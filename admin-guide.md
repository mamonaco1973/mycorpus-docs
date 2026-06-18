# mycorpus Administrator Guide

This guide covers everything an administrator needs to configure and operate a
mycorpus deployment: managing corpora, configuring data sources, controlling
user access, connecting identity providers, and understanding plan limits.

---

## Table of Contents

1. [Corpora Management](#corpora-management)
2. [Source Types](#source-types)
3. [User Management](#user-management)
4. [Token Usage and Tracking](#token-usage-and-tracking)
5. [Identity Providers](#identity-providers)
6. [MCP Connector (Claude Connector)](#mcp-connector-claude-connector)
7. [Plans and Limits](#plans-and-limits)
8. [Branding and Settings](#branding-and-settings)
9. [Data Security](#data-security)
10. [FAQ](#faq)

---

## Corpora Management

A corpus is a named knowledge base. Users select a corpus before starting a
conversation; the system retrieves relevant passages from that corpus to
ground the AI's answers.

### Creating a corpus

Open the Corpora panel (admin-only button in the sidebar). Click **New
Corpus**, enter a name, and save. Each corpus gets a unique ID and starts in
an unconfigured state. You must add at least one source and run a build before
users can query it.

The number of corpora you can create is gated by your plan tier:

| Tier     | Max corpora |
|----------|-------------|
| Free     | 5           |
| Basic    | 10          |
| Pro      | 25          |
| Business | 100         |

### Configuring sources

Each corpus has a Sources section where you add one or more data sources. The
available source types are GitHub, GitHub Corpus, GitLab, GitLab Corpus,
YouTube, URL, Q&A, and uploaded Documents. See the [Source Types](#source-types)
section for full configuration details for each type.

Credentials (personal access tokens, API keys) are stored server-side and
never returned to the browser after being saved. The indicator field returned
depends on the source type: GitHub sources return `pat_configured`; GitHub
Corpus, GitLab, and GitLab Corpus sources return `token_configured`; YouTube
sources return `api_key_configured`. To rotate a credential, enter the new
value and save. To keep the existing credential unchanged, submit `null` for
that field — submitting an empty string clears the stored credential.

### Building a corpus

After configuring sources, click **Build** in the corpus panel. A build runs
as an ECS Fargate task and may take several minutes depending on corpus size.
The corpus status changes to `building` while the task runs, then to `ready`
on success or `error` on failure.

The previous corpus remains fully queryable until the new build completes.
Artifacts are staged in S3 under a timestamped prefix, and the manifest
pointer is swapped atomically at the end of the build.

### Build notifications

When SMTP is configured (via the `smtp_server`, `smtp_port`, `smtp_user`, and
`smtp_password` Terraform variables), the system emails all superadmins a
build summary after every build, whether it succeeds or fails. The email
includes a per-source document count, any source errors, the final chunk
count, and an attached build log from CloudWatch.

If SMTP is not configured, build notifications are silently skipped.

### Chunk limits by tier

The corpus builder enforces a maximum number of text chunks. Content beyond
the limit is dropped and a warning is logged. The chunk cap is per corpus, per
build:

| Tier     | Max chunks |
|----------|------------|
| Free     | 20,000     |
| Basic    | 30,000     |
| Pro      | 50,000     |
| Business | 100,000    |

If you see "chunk limit reached" in a build notification, reduce the number of
sources or switch to a higher plan tier.

### CORPUS.md — corpus description

Each corpus can have a plain-prose description that helps the AI understand
when to use that knowledge base. There are two ways this description is set:

- **Automatic (from source):** If any source document is named `CORPUS.md`
  (case-insensitive), its text is used as the corpus description.
- **AI-generated:** If no `CORPUS.md` is found in the loaded content, the
  system generates a description automatically by sampling corpus chunks and
  asking the AI model to describe the knowledge base's topics and use cases.

Once a corpus description is set, subsequent builds will not overwrite it.
You can edit the description manually in the corpus settings at any time.

### Starter questions

After each successful build the system generates 16 starter questions
automatically. These appear in the chat interface to help users begin
conversations. Each question has a short clickable label (3–6 words) and a
full detailed question text. Starter questions are regenerated on every build.

---

## Source Types

### GitHub — readme/file ingestor

Fetches a fixed list of files (e.g. `README.md`) from every public repository
belonging to a GitHub user or organisation.

| Field         | Required | Description |
|---------------|----------|-------------|
| user          | Yes      | GitHub username or org name |
| pat           | Yes      | Personal access token with `repo` read scope |
| files         | No       | List of file paths to fetch per repo (default: `["README.md"]`) |
| repo_filter   | No       | List of repository names to include; all repos are fetched if omitted |

The ingestor paginates through all public repositories (up to the GitHub API
rate limit of 5,000 requests/hour) and fetches only the files listed in
`files` from each repo. Only public repos are indexed; the API request always
uses `type=public` regardless of PAT scope.

### GitHub Corpus — web crawler anchored to a GitHub repo

Crawls the rendered web pages associated with a GitHub repository rather than
the raw file tree. Useful for repositories that publish documentation sites.

| Field   | Required | Description |
|---------|----------|-------------|
| repo    | Yes      | GitHub repository path (e.g. `owner/repo`) |
| branch  | No       | Branch to use (default: `main`) |
| path    | No       | Path within the repository to scope the crawl |
| token   | Yes      | Personal access token |

### GitLab — readme/file ingestor

Fetches a fixed list of files from every project in a GitLab user namespace
or group.

| Field         | Required | Description |
|---------------|----------|-------------|
| user          | Yes      | GitLab username or group path |
| token         | Yes      | GitLab personal access token |
| files         | No       | File paths to fetch per project (default: `["README.md"]`) |
| repo_filter   | No       | List of project path names to include; all projects if omitted |

When `user` is a group path, the ingestor falls back to the groups API
automatically. Non-404 errors fetching individual files are logged as warnings
and the remaining files continue to be fetched.

### GitLab Corpus — web crawler anchored to a GitLab project

Crawls rendered documentation pages associated with a GitLab project.

| Field   | Required | Description |
|---------|----------|-------------|
| repo    | Yes      | GitLab project path (e.g. `group/project`) |
| branch  | No       | Branch to use (default: `main`) |
| path    | No       | Path within the project to scope the crawl |
| token   | Yes      | Personal access token |

### YouTube

Fetches the title and description of every video in a YouTube channel.

| Field      | Required | Description |
|------------|----------|-------------|
| channel_id | Yes      | YouTube channel ID (e.g. `UCxxxxxx`) |
| api_key    | Yes      | Google API key with the YouTube Data API v3 enabled |

The ingestor uses the `search.list` API to enumerate all video IDs in the
channel, then calls `videos.list` in batches of 50 to retrieve full
descriptions (search snippets are truncated to ~300 characters by the API).
The corpus document for each video is `{title}\n\n{description}` when a
description is present, or just the title when the description is empty.

Note: this ingestor indexes video metadata (title + description) only. Video
transcripts are not fetched.

### URL — web page fetcher and crawler

Fetches a web page and optionally crawls links found on that page.

| Field        | Required | Description |
|--------------|----------|-------------|
| url          | Yes      | Absolute URL to fetch |
| title        | No       | Override the page `<title>` with a custom label |
| crawl_links  | No       | If `true`, also crawl same-domain links from the root page (default: `false`) |

When `crawl_links` is `true`, the ingestor follows every same-domain link
found on the root page, up to a maximum of 100 pages total. External domains,
images, videos, and dynamic pages (`.php`, `.jsp`) are skipped. Navigation,
header, and footer elements are stripped before text is extracted.

A global deduplication set is shared across all URL-type sources in a build.
If two sources link to the same page, it is only fetched once. The root URL
of each source is always fetched fresh regardless of deduplication state.

Each page is capped at 200,000 extracted characters.

### Q&A — manual question-and-answer pairs

Stores a question and answer directly in the source configuration, with no
external fetching required.

| Field    | Required | Description |
|----------|----------|-------------|
| question | Yes      | The question text |
| answer   | Yes      | The answer text |

Each Q&A pair becomes a single corpus document formatted as:
```
Q: {question}

A: {answer}
```

Use this source type for curated FAQ content, policy statements, or any
knowledge that needs to be in the corpus verbatim.

### Uploaded Documents

Files uploaded directly through the corpus UI are stored in S3 and
automatically included in every build without any source configuration entry.
Supported formats:

- **PDF** — text is extracted page by page using pypdf.
- **DOCX** — paragraph text is extracted using python-docx.
- **Plain text and all other formats** — decoded as UTF-8.

Uploaded documents appear in the source results summary as `(uploaded files)`.

---

## User Management

### Roles

Every user in the system has one of the following roles:

**superadmin** — Users listed in the `ADMIN_EMAILS` environment variable (set
at deploy time as a comma-separated list). Superadmins always have full admin
access, cannot be denied, and cannot be modified or deleted through the admin
UI. Their role shows as `superadmin` in the user list. Only superadmins can
access corpus management endpoints.

**admin** — Users granted admin access through the Users panel. Admins can
access the user management and identity provider management interfaces. They
cannot access corpus management, which is restricted to superadmins. Unlike
superadmins, admin users can have their role changed or their account deleted.

**allowed** — Normal users who can query corpora but have no admin access.
This is the default role for new users when the system is in open mode.

**denied** — Users who are blocked from using the system. A denied user who
tries to sign in receives an "access denied" response. You can deny a user who
has already registered, or pre-deny an email address before they register.

### Access modes

The access mode controls what happens when a new user signs up:

**Open mode** (`default_user_role = allowed`) — Any user who creates an
account is automatically admitted and can start querying immediately. This is
the default.

**Closed mode** (`default_user_role = denied`) — New users who sign up are
blocked by default. An admin must set their role to `allowed` or `admin`
before they can use the system. You can pre-authorize an email address before
the user signs up — they will be admitted automatically on first login.

Change the access mode from the Users panel. The setting takes effect
immediately for any new registrations; existing users are not affected.

### Registration toggle

Separately from the access mode, you can disable new user registrations
entirely. When registration is disabled, new sign-up attempts are rejected
with a `registration_closed` error. Existing users and admins can continue to
sign in normally.

The registration toggle is on the Identity tab under the Email / Password
provider card.

### User cap

Your plan tier sets a maximum number of registered user accounts. When the cap
is reached, new registration attempts are rejected with a `user_limit_reached`
error. Superadmins bypass the user cap.

| Tier     | User cap |
|----------|----------|
| Free     | 5        |
| Basic    | 10       |
| Pro      | 25       |
| Business | 9,999    |

### Pre-authorizing users

To pre-authorize a user who has not yet signed up, enter their email address
in the Users panel and assign them a role of `allowed` or `admin`. The
system writes a DynamoDB record for that email. When the user signs up and
logs in for the first time, the pre-existing role is honoured and their usage
counters are initialized.

### Deleting users

Deleting a user from the Users panel removes them from both Cognito and the
DynamoDB user record. Superadmins cannot be deleted. If the deleted user has
not yet signed up (pre-authorized only), only the DynamoDB record is removed.

---

## Token Usage and Tracking

### Token budget

Each plan tier includes a monthly Bedrock token budget. Tokens are consumed
by AI model calls (both for answering questions and for corpus builds that
generate starter questions and corpus descriptions).

| Tier     | Monthly token budget |
|----------|---------------------|
| Free     | 1,000,000           |
| Basic    | 5,000,000           |
| Pro      | 15,000,000          |
| Business | 30,000,000          |

### Tracking modes

Admins can choose between two token tracking modes from the Users panel:

**Per-user** — The monthly budget is divided equally among all user slots
(`token_budget ÷ user_cap`). Each user has their own counter. When a user
reaches their individual limit, they are blocked from further queries until
the next calendar month. Other users are unaffected.

**Shared** — All users draw from a single pool equal to the full
`token_budget`. The first users to query exhaust the pool; when the shared
total is reached, all users are blocked until the next calendar month.

The tracking mode can be changed at any time. Changes take effect on the next
query.

### Monthly reset

Token counters reset at the start of each calendar month (UTC). The system
uses a `period_key` field (format `YYYY-MM`) to detect when a counter belongs
to a previous period. Counters are not automatically zeroed at month rollover;
they are treated as zero when the period key does not match the current month.

---

## Identity Providers

Cognito email/password is always available. Additional identity providers are
additive — removing one never disables email/password login.

Provider management is on the **Identity** tab (admin only). The tab shows the
current status of each provider and the SP metadata URLs you need when
registering Cognito in an external identity provider.

### Email / Password (always enabled)

Standard Cognito email/password sign-in. Cannot be removed. Ensures admin
recovery access even if an external provider is misconfigured.

**Password policy (set at deploy time, not configurable at runtime):**
- Minimum 12 characters
- Must contain lowercase letters
- Must contain uppercase letters
- Must contain numbers
- Symbols are not required

Account recovery is via verified email.

### Google Sign-In (Pro and Business tiers)

Allows users to sign in with a Google account via Cognito's Google OAuth2
integration.

**Before enabling Google Sign-In**, create an OAuth 2.0 client ID in Google
Cloud Console and add both values shown in the Identity tab:

- **Authorized JavaScript origin** — the root URL of your mycorpus app
- **Authorized redirect URI** — the Cognito OAuth2 callback URL

**To configure:**

1. On the Identity tab, copy the two URLs from the Google Sign-In card into
   your Google Cloud Console OAuth credentials.
2. Enter the **Client ID** and **Client Secret** from Google Cloud Console.
3. Click **Enable Google Sign-In**.

Google Sign-In can be updated at any time by entering new credentials and
saving again. To remove it, click **Remove** on the Google Sign-In card.
Users who signed in exclusively via Google will need to use email/password
instead.

### SAML 2.0 (Business tier only)

Connects any SAML 2.0 identity provider — Okta, Azure AD, Ping, OneLogin, or
any other SAML-compliant IdP. Multiple SAML providers can be configured
simultaneously.

**Register Cognito as a Service Provider in your IdP** using these values from
the Identity tab:

- **ACS URL** (assertion consumer service URL) — where the IdP posts the
  SAML assertion
- **SP Entity ID** — the Cognito service provider identifier
- **SP Metadata URL** — a URL to the Cognito SP metadata document (some IdPs
  can import this directly)

**To add a SAML provider:**

1. Register Cognito in your IdP using the SP metadata values above.
2. On the Identity tab, enter a **Display Name** (e.g. `Okta` or `AzureAD`).
3. Enter the **IdP Metadata URL** published by your IdP.
4. Optionally enter the **Email attribute** name if your IdP uses a
   non-standard attribute. Leave blank to use the default WS-Federation claim
   (`http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress`),
   which works for Okta and Azure AD.
5. Click **Add SAML Provider**.

To remove a SAML provider, click **Remove** next to its name. Users who sign
in exclusively via that provider will need to use email/password instead.

### OIDC (Business tier only)

Connects any OpenID Connect provider — Okta, Auth0, Azure AD in OIDC mode,
or any other OIDC-compliant IdP. Multiple OIDC providers can be configured.

**Register Cognito in your OIDC provider** using these values from the
Identity tab:

- **Sign-in redirect URI** — the Cognito OAuth2 callback URL
- **Sign-out redirect URI** — the Cognito logout URL
- **Trusted Origins / Base URI** — the root URL of your mycorpus app (required
  by Okta's Trusted Origins setting)

**To add an OIDC provider:**

1. Register a new application in your OIDC provider and paste in the redirect
   and sign-out URIs above.
2. On the Identity tab, enter a **Display Name** (e.g. `Okta` or `Auth0`).
3. Enter the **Issuer URL** (e.g. `https://your-org.okta.com`).
4. Enter the **Client ID** and **Client Secret** from your OIDC provider.
5. Click **Add OIDC Provider**.

The connector requests `email profile openid` scopes. The email claim is
mapped to the Cognito user's email attribute.

### Provider tier requirements

| Provider        | Required tier |
|-----------------|---------------|
| Email / Password | All tiers     |
| Google Sign-In  | Pro or higher |
| SAML 2.0        | Business      |
| OIDC            | Business      |

---

## MCP Connector (Claude Connector)

The MCP Connector exposes your corpora to Claude via the Model Context Protocol.
Once connected, Claude retrieves relevant passages from your knowledge bases
during conversations.

### Connecting claude.ai

1. In claude.ai, go to **Settings → Connectors → Add custom connector**.
2. Paste the **MCP Server URL** from the Claude Connector panel in the mycorpus
   settings sidebar.
3. Click **Connect**. A login window opens.
4. Sign in with your mycorpus account.
5. Once authenticated, your knowledge bases are available in every claude.ai
   conversation.

The MCP Server URL is shown on the Claude Connector settings panel. Each
mycorpus deployment has a single shared MCP Server URL.

### API keys

Users can generate personal API keys for MCP clients that do not support the
OAuth flow. API keys are managed from the user's profile, not the admin panel.

Key properties:
- Keys begin with the prefix `mc_` and are 32 URL-safe random bytes.
- The full key value is shown **once** at creation time and never stored.
  Users must copy it immediately. Only a SHA-256 hash is persisted.
- Each key has an optional **Label** (up to 64 characters) to identify its
  purpose.
- The key listing shows the first 12 characters of each key (prefix) plus the
  label and creation date, but never the full value.
- Keys can be revoked at any time. Revoking a key immediately blocks any
  client using it.

Admins cannot view or revoke other users' API keys. Users manage their own
keys.

---

## Plans and Limits

Four plan tiers are available. The active tier controls corpus limits, chunk
limits, user caps, and token budgets simultaneously.

| Tier     | Corpora | Chunks/corpus | Users | Monthly tokens | IDP support      |
|----------|---------|---------------|-------|----------------|------------------|
| Free     | 5       | 20,000        | 5     | 1,000,000      | Email/Password   |
| Basic    | 10      | 30,000        | 10    | 5,000,000      | Email/Password   |
| Pro      | 25      | 50,000        | 25    | 15,000,000     | + Google Sign-In |
| Business | 100     | 100,000       | 9,999 | 30,000,000     | + SAML, OIDC     |

The active tier is set via the `runtime_tier` Terraform variable at deploy
time. It can also be changed at runtime via the Plan API (admin only), which
updates the CONFIG record in DynamoDB, resets token counters to zero, and
resets the token tracking mode to shared.

### Downgrade behavior

Switching to a lower-paid tier (e.g. Business → Pro) via the Plan API purges
all non-superadmin users from both Cognito and DynamoDB. Affected users must
re-register under the new plan's lower user cap. Superadmin accounts are never
affected by a purge.

Downgrading to the free tier is not permitted through the Plan API. The free
tier can only be reached by cancelling the subscription, which is handled
outside the admin UI.

### Free trial

New deployments on the free tier start a 90-day trial period. The trial start
date is recorded on first use and is not reset if the plan is later upgraded
and downgraded back to free. When 15 or fewer days remain, the UI shows a
warning banner. When the trial expires, the `trial_expired` flag is set and
further usage is blocked until the deployment is upgraded to a paid tier.

---

## Branding and Settings

### Assistant name

The display name shown in the chat interface header and authentication modal.
Set via the `assistant_name` Terraform variable at deploy time (default:
`My Assistant`). Can also be updated at runtime via the corpus settings API
without redeploying.

### System prompt

The system message injected into every AI model call. It instructs the model
how to behave when answering questions from the corpus.

Default system prompt:
> You are a helpful AI assistant grounded in the provided context. Answer
> questions accurately based on the context excerpts. If the context does not
> contain enough information to answer, say so clearly rather than speculating.

The system prompt can be updated at runtime via the corpus settings API
without a redeployment. Changes take effect on the next query.

### Sidebar navigation links

Admins can configure custom navigation links that appear in the sidebar for all
users. Each link has a label and a URL and opens in a new browser tab.

### Support email

The contact email shown on the Plan tab for users who want to inquire about
upgrading. Set via the `support_email` Terraform variable.

---

## Data Security

### Sensitive credential storage

Personal access tokens (GitHub, GitLab) and API keys (YouTube) are stored
in S3 in the corpus `sources.json` file. They are never returned to the browser.
The indicator field returned depends on the source type: GitHub sources return
`pat_configured: true`; GitHub Corpus, GitLab, and GitLab Corpus sources return
`token_configured: true`; YouTube sources return `api_key_configured: true`.
To update a credential, submit a new value. Submitting `null` keeps the existing
credential unchanged; submitting an empty string clears it.

MCP API keys (the `mc_` tokens users generate for Claude clients) are never
stored. Only a SHA-256 hash is persisted in DynamoDB. The raw key is returned
to the user exactly once, at creation time.

### Superadmin protection

Superadmins are identified by the `ADMIN_EMAILS` environment variable, which
is set at deploy time and requires a Terraform change to modify. Superadmin
accounts cannot be denied, deleted, or have their role changed via the admin
UI, regardless of what DynamoDB contains.

### Token tracking and budget enforcement

Token budgets are enforced per-period (calendar month). The system tracks both
a per-user counter and a shared global counter for every query. Which counter
is displayed and enforced depends on the active tracking mode (`per_user` or
`shared`). Token limits are soft: a DynamoDB read failure causes the system to
fail open (allow the query) rather than lock out all users.

### Password requirements

Cognito enforces the following password policy for email/password accounts
(set at deploy time via Terraform, not configurable at runtime):
minimum 12 characters; must include at least one lowercase letter, one
uppercase letter, and one number. Symbols are not required. Passwords can be
reset via verified email.

---

## FAQ

**Who is a superadmin and how do I add one?**

Superadmins are identified by the `ADMIN_EMAILS` Terraform variable, a
comma-separated list of email addresses set at deploy time. Any user whose
email appears in that list always has full admin access, cannot be denied, and
cannot be deleted or have their role changed through the admin UI. To add or
remove a superadmin, update the `ADMIN_EMAILS` variable and re-apply Terraform.

**How do I block all new sign-ups without affecting existing users?**

Disable registrations from the Identity tab, under the Email / Password
provider card, by clicking the **Allow new user registrations** toggle. This
rejects new account creation while allowing all existing users to continue
signing in normally. It does not affect the access mode (open vs. closed).

**What is the difference between open mode and closed mode?**

In open mode (`default_user_role = allowed`), any user who successfully creates
a Cognito account is immediately admitted to the system. In closed mode
(`default_user_role = denied`), newly registered users are blocked until an
admin grants them the `allowed` or `admin` role. You can pre-authorize a user
in closed mode by entering their email address in the Users panel and assigning
a role before they sign up.

**How do I pre-authorize a user who hasn't signed up yet?**

In the Users panel, enter the user's email address and set their role to
`allowed` or `admin`. The system creates a DynamoDB record for that email.
When the user signs up and signs in for the first time, the pre-assigned role
is applied automatically.

**Can I have multiple SAML or OIDC providers?**

Yes. SAML and OIDC each support multiple configured providers simultaneously.
Each provider has a unique display name. Google Sign-In is limited to one
provider (the single configured Google OAuth app).

**What SP metadata do I need when registering Cognito with my SAML IdP?**

The Identity tab shows three values under the SAML 2.0 card:
- **ACS URL** — paste this as the SAML assertion consumer service URL in your
  IdP.
- **SP Entity ID** — paste this as the service provider entity ID or audience
  restriction.
- **SP Metadata URL** — some IdPs (Okta, Azure AD) can import this URL
  directly to configure all SAML settings automatically.

**What OIDC redirect URIs do I need when registering with an OIDC provider?**

The Identity tab shows three values under the OIDC card:
- **Sign-in redirect URI** — paste this as the allowed redirect URI (callback
  URL) in your OIDC app.
- **Sign-out redirect URI** — paste this as the allowed post-logout redirect
  URI.
- **Trusted Origins (Base URI)** — required by Okta's Trusted Origins setting;
  paste this as an allowed base URI.

**What happens when a corpus build hits the chunk limit?**

The build succeeds, but content is truncated to the first N chunks allowed by
your plan tier. A warning is included in the build notification email. To
include all content, either reduce the number of sources, narrow the
`repo_filter` or file list, or upgrade to a higher plan tier.

**What happens if a source fails during a build?**

A failed source is skipped and logged as an error. The build continues with
the remaining sources and completes successfully (assuming at least some
content was ingested). The failed source appears in the build notification
email with a `[FAILED]` tag and the error message. Fix the source
configuration (e.g. a revoked PAT or incorrect metadata URL) and rebuild.

**How are token budgets enforced for shared vs. per-user tracking?**

In **per-user** mode, the monthly budget is divided by the user cap
(`token_budget ÷ user_cap`). Each user has an independent counter; one user
hitting their limit does not affect others. In **shared** mode, all users draw
from a single pool equal to the full `token_budget`. The tracking mode can be
changed at any time from the Users panel.

**What is the MCP Server URL used for?**

The MCP Server URL is the endpoint Claude uses to retrieve passages from your
knowledge bases via the Model Context Protocol. In claude.ai, paste this URL
when adding a custom connector. The connection is authenticated via OAuth —
users sign in with their mycorpus account the first time they connect.

**How do I revoke a user's MCP API key?**

Users manage their own API keys from their profile. An admin cannot view or
revoke another user's keys. If a key is compromised, the affected user should
revoke it from their profile. If the user account itself needs to be
deactivated, set the user's role to `denied` or delete their account — both
actions block all future authenticated requests regardless of key state.

**Are credentials like GitHub PATs visible to admins in the UI?**

No. Personal access tokens and API keys submitted via the source configuration
UI are stored in S3 and never returned to the browser. The API returns a
boolean indicator (`pat_configured` for GitHub, `token_configured` for GitHub
Corpus/GitLab/GitLab Corpus, `api_key_configured` for YouTube) to show whether
a credential is set. The raw value cannot be retrieved after it is saved.

**What builds does the system send email notifications for?**

The system emails all superadmins after every corpus build — both successful
builds and failed ones. The email includes a per-source document count, error
details for any failed sources, the total chunk count, and an attached
CloudWatch log. Notifications require SMTP to be configured via the
`smtp_server`, `smtp_port`, `smtp_user`, and `smtp_password` Terraform
variables. If SMTP is not configured, notifications are silently skipped.

**What happens to users when I downgrade to a lower plan tier?**

Switching to a lower-paid tier via the Plan API immediately purges all
non-superadmin users from Cognito and DynamoDB. Superadmin accounts are
preserved. Purged users must re-register once the new plan is active. Note
that downgrading to the free tier is not permitted through the Plan API;
that requires cancelling the subscription outside the admin UI.

**What is the free trial and when does it expire?**

New deployments on the free tier receive a 90-day trial period. The trial
clock starts on first use and cannot be reset. When 15 or fewer days remain,
the UI displays a warning banner. When the trial expires, further usage is
blocked until the deployment is upgraded to a paid tier. The trial only applies
to the free tier; paid tiers are not subject to a trial period.

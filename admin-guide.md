# MyCorpus.ai Administrator Guide

This guide covers everything an administrator needs to configure and operate a
MyCorpus.ai deployment: managing corpora, configuring data sources, controlling
user access, connecting identity providers, and understanding plan limits.

---

## Table of Contents

1. [Corpora Management](#corpora-management)
2. [Source Types](#source-types)
3. [.corpora File Reference](#corpora-file-reference)
4. [User Management](#user-management)
5. [Token Usage and Tracking](#token-usage-and-tracking)
6. [Identity Providers](#identity-providers)
7. [MCP Connector (Claude Connector)](#mcp-connector-claude-connector)
8. [Plans and Limits](#plans-and-limits)
9. [Branding and Settings](#branding-and-settings)
10. [Data Security](#data-security)
11. [FAQ](#faq)

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
| Business | 50          |

### Configuring sources

Each corpus has a Sources section where you add one or more data sources. The
available source types are GitHub, GitHub Corpus Repo, GitLab, GitLab Corpus
Repo, YouTube, Web Page (URL), RSS / Atom Feed, Q&A, Google Drive, ZIP
Archive, Corpora File, and uploaded Documents. See the [Source Types](#source-types)
section for full configuration details for each type.

Credentials (personal access tokens, API keys, OAuth refresh tokens) are
stored server-side and never returned to the browser after being saved. The
indicator field returned depends on the source type: GitHub sources return
`pat_configured`; GitHub Corpus Repo, GitLab, and GitLab Corpus Repo sources
return `token_configured`; YouTube sources return `api_key_configured`; Google
Drive sources return `refresh_token_configured`. To rotate a credential, enter
the new value and save. To keep the existing credential unchanged, submit
`null` for that field — submitting an empty string clears the stored
credential.

### Building a corpus

After configuring sources, click **Build** in the corpus panel. A build runs
as an ECS Fargate task and may take several minutes depending on corpus size.
The corpus status changes to `building` while the task runs, then to `ready`
on success or `error` on failure.

The previous corpus remains fully queryable until the new build completes.
Artifacts are staged in S3 under a timestamped prefix, and the manifest
pointer is swapped atomically at the end of the build.

### Cancelling a build

While a build is running, a **Cancel** button appears in the corpus panel.
Clicking it stops the ECS Fargate task and marks the corpus status as
`cancelled`. The previous build's artifacts remain intact and the corpus
continues to be queryable. A cancelled build counts as a failed build in the
notification email if SMTP is configured.

### Scheduled rebuilds

Each corpus can be configured to rebuild automatically on a schedule without
manual intervention. The scheduler runs daily at midnight UTC.

To enable a schedule, open the corpus panel and click the **Schedule** button.
The available options depend on your plan tier:

**Free and Basic tiers** — automatic weekly rebuild every Sunday. The day
cannot be changed.

**Pro and Business tiers** — choose between daily rebuilds or weekly rebuilds
on a configurable day of the week (Sunday through Saturday).

When the scheduler fires, it launches an ECS build task for each corpus that
has scheduling enabled and is due today. The build runs exactly like a manual
build and sends the same email notification on completion (if SMTP is
configured).

To disable scheduled rebuilds for a corpus, open the Schedule panel and toggle
off the schedule.

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

Every build regenerates the corpus description. If a `CORPUS.md` file is
found in the source, its content is used; otherwise the AI generates a new
description. Manual edits made via the corpus settings panel are not
preserved across builds.

### Starter questions

After each successful build the system generates 32 starter questions
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

### GitHub Corpus Repo — full repository ingestor

Traverses the complete file tree of a GitHub repository and ingests every
supported file it contains. Useful for indexing a documentation repo,
a knowledge base, or any repository with structured content.

| Field   | Required | Description |
|---------|----------|-------------|
| repo    | Yes      | GitHub repository path (e.g. `owner/repo`) |
| branch  | No       | Branch to use (default: `main`) |
| path    | No       | Subdirectory prefix to limit ingestion (e.g. `docs/`), heuristic mode only |
| pat     | No       | Personal access token — raises the GitHub API rate limit from 60 to 5,000 requests/hour and allows access to private repositories |

**Supported file types:** `.txt`, `.md`, `.rst`, `.markdown`, `.text`, `.pdf`, `.docx`.
Files larger than 10 MB are skipped.

**Declarative mode:** If one or more files ending in `.corpora` exist at the
repository root, they take full control of what gets ingested. The heuristic
file crawl is skipped entirely. All `.corpora` files at the root are processed
in the order returned by the GitHub API. See the [.corpora File Reference](#corpora-file-reference)
section for the full format and directive list.

If no `.corpora` files are present, the ingestor automatically downloads every
supported file in the repository (filtered by the optional `path` prefix).

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

### GitLab Corpus Repo — full repository ingestor

Traverses the complete file tree of a GitLab repository and ingests every
supported file it contains. Mirrors the GitHub Corpus Repo ingestor but uses
the GitLab Repository Files API.

| Field   | Required | Description |
|---------|----------|-------------|
| repo    | Yes      | GitLab project path (e.g. `namespace/project`) |
| branch  | No       | Branch to use (default: `main`) |
| path    | No       | Subdirectory prefix to limit ingestion (e.g. `docs/`), heuristic mode only |
| token   | No       | GitLab personal access token |

**Supported file types:** `.txt`, `.md`, `.rst`, `.markdown`, `.text`, `.pdf`, `.docx`.
Files larger than 10 MB are skipped.

**Declarative mode:** Same `.corpora` file mechanism as GitHub Corpus Repo. If
one or more files ending in `.corpora` exist at the repository root, they
exclusively control ingestion. Otherwise all supported files are downloaded.

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

### Web Page (URL) — web page fetcher and crawler

Fetches one or more web pages and optionally crawls links found on each page.
When adding a new URL source, you can paste multiple URLs at once (one per
line). Each URL becomes a separate source entry.

| Field        | Required | Description |
|--------------|----------|-------------|
| url          | Yes      | Absolute URL to fetch |
| title        | No       | Override the page `<title>` with a custom label |
| crawl_links  | No       | If `true`, also crawl same-domain links from the root page (default: `false`) |

When `crawl_links` is `true`, the ingestor follows every same-domain link
found on the root page, one level deep, up to a maximum of 100 pages total.
External domains, images, videos, audio files, archives, and dynamic pages
(`.php`, `.jsp`) are skipped. Navigation, header, and footer elements are
stripped before text is extracted.

HTML pages are capped at 500,000 extracted characters. If the URL points to a
PDF or DOCX file (detected by Content-Type or file extension), the ingestor
extracts text directly from the file with no character cap.

A global deduplication set is shared across all URL-type sources in a build.
If two sources link to the same page, it is only fetched once. The root URL
of each source is always fetched fresh regardless of deduplication state.

### RSS / Atom Feed

Fetches articles from an RSS or Atom feed. Every entry link in the feed is
fetched and its page text is extracted, exactly as if each article URL were
listed as a Web Page source.

| Field           | Required | Description |
|-----------------|----------|-------------|
| url             | Yes      | RSS or Atom feed URL |
| max_items       | No       | Maximum feed entries to process (default: 50) |
| crawl_links     | No       | If `true`, also follow links found on each article page (default: `false`) |
| allowed_domains | No       | List of domain patterns to allow for cross-domain link crawling (e.g. `*.example.com`) |
| max_crawl       | No       | Maximum pages to crawl per article when `crawl_links` is `true` (default: 100) |

Feed entries that have already been seen by another source in the same build
are skipped (shared deduplication with URL sources). Malformed or unreachable
feeds are logged as errors and the source is skipped.

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

### Google Drive — folder ingestor

Ingests files from a Google Drive folder. Requires Google Drive OAuth
credentials to be configured at deploy time via the `gdrive_client_id` and
`gdrive_client_secret` Terraform variables. If those variables are not set,
the Google Drive source type is unavailable.

**Connection flow:**

1. Click **Connect Google Drive** in the source configuration panel.
2. A Google login popup opens — sign in and grant Drive read access.
3. The Google Picker opens — select the folder to ingest.
4. The folder ID and a refresh token are stored server-side (the refresh token
   is never returned to the browser after saving).

| Field         | Required | Description |
|---------------|----------|-------------|
| folder_id     | Yes      | Google Drive folder ID (set via the Google Picker, not typed manually) |
| folder_name   | No       | Display name of the selected folder |
| refresh_token | Yes      | OAuth refresh token (set via the Connect flow, stored server-side) |

**Supported file types:**
- Google Docs — exported as plain text
- Google Sheets — exported as CSV (rows tab-separated)
- Google Slides — exported as plain text
- PDF — extracted via pypdf
- Word (.docx) — extracted via python-docx
- Plain text, Markdown, RST, CSV — decoded as UTF-8

Google Workspace file exports are capped at 10 MB. Binary files (PDF, DOCX,
plain text) are capped at 50 MB. The ingestor processes up to 500 files per
folder. Subfolders are traversed recursively up to 5 levels deep.

**Declarative mode:** If one or more files ending in `.corpora` exist as
direct children of the selected folder, they take full control of what gets
ingested. All `.corpora` files at the folder root are processed. The same
`[web]`, `[files]`, `[rss]`, and `[excludes]` directive format applies (see
the [.corpora File Reference](#corpora-file-reference) section). If no `.corpora` files
are present, all supported files in the folder tree are downloaded
automatically.

The credential indicator returned is `refresh_token_configured`.

### ZIP Archive — archive ingestor

Uploads a ZIP file to S3 and extracts all supported files from it at build
time. No external credentials are needed — the archive lives in the corpus
S3 bucket.

To add a ZIP source, click **Add Source**, choose **ZIP Archive**, and select
a `.zip` file. The file is uploaded immediately and the source entry is saved.

**Supported file types inside the archive:**
- PDF (.pdf) — extracted via pypdf
- Word (.docx) — extracted via python-docx
- Plain text (.txt, .md, .rst, .markdown)
- Code and config files (.py, .js, .ts, .java, .go, .yaml, .json, .sql, and
  many other common code extensions)

Nested ZIP files inside the archive are skipped. Password-protected entries
are skipped. Individual files larger than 20 MB are skipped. The ingestor
processes up to 500 files per archive. Files from ZIP archives are stored
individually in S3 and can be downloaded directly from source links in the
chat interface.

### Corpora File — inline `.corpora` definition

Stores a `.corpora` declarative build file inline in the corpus configuration.
This lets you define URL crawling and RSS feed ingestion directly in the admin
panel, without committing a `.corpora` file to a repository or folder.

| Field   | Required | Description |
|---------|----------|-------------|
| content | Yes      | The full text content of the `.corpora` file |

Paste the content directly into the editor, load a sample from the built-in
sample picker, or load a `.corpora` file from disk. A live validation indicator
shows how many web URLs and RSS feeds are configured before you save.

The content field accepts the same INI-style format as a `.corpora` file in a
GitHub or GitLab repository (see the [.corpora File Reference](#corpora-file-reference)
section). Supported directives in this mode:

- `[web]` — crawl one or more URLs
- `[rss]` — fetch articles from an RSS or Atom feed
- `[excludes]` — URL patterns to exclude from all crawls in this source

The `[files]` directive is not supported in this mode because there is no
repository or folder tree to expand globs against. If `[files]` directives
are present in the content, they are ignored and a warning is written to the
build log.

### Uploaded Documents

Files uploaded directly through the corpus UI are stored in S3 and
automatically included in every build without any source configuration entry.
Supported formats:

- **PDF** — text is extracted page by page using pypdf.
- **DOCX** — paragraph text is extracted using python-docx.
- **Plain text and all other formats** — decoded as UTF-8.

Uploaded documents appear in the source results summary as `(uploaded files)`.

---

## .corpora File Reference

A `.corpora` file is a declarative build definition that takes full control of
what a GitHub Corpus Repo, GitLab Corpus Repo, or Google Drive source ingests.
The same format is also used by the Corpora File (inline) source type. When a
`.corpora` file is present, the automatic heuristic file crawl is skipped
entirely.

The file uses an INI-style format. Lines starting with `#` are comments. Blank
lines are ignored. Each section header is a directive type in square brackets.
Multiple directives of the same type are allowed in a single file, and multiple
`*.corpora` files at the root of a repo or folder are all processed.

### Sections

**`[web]`** — crawl one or more web URLs

```ini
[web]
url = https://docs.example.com
crawl_links = true
max_crawl = 50
domain = *.example.com
max_workers = 10
```

| Key             | Description |
|-----------------|-------------|
| `url`           | Absolute URL to fetch (repeat for multiple URLs) |
| `crawl_links`   | If `true`, follow same-domain links one level deep (default: `false`) |
| `max_crawl`     | Maximum pages to crawl when `crawl_links` is `true` (default: 100) |
| `domain`        | Additional domain patterns (fnmatch) to allow during cross-domain crawling (repeat for multiple) |
| `allow_pattern` | fnmatch URL whitelist — when set, only URLs matching at least one pattern are followed; overrides the domain filter and enables cross-domain PDF harvesting (repeat for multiple patterns) |
| `max_workers`   | Number of parallel fetch threads (default: 5, max: 20) |

**`[files]`** — ingest specific files from the repo or folder by glob pattern

```ini
[files]
source = docs/*.md
source = README.md
source = guides/**/*.rst
```

| Key      | Description |
|----------|-------------|
| `source` | Glob pattern matched against all paths in the repo or folder tree (repeat for multiple patterns) |

This directive is only supported in GitHub Corpus Repo, GitLab Corpus Repo,
and Google Drive sources. In the Corpora File (inline) source type it is not
supported — the directive is skipped and a warning is written to the build log.

**`[rss]`** — fetch articles from an RSS or Atom feed

```ini
[rss]
url = https://blog.example.com/feed.xml
max_items = 25
crawl_links = false
max_workers = 5
```

| Key             | Description |
|-----------------|-------------|
| `url`           | RSS or Atom feed URL (repeat for multiple feeds) |
| `max_items`     | Maximum feed entries to process (default: 50) |
| `crawl_links`   | If `true`, follow links found on each article page (default: `false`) |
| `max_crawl`     | Maximum pages to crawl per article when `crawl_links` is `true` (default: 100) |
| `domain`        | Additional domain patterns to allow for cross-domain crawling (repeat for multiple) |
| `max_workers`   | Number of parallel fetch threads for article pages (default: 5, max: 20) |

**`[excludes]`** — URL patterns to exclude from all crawls in this file

```ini
[excludes]
url = https://example.com/*/comments
url = https://blog.example.com/tags/*
url = https://example.com/page/*/print
```

| Key   | Description |
|-------|-------------|
| `url` | URL pattern to exclude (fnmatch wildcards supported, e.g. `*`, `?`). Repeat for multiple patterns. |

Exclude patterns apply to all `[web]` and `[rss]` crawls within the same
`.corpora` file. Place the `[excludes]` section before the `[web]` and `[rss]`
sections to make it clear which patterns are in effect. Patterns are matched
against fully-qualified absolute URLs using fnmatch wildcard rules.

Unknown section types emit a warning in the build log and are skipped.

### Example `.corpora` file

```ini
# Exclude noisy pages from all crawls
[excludes]
url = https://docs.example.com/*/changelog
url = https://docs.example.com/*/archive

# Crawl the documentation site
[web]
url = https://docs.example.com
crawl_links = true
max_crawl = 200

# Pull in specific repo files
[files]
source = README.md
source = docs/*.md

# Index the company blog
[rss]
url = https://blog.example.com/feed.xml
max_items = 30
```

---

## User Management

### Roles

Every user in the system has one of the following roles:

**superadmin** — Users listed in the `ADMIN_EMAILS` environment variable (set
at deploy time as a comma-separated list). Superadmins always have full admin
access, cannot be denied, and cannot be modified or deleted through the admin
UI. Their role shows as `owner` in the user list. Only superadmins can
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
| Business | 50       |

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
| Free     | 500,000             |
| Basic    | 3,000,000           |
| Pro      | 10,000,000          |
| Business | 25,000,000          |

### Tracking modes

Admins can choose between two token tracking modes from the Users panel:

**Per-user** — The monthly budget is divided equally among all user slots
(`token_budget ÷ user_cap`). Each user has their own counter. Both the
per-user limit and the shared pool are always enforced — a user is blocked
when their individual slice is exhausted, and all users are blocked when the
shared pool is exhausted.

**Shared** — All users draw from a single pool equal to the full
`token_budget`. Both the shared pool and each user's individual slice
(`token_budget ÷ user_cap`) are always enforced. A user is blocked when
either limit is reached.

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

Identity provider availability depends on your plan tier:

| Provider            | Free | Basic | Pro | Business |
|---------------------|------|-------|-----|----------|
| Email / Password    | ✓    | ✓     | ✓   | ✓        |
| Google Sign-In      | —    | ✓     | ✓   | ✓        |
| SAML 2.0            | —    | —     | —   | ✓        |
| OIDC                | —    | —     | —   | ✓        |

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

### Google Sign-In

Allows users to sign in with a Google account via Cognito's Google OAuth2
integration. Requires Basic plan or higher.

**Before enabling Google Sign-In**, create an OAuth 2.0 client ID in Google
Cloud Console and add both values shown in the Identity tab:

- **Authorized JavaScript origin** — the root URL of your MyCorpus.ai app
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

### SAML 2.0

Connects any SAML 2.0 identity provider — Okta, Azure AD, Ping, OneLogin, or
any other SAML-compliant IdP. Multiple SAML providers can be configured
simultaneously. Requires Business plan.

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

### OIDC

Connects any OpenID Connect provider — Okta, Auth0, Azure AD in OIDC mode,
or any other OIDC-compliant IdP. Multiple OIDC providers can be configured.
Requires Business plan.

**Register Cognito in your OIDC provider** using these values from the
Identity tab:

- **Sign-in redirect URI** — the Cognito OAuth2 callback URL
- **Sign-out redirect URI** — the Cognito logout URL
- **Trusted Origins / Base URI** — the root URL of your MyCorpus.ai app
  (required by Okta's Trusted Origins setting)

**To add an OIDC provider:**

1. Register a new application in your OIDC provider and paste in the redirect
   and sign-out URIs above.
2. On the Identity tab, enter a **Display Name** (e.g. `Okta` or `Auth0`).
3. Enter the **Issuer URL** (e.g. `https://your-org.okta.com`).
4. Enter the **Client ID** and **Client Secret** from your OIDC provider.
5. Click **Add OIDC Provider**.

The connector requests `email profile openid` scopes. The email claim is
mapped to the Cognito user's email attribute.

---

## MCP Connector (Claude Connector)

The MCP Connector exposes your corpora to Claude via the Model Context Protocol.
Once connected, Claude retrieves relevant passages from your knowledge bases
during conversations.

### Enabling or disabling the connector

Admins can enable or disable the Claude Connector for all users from the
**Users** tab using the **Claude Connector** toggle. When disabled, users who
open the Claude Connector settings panel see a message asking them to contact
their system administrator. Disabling the connector hides the panel in the UI
but does not block existing API keys or OAuth tokens from authenticating — the
MCP endpoint remains accessible regardless of this setting.

### Connecting claude.ai

1. In claude.ai, go to **Settings → Connectors → Add custom connector**.
2. Paste the **MCP Server URL** from the Claude Connector panel in the
   MyCorpus.ai settings sidebar into the URL field and click **Connect**.
3. A login window opens — sign in with your MyCorpus.ai account.
4. Once authenticated, your knowledge bases are available in every claude.ai
   conversation.

The MCP Server URL is shown on the Claude Connector settings panel. Each
MyCorpus.ai deployment has a single shared MCP Server URL.

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
limits, user caps, token budgets, and identity provider availability
simultaneously.

| Tier     | Corpora | Chunks/corpus | Users | Monthly tokens | Google login | SAML / OIDC |
|----------|---------|---------------|-------|----------------|--------------|-------------|
| Free     | 5       | 20,000        | 5     | 500,000        | —            | —           |
| Basic    | 10      | 30,000        | 10    | 3,000,000      | ✓            | —           |
| Pro      | 25      | 50,000        | 25    | 10,000,000     | ✓            | —           |
| Business | 50      | 100,000       | 50    | 25,000,000     | ✓            | ✓           |

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
> You are a helpful AI assistant grounded in the provided knowledge base.
> Answer questions accurately based on the knowledge base. If the knowledge
> base does not contain enough information to answer, say so clearly rather
> than speculating.

The system prompt can be updated at runtime via the Settings panel or the
corpus settings API without a redeployment. Changes take effect on the next
query.

### AI retrieval settings

The Settings tab (admin only) exposes three retrieval parameters that can be
changed without redeployment:

**Knowledge Search Depth** (`top_k`) — How many passages the AI considers
before answering. Options: 5 (Focused), 10 (Balanced, **default**), 15
(Thorough), 20 (Exhaustive). Lower values reduce token cost per query; higher
values improve coverage for complex questions.

**Conversation Memory** (`history_window`) — Number of previous Q&A turns
included as context. Options: 3 (Short), 5 (Standard, **default**), 10
(Extended). Increase if users frequently refer back to earlier parts of a
conversation.

**Excerpt Length** (`max_chunk_chars`) — Maximum characters of each knowledge
base passage sent to the model. Options: 800 (Compact), 1,500 (Standard,
**default**), 3,000 (Full). Longer excerpts provide more context but consume
more tokens per query.

### Sidebar navigation links

Admins can configure custom navigation links that appear in the sidebar for all
users. Each link has a label and a URL and opens in a new browser tab.

### Support email

The contact email shown on the Plan tab for users who want to inquire about
upgrading. Set via the `support_email` Terraform variable.

---

## Data Security

### Sensitive credential storage

Personal access tokens (GitHub, GitLab), API keys (YouTube), and OAuth refresh
tokens (Google Drive) are stored in S3 in the corpus `sources.json` file.
They are never returned to the browser. The indicator field returned depends
on the source type: GitHub sources return `pat_configured: true`; GitHub
Corpus Repo, GitLab, and GitLab Corpus Repo sources return
`token_configured: true`; YouTube sources return `api_key_configured: true`;
Google Drive sources return `refresh_token_configured: true`. ZIP Archive and
Corpora File sources have no sensitive credentials. To update a credential,
submit a new value. Submitting `null` keeps the existing credential unchanged;
submitting an empty string clears it.

MCP API keys (the `mc_` tokens users generate for Claude clients) are never
stored in plain form. Only a SHA-256 hash is persisted in DynamoDB. The raw
key is returned to the user exactly once, at creation time.

### Superadmin protection

Superadmins are identified by the `ADMIN_EMAILS` environment variable, which
is set at deploy time and requires a Terraform change to modify. Superadmin
accounts cannot be denied, deleted, or have their role changed via the admin
UI, regardless of what DynamoDB contains.

### Token tracking and budget enforcement

Token budgets are enforced per-period (calendar month). The system tracks both
a per-user counter and a shared global counter for every query. Both limits
are always enforced simultaneously — a query is blocked if either the shared
pool is exhausted or the requesting user has reached their individual slice
(`token_budget ÷ user_cap`). The tracking mode (`per_user` or `shared`)
controls only which counter is displayed in the UI. A DynamoDB failure during
the authorization check fails open (the request proceeds). A DynamoDB failure
during the token budget check returns HTTP 500 — the query is blocked.

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
cannot be deleted or have their role changed through the admin UI. Their role
shows as `owner` in the user list. To add or remove a superadmin, update the
`ADMIN_EMAILS` variable and re-apply Terraform.

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
provider (the single configured Google OAuth app). SAML and OIDC require the
Business plan; Google Sign-In requires Basic plan or higher.

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

Both the shared pool and the per-user allocation are always enforced,
regardless of tracking mode — a query is blocked if either limit is exceeded.
In **per-user** mode, the monthly budget is divided by the user cap
(`token_budget ÷ user_cap`); a user is blocked when their individual slice
runs out, and all users are blocked when the shared pool is exhausted.
In **shared** mode, all users draw from a single pool equal to the full
`token_budget`; individual users are also blocked when their per-user slice
(`token_budget ÷ user_cap`) runs out. The tracking mode controls which counter
is displayed in the UI — it does not change what is enforced. The mode can be
changed at any time from the Users panel.

**What is the MCP Server URL used for?**

The MCP Server URL is the endpoint Claude uses to retrieve passages from your
knowledge bases via the Model Context Protocol. In claude.ai, paste this URL
when adding a custom connector. The connection is authenticated via OAuth —
users sign in with their MyCorpus.ai account the first time they connect.

**How do I revoke a user's MCP API key?**

Users manage their own API keys from their profile. An admin cannot view or
revoke another user's keys. If a key is compromised, the affected user should
revoke it from their profile. If the user account itself needs to be
deactivated, set the user's role to `denied` or delete their account — both
actions block all future authenticated requests regardless of key state.

**Can I disable the Claude Connector for all users?**

Yes. On the Users tab, use the **Claude Connector** toggle to enable or disable
the MCP connector for the entire deployment. When disabled, users see a message
asking them to contact their administrator. Existing API keys are preserved and
continue to authenticate normally — disabling the connector hides the UI panel
but does not block the MCP endpoint.

**Are credentials like GitHub PATs visible to admins in the UI?**

No. Personal access tokens, API keys, and OAuth refresh tokens submitted via
the source configuration UI are stored in S3 and never returned to the browser.
The API returns a boolean indicator (`pat_configured` for GitHub;
`token_configured` for GitHub Corpus Repo, GitLab, and GitLab Corpus Repo;
`api_key_configured` for YouTube; `refresh_token_configured` for Google Drive)
to show whether a credential is set. The raw value cannot be retrieved after
it is saved.

**What builds does the system send email notifications for?**

The system emails all superadmins after every corpus build — both successful
builds and failed ones, including scheduled builds and cancelled builds. The
email includes a per-source document count, error details for any failed
sources, the total chunk count, and an attached CloudWatch log. Notifications
require SMTP to be configured via the `smtp_server`, `smtp_port`, `smtp_user`,
and `smtp_password` Terraform variables. If SMTP is not configured,
notifications are silently skipped.

**What happens to users when I downgrade to a lower plan tier?**

Switching to a lower-paid tier via the Plan API immediately purges all
non-superadmin users from Cognito and DynamoDB. Superadmin accounts are
preserved. Purged users must re-register once the new plan is active. Note
that downgrading to the free tier is not available through the Plan API — the
free tier is only reached by cancelling the subscription outside the admin UI.

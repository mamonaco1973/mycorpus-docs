# mycorpus Administrator Guide

This guide covers everything an administrator needs to configure, operate, and maintain a mycorpus deployment. Administrators have access to a dedicated admin panel that is not visible to regular users.

---

## Admin Panel Overview

### How do I access the admin panel?

Log in with an account that has admin or owner privileges. The admin navigation appears in the left sidebar. The admin panel contains five tabs: **Corpora**, **Login Page**, **Links**, **Users**, and **Identity**.

### What is the difference between an Owner and an Admin?

**Owners** are defined by the `ADMIN_EMAILS` environment variable set at deployment time. Owners bypass all user caps and token limits, cannot be deleted or denied through the interface, and always have full access regardless of plan tier or other settings.

**Admins** are regular users whose role has been set to Admin through the Users tab. Admins have access to the full admin panel and can manage corpora, users, and settings. Admins are subject to the standard user cap and token budget unless elevated.

**Regular users** can only access the chat interface.

---

## Corpora

### What is a corpus?

A corpus is a named collection of content that mycorpus searches to answer user questions. You can create multiple corpora covering different topics, teams, or projects. Each corpus has its own sources, build history, and configuration.

### How do I create a corpus?

In the admin panel, go to the **Corpora** tab and click **New Corpus**. Enter a name and optional description. The corpus is created immediately but contains no content until you configure sources and trigger a build.

### How do I configure sources for a corpus?

Select a corpus from the list, then open the **Sources** tab within the corpus detail view. Click **+ Add Source** to add a source. Choose the source type from the dialog and fill in the required fields. You can add multiple sources of different types — all sources are combined into a single corpus during the build.

### How do I build a corpus?

After configuring sources, click **Build Corpus**. This launches a background build process. The build status changes to **Building** while it runs. When complete, the status changes to **Ready** and the corpus becomes available for chat. Build time depends on the size and number of sources — a typical build takes a few minutes to an hour.

### How much does a corpus build cost?

The corpus builder runs on AWS ECS Fargate. A two-hour build on a 1 vCPU / 2 GB container costs approximately $0.10. There is no fixed overhead — you are billed per second of actual run time.

### What happens if a build fails?

The corpus status changes to **Error**. An email notification is sent to all Owner accounts with a summary of which sources succeeded and which failed. The previous successful build remains active — users can continue chatting using the last known-good corpus while you investigate and re-trigger.

### How do I view the build log?

In the corpus detail view, click the **Log** tab while a build is running, or after it completes. The log streams from AWS CloudWatch and shows detailed progress from each ingestor. Failed sources are clearly marked.

### What is CORPUS.md?

CORPUS.md is a plain-text description of what a corpus covers. It is used as the tool description when the corpus is exposed through the MCP Connector to Claude Desktop, so Claude knows when to search that corpus. It is also useful documentation for anyone managing the knowledge base.

CORPUS.md can come from three places, in order of priority:

1. **Source document** — place a file named `CORPUS.md` in a GitHub or GitLab Corpus Repo source. It is detected automatically during the build.
2. **AI generation** — if no CORPUS.md is found in source documents, the build process samples up to 30 content chunks and calls Bedrock to generate a description automatically.
3. **Manual edit** — you can write or overwrite the description at any time in the corpus detail panel. Select a corpus, open the **Sources** sub-tab, then click the **CORPUS.md** inner tab.

Manual edits are preserved across corpus rebuilds. The ingestor only writes a new CORPUS.md if the field is currently blank.

### How do I edit CORPUS.md manually?

Select the corpus from the Corpora list. In the corpus detail panel, click the **CORPUS.md** inner tab (next to Sources). A text editor appears with the current content. Edit the description and click **Save**. To discard your edits and regenerate from the corpus content, click **Regenerate with AI**.

### What is the chunk limit?

Each corpus has a maximum number of text chunks determined by your plan tier. If the chunk limit is reached during a build, ingestion stops and the email notification notes that content was truncated. To index more content, upgrade your plan or reduce the number of sources.

| Plan     | Chunk limit per corpus |
|----------|------------------------|
| Free     | 10,000                 |
| Basic    | 25,000                 |
| Pro      | 50,000                 |
| Business | 100,000                |

---

## Source Types

### GitHub Source

The GitHub source crawls a GitHub user's or organisation's public repositories and fetches specific files (such as README.md) from each one. This is useful for indexing documentation spread across many repositories.

Configuration fields:
- **GitHub User / Org** — the GitHub username or organisation name
- **Personal Access Token** — a GitHub PAT with `public_repo` scope for public repos, or `repo` scope for private repos. Required for higher API rate limits.
- **Files to fetch** — comma-separated list of file paths to retrieve from each repo (e.g. `README.md, CLAUDE.md, docs/overview.md`)
- **Repo filter** — optional comma-separated list of repository names to include. Leave blank to include all repos.

### GitHub Corpus Repo Source

The GitHub Corpus Repo source treats a single GitHub repository as a document store. Every file in the repository (or a subdirectory) whose extension is supported is downloaded and added to the corpus. This is the recommended approach when you maintain documentation in a GitHub repository and want automatic updates on scheduled rebuilds.

Configuration fields:
- **Repository** — the repository in `owner/repo` format (e.g. `myorg/knowledge-base`)
- **Branch** — the branch to read from (default: `main`)
- **Path prefix** — optional subdirectory to limit ingestion (e.g. `docs/`). Leave blank to include all files.
- **Personal Access Token** — optional for public repos; required for private repos.

Supported file types: `.txt`, `.md`, `.rst`, `.pdf`, `.docx`

Files named with a `.url` extension are treated as URL crawl instructions. The file should contain either a plain URL (one per file) or a JSON object: `{"url": "https://example.com", "crawl_links": true, "title": "Optional title"}`. When `crawl_links` is true, the crawler follows links on the target page up to 100 pages deep within the same domain.

### GitLab Source

The GitLab source mirrors the GitHub source but connects to GitLab. It lists all projects owned by a user or group and fetches specified files from each project. Supports both gitlab.com and self-hosted GitLab instances.

Configuration fields:
- **GitLab Host** — leave blank for `gitlab.com`, or enter your self-hosted instance URL (e.g. `gitlab.mycompany.com`)
- **User or Group** — the GitLab username or group path
- **Personal Access Token** — a GitLab PAT with `read_api` and `read_repository` scopes
- **Files to fetch** — comma-separated file paths to retrieve from each project
- **Project filter** — optional comma-separated list of project path names to include

### GitLab Corpus Repo Source

The GitLab Corpus Repo source treats a single GitLab repository as a document store, identical in behaviour to the GitHub Corpus Repo source but using the GitLab API. Supports self-hosted GitLab instances.

Configuration fields:
- **GitLab Host** — leave blank for `gitlab.com`
- **Repository** — the project in `namespace/project` format (e.g. `mygroup/knowledge-base`)
- **Branch** — the branch to read from (default: `main`)
- **Path prefix** — optional subdirectory filter
- **Personal Access Token** — optional for public projects; required for private projects

Supported file types and `.url` file handling are identical to the GitHub Corpus Repo source.

### YouTube Source

The YouTube source downloads transcripts from a YouTube channel's public videos. This is useful for indexing recorded presentations, training videos, or any channel whose spoken content should be searchable.

Configuration fields:
- **Channel ID** — the YouTube channel ID (starts with `UC`). Find it in the channel's About page or in the URL.
- **YouTube API Key** — a Google Cloud API key with the YouTube Data API v3 enabled.
- **Max videos** — the maximum number of recent videos to process (most recent first)

Only videos with available transcripts (auto-generated or manually uploaded) can be indexed. Videos without transcripts are skipped with a warning in the build log.

### Web Page Source

The Web Page source fetches content from a URL. You can add a single URL or paste multiple URLs at once. Optionally enable link crawling to follow same-domain links up to 100 pages deep.

Configuration fields:
- **URL** — the web page address. Must begin with `https://` or `http://`
- **Follow links on this page** — when enabled, the crawler follows every same-domain link found on the root page, up to 100 pages total (1 level deep)

When adding multiple URLs at once, paste one URL per line. The crawl-links option applies to all URLs in the batch.

### Q&A Source

The Q&A source lets you enter question-and-answer pairs directly. This is useful for FAQs, known issues, policy statements, or any content that is best expressed as a direct question and answer rather than as a document.

Each Q&A entry has a question field and an answer field. The question and answer are combined into a single document chunk and embedded into the corpus. Questions submitted by users that closely match a Q&A entry will surface that answer.

### Document Upload Source

The Document Upload source allows you to upload files directly through the admin interface. Uploaded documents are stored in S3 and included in every corpus build automatically — you do not need to re-upload them when rebuilding.

Supported file types: `.txt`, `.md`, `.pdf`, `.docx`

To upload a document: in the corpus detail view, open the **Sources** tab, click **Upload Document**, and select a file. The document is immediately stored and will be included in the next build.

---

## Users

### How do I view all users?

In the admin panel, go to the **Users** tab. This shows every registered user, their email address, role, token usage, and account status.

### What are the access modes?

mycorpus supports two access modes:

**Open mode** — any user who signs up is immediately granted access. This is the default for low-friction deployments where anyone with the link should be able to use the system.

**Closed mode** — new users who sign up are placed in a pending state and cannot use the chat until an administrator approves them. Use closed mode when you need to control who can access the system.

Switch between modes using the **Access Mode** toggle in the Users tab.

### How do I approve or deny a user?

In the Users tab, find the user in the list. Use the role selector to set their status:
- **Allowed** — the user can access the chat
- **Denied** — the user is blocked from the chat
- **Admin** — the user can access the admin panel and manage the system

### How do I pre-authorise a user before they sign up?

In the Users tab, click **Pre-authorize User** and enter their email address. When that person signs up using that exact email address, they are immediately granted access without waiting for manual approval. This is useful in closed mode when you want to invite specific people.

### How do I delete a user?

In the Users tab, click the delete option next to a user. This removes the user from both Cognito (the authentication system) and the usage database. The user will no longer be able to log in. Their conversation history is not automatically deleted from S3.

### Can I delete an Owner account?

No. Owner accounts are defined by the `ADMIN_EMAILS` environment variable at deployment time. They cannot be denied, demoted, or deleted through the admin interface. To remove an owner, update the environment variable and redeploy.

---

## Identity Providers

### What identity providers does mycorpus support?

mycorpus supports three external identity providers in addition to the built-in email and password login:

- **Google** — available on Pro and Business plans
- **SAML** — available on Business plans only
- **OIDC** — available on Business plans only

Email and password login is always available and cannot be disabled. It serves as the recovery path if an identity provider is misconfigured.

### How do I configure Google login?

Go to the **Identity** tab in the admin panel. If your plan supports Google login, the Google card will be active. Click **Configure** and enter:
- **Client ID** — from the Google Cloud Console OAuth credentials
- **Client Secret** — from the same credentials page

To create Google OAuth credentials: in the Google Cloud Console, go to APIs & Services → Credentials → Create Credentials → OAuth client ID. Set the application type to Web Application. Add the callback URL shown in the mycorpus Identity tab to the Authorised redirect URIs list.

### How do I configure SAML login?

Go to the **Identity** tab and open the SAML card (Business plan required). Click **Configure** and enter:
- **Metadata URL** — the URL of your identity provider's SAML metadata XML. Cognito fetches the certificate automatically from this URL.

From the Identity tab, copy the **ACS URL**, **Entity ID**, and **Metadata URL** shown in the Service Provider section and enter them into your identity provider's SAML application configuration.

### How do I configure OIDC login?

Go to the **Identity** tab and open the OIDC card (Business plan required). Click **Configure** and enter:
- **Client ID** — from your OIDC provider's application settings
- **Client Secret** — from the same settings
- **Issuer URL** — the OIDC discovery endpoint (e.g. `https://accounts.example.com`)

### What happens if I misconfigure an identity provider?

Email and password login remains active as a fallback at all times. If an SSO configuration is broken, administrators can still log in with their email and password and correct the identity provider settings.

---

## Login Page and Branding

### How do I customise the login page?

In the admin panel, go to the **Login Page** tab. From here you can set:
- **Assistant name** — displayed as the product name throughout the interface
- **Welcome message** — shown on the login page below the product name
- **Logo** — upload a custom logo image
- **Accent colour** — the primary colour used in buttons and highlights

Changes take effect immediately without requiring a rebuild.

### How do I add links to the navigation?

Go to the **Links** tab in the admin panel. Add URLs and labels that will appear in the application navigation. This is useful for linking to related internal tools, documentation sites, or support pages.

---

## Plan Tiers

mycorpus is available in four plan tiers. The active tier is stored in the system configuration and controls chunk limits, user caps, and available features.

| Feature                   | Free     | Basic    | Pro      | Business   |
|---------------------------|----------|----------|----------|------------|
| Users                     | 5        | 10       | 25       | Variable   |
| Corpora                   | 2        | 10       | 25       | 100        |
| Chunks per corpus         | 10,000   | 25,000   | 50,000   | 100,000    |
| Tokens per user per week  | 100,000  | 250,000  | 500,000  | Variable   |
| Google login              | No       | No       | Yes      | Yes        |
| SAML / OIDC login         | No       | No       | No       | Yes        |
| Scheduled corpus rebuilds | No       | No       | Yes      | Yes        |

Owner accounts bypass user caps and have a 2× token multiplier applied at query time.

---

## Token Budgets

### How does the token budget work?

Each user has a weekly token budget. Tokens are consumed when the AI model generates a response. The budget resets every Sunday at 01:00 UTC. Usage does not carry over between weeks.

### How is the token budget set?

The default token budget is configured at deployment time and applies to all users. It is stored in the system configuration. Owner accounts have a 2× multiplier applied automatically — a 100,000-token budget becomes 200,000 for owners.

### What happens when a user hits their limit?

The user sees a message that their budget is exhausted and when it resets. They cannot submit new queries until the reset. Their existing conversations remain accessible for reading.

---

## Scheduled Corpus Rebuilds

Scheduled corpus rebuilds allow a corpus to be automatically rebuilt on a daily or weekly schedule without manual intervention. This is particularly useful when using GitHub Corpus Repo, GitLab Corpus Repo, or URL sources where the source content changes over time.

Scheduled rebuilds are available on Pro and Business plans. Configuration fields (frequency, hour, day of week) are reserved in the system and will be enabled in a forthcoming release.

---

## MCP Connector

The MCP Connector lets users connect Claude Desktop to their mycorpus knowledge bases using the Model Context Protocol. Once connected, Claude Desktop can search corpora directly during a conversation — no copy-pasting required.

### How does the MCP Connector work?

mycorpus exposes a `/mcp` endpoint that implements the MCP Streamable HTTP transport. Each user provisions a personal API key, adds it to their Claude Desktop configuration, and Claude can then call `list_corpora` and `search_<corpus>` tools when answering questions.

The MCP Connector is available to all registered users, not just administrators.

### How do users set up the MCP Connector?

Users open their settings (the person icon in the sidebar), navigate to the **MCP Connector** tab, and click **Generate** to create an API key. The raw key is shown once and must be copied immediately. The settings panel also displays a ready-to-paste JSON snippet for `claude_desktop_config.json`.

### What tools does the MCP endpoint expose?

Two tool types are exposed:

- `list_corpora` — returns a list of all ready corpora with their CORPUS.md descriptions, so Claude can decide which corpus to search.
- `search_<corpus_id>` — performs a semantic search over a specific corpus and returns the top relevant passages. One tool is created per built corpus.

The CORPUS.md description of each corpus becomes the tool description. A well-written CORPUS.md helps Claude select the right corpus for each question automatically.

### How do I revoke an API key?

Users can revoke their own keys from the MCP Connector settings panel by clicking **Revoke** next to the key. Administrators cannot revoke other users' keys through the admin panel. Revocation takes effect immediately on the next API call.

### How many API keys can a user have?

There is no enforced limit. Users can generate as many keys as they need — for example, one per device or one per Claude Desktop profile.

---

## Data and Security

### Where is corpus data stored?

All corpus data is stored in an S3 bucket within your dedicated AWS account. Each tenant has their own isolated AWS account — data is never co-mingled with other organisations. The built corpus artifacts (chunk text and embeddings) live at `corpora/{id}/builds/{timestamp}/` in that bucket. Source configuration is stored at `corpora/{id}/sources.json`. Uploaded documents are stored at `corpora/{id}/documents/`.

### Who has access to my data?

Data is contained within your dedicated AWS account. Only AWS services operating within that account (Lambda, ECS, Bedrock) access it during normal operation. No data is shared with other tenants or external parties. AWS Bedrock processes inference requests in memory without persisting prompts or completions.

### How is data encrypted?

Data at rest in S3 and DynamoDB is encrypted using AWS-managed KMS keys by default. For enhanced isolation, a customer-managed KMS key (CMK) can be configured per deployment, allowing cryptographic destruction of all corpus data by deleting the key.

Data in transit between services uses TLS. Traffic between the ECS corpus builder and AWS APIs stays within the AWS network.

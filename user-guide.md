# My Corpus — User Guide

## Table of Contents

- [Getting Started](#getting-started)
- [Signing In](#signing-in)
- [The Chat Interface](#the-chat-interface)
- [Conversations](#conversations)
- [Sources and Citations](#sources-and-citations)
- [Token Budgets](#token-budgets)
- [Corpora](#corpora)
- [Building a Corpus](#building-a-corpus)
- [Source Types](#source-types)
  - [GitHub (User Repositories)](#github-user-repositories)
  - [GitHub Corpus (Single Repository)](#github-corpus-single-repository)
  - [GitLab (User Repositories)](#gitlab-user-repositories)
  - [GitLab Corpus (Single Repository)](#gitlab-corpus-single-repository)
  - [YouTube](#youtube)
  - [Q&A Pairs](#qa-pairs)
  - [Web Pages](#web-pages)
  - [Paste Text](#paste-text)
  - [Upload Files](#upload-files)
- [Admin: CORPUS.md](#admin-corpusmd)
- [Admin: Managing Users](#admin-managing-users)
- [Admin: Token Tracking](#admin-token-tracking)
- [Admin: Access Mode and Registration](#admin-access-mode-and-registration)
- [Admin: Appearance and Branding](#admin-appearance-and-branding)
- [Admin: Identity and SSO](#admin-identity-and-sso)
- [Admin: Support](#admin-support)
- [Plan Tiers](#plan-tiers)
- [Troubleshooting](#troubleshooting)

---

## Getting Started

My Corpus is a retrieval-augmented AI chat application. You ask questions in plain language and the system answers using content from one or more knowledge bases (called *corpora*) that have been built from your organisation's documents, repositories, web pages, and other sources.

Before you can chat, a corpus must be built by an administrator. If no corpus has been built yet, your questions will receive a message saying so. Contact your administrator if the knowledge base appears to be missing.

The first time you visit the application after logging in, your account is registered automatically. On deployments where registration is open, this succeeds silently. On deployments where the administrator has enabled closed access, you must be pre-authorised before your first login will work.

---

## Signing In

**How do I sign in?**

Click the sign-in button on the landing page. You will be redirected to the Cognito Hosted UI. Enter your email and password. On Pro and Business plans, your administrator may have enabled Google login as an alternative. On Business plans, SAML or OIDC single-sign-on may also be available.

After authentication you are redirected back to the application. Your session tokens are stored locally in your browser. The application checks your token on every page load and silently refreshes it when it is close to expiring, so you will not normally be asked to sign in again during an active session.

**What happens if I am denied access?**

If your account has been denied by an administrator, you will see an "Access required" message after signing in and will be logged out automatically. Contact your administrator to request access.

**What happens if the system is at capacity?**

If your plan's user limit has been reached, you will see an "Access unavailable" message. Contact your administrator.

**How do I sign out?**

Click your avatar or name in the bottom-left of the sidebar to open the user menu, then click "Sign out". You will be asked to confirm. Signing out clears your session tokens from the browser.

---

## The Chat Interface

**How do I ask a question?**

Type your question into the input box at the bottom of the screen and press **Enter** to send. To insert a line break without sending, press **Shift+Enter**. The input box grows automatically as you type, up to a maximum height.

You can also click one of the starter question buttons shown on the empty-state screen. These are example questions drawn from the selected corpus and are reshuffled randomly each time you start a new conversation or switch corpus.

**Can I send a message while one is still being processed?**

No. The send button and input box are disabled while a query is in progress. Wait for the current answer to arrive before asking the next question.

**How long does it take to get an answer?**

Queries are processed asynchronously. After you send a question the interface shows animated dots while waiting. The application checks for an answer every 2 seconds. If no answer arrives within 2 minutes, the query times out and you will see an error message. This can happen if the backend worker encountered a problem.

**Can I cancel a query?**

Yes. While a query is pending or processing, a Cancel button appears in the chat bubble. Clicking it stops the polling and marks the query as cancelled in the interface. Note that cancelling in the browser does not stop server-side processing; it only means the browser stops waiting for the result.

**How are answers formatted?**

Answers are rendered as Markdown. Text with headings, bullet lists, bold, and code blocks will display with appropriate formatting.

**What are the starter question buttons?**

When you open a new conversation or visit the empty-state screen, up to four starter questions are displayed. These come from the selected corpus's configured starter questions, shuffled randomly. Clicking one fills the input box and submits it immediately.

**Is there a theme option?**

Yes. Open the user menu (click your avatar in the sidebar), choose Settings, then go to the Appearance tab. You can select from the available themes. Your choice is saved in the browser.

**How do I contact my administrator?**

Open the user menu (click your avatar in the sidebar) and click "Contact Admin". This opens a contact dialog with details for reaching the administrator.

---

## Conversations

**What is a conversation?**

A conversation is a persistent thread of questions and answers. Each conversation is pinned to a specific corpus at the time it is created. All questions in a conversation are answered from that same corpus, and the system uses previous turns as context to give more coherent follow-up answers.

**How many previous turns does the system remember?**

The system includes a configurable number of previous completed question-and-answer pairs as context when generating each new answer. This window is set by the administrator in the runtime configuration. Older turns beyond the window are not included, but they remain visible in the chat history display.

**How are conversations named?**

A new conversation starts with the default title `New conversation` (no trailing period). The first question you ask replaces this title automatically. The title is then fixed for the lifetime of the conversation.

**How do I start a new conversation?**

Click the **New Chat** button at the top of the sidebar. A new conversation is created immediately, pinned to whichever corpus is currently selected in the corpus picker above the input box.

**How do I switch between conversations?**

Click any conversation in the sidebar list. Conversations are shown newest first. The full question-and-answer history for the selected conversation loads immediately.

**How do I delete a conversation?**

Hover over a conversation in the sidebar to reveal the delete option and click it. Deleting a conversation removes it and all its messages permanently, including the stored question and answer text. This cannot be undone.

**How do I switch corpus for a new conversation?**

Use the corpus picker dropdown above the chat input box. Selecting a different corpus updates your choice locally and applies it to the next conversation you create. Existing conversations remain pinned to the corpus they were created with.

---

## Sources and Citations

**Does the system cite its sources?**

Yes. Each completed answer includes a collapsible Sources section below the text. Click the "N sources" toggle to expand or collapse the list.

**What do the source links do?**

The behaviour depends on the type of source:

- Sources from uploaded files (PDFs, Word documents, and other files) show a document icon. Clicking one triggers a download of the original file.
- Sources from web URLs and GitHub or GitLab pages show an arrow icon. Clicking one opens the source page in a new browser tab.
- Sources from paste-text documents or Q&A pairs show a document icon with no link because there is no external URL.

Duplicate sources (same URL) are deduplicated before display, so each unique source appears only once even if multiple chunks from it contributed to the answer.

---

## Token Budgets

**What is a token budget?**

Every question you ask and every answer you receive consumes tokens — units that measure the volume of text processed by the AI model. Your plan includes a monthly token budget that resets at the start of each calendar month.

**How do I see my remaining budget?**

A circular token usage ring is displayed around your avatar in the sidebar. The ring fills as you use tokens. The label beneath shows exact numbers, for example "42K / 250K tokens". The ring colour changes from the default colour to amber when usage reaches 70% and to red when it reaches 90%. The display updates automatically every 30 seconds and after each completed query.

**What happens when I run out of tokens?**

If your budget is exhausted before the end of the month, your next question will be rejected and you will see a "Token limit reached" alert that shows the date your budget resets. Contact your administrator to request a budget reset or plan upgrade.

**What are the two tracking modes?**

Administrators can choose between two modes:

- **Per User:** The plan's total monthly budget is divided equally by the number of configured users. Each user has their own independent monthly allocation, preventing any single user from consuming tokens from another user's share. The plan's overall monthly ceiling still applies to all users combined.
- **Shared Pool:** All users draw from a single shared monthly budget. The total available is the plan's full monthly allowance. On busy deployments, heavy usage by one user reduces what is available for everyone else.

In both modes the system enforces both the per-user allocation and the overall plan total. A query is blocked if either limit is exceeded.

The administrator sets the tracking mode in the admin panel under the Users tab. The mode can be changed at any time.

---

## Corpora

**What is a corpus?**

A corpus is a searchable knowledge base built from one or more configured sources. When you ask a question, the system searches the corpus for relevant text chunks and uses them to generate the answer.

**Can there be more than one corpus?**

Yes. Your plan determines how many corpora your deployment can have (see Plan Tiers below). There is always a default corpus that cannot be deleted. Additional corpora can be created by administrators and appear in the corpus picker in the chat interface.

**How do I pick which corpus to use?**

Use the corpus picker dropdown above the chat input. Selecting a corpus affects the next conversation you create. The starter questions displayed on the empty-state screen update to reflect the selected corpus.

**When does a corpus become usable?**

A corpus must be built before it can answer questions. Its status is shown in the admin panel as one of:

- **not\_built**: No build has run yet.
- **building**: A build is in progress.
- **ready**: Built and available for queries.
- **error**: The last build failed. The corpus may still be queryable using a previous successful build, but a new build is needed to recover.
- **pending changes**: Sources have been added, edited, or removed since the last build. The corpus is still queryable using the previous build, but a new build is needed to include the changes.

**What is a chunk?**

During a build, each source document is split into overlapping text segments called chunks. Each chunk is converted to a numeric embedding vector. When you ask a question, the question is also embedded and the most semantically similar chunks are retrieved to form the answer context. Your plan sets the maximum number of chunks per corpus.

---

## Building a Corpus

**How do I trigger a build?** (Admin only)

Open the admin panel by clicking the Corpora button in the sidebar (visible to admins only). Select the corpus you want to build and click **Build Corpus**. This launches a background container (ECS Fargate task) that ingests all configured sources and generates the chunk embeddings. A build log panel appears and streams progress.

**How long does a build take?**

Build time depends on the number and size of sources. Small corpora with a few dozen documents may complete in a few minutes. Large corpora with thousands of files or many web pages may take considerably longer.

**Do I need to rebuild after adding a source?**

Yes. Adding, editing, or removing a source marks the corpus as "pending changes". The corpus remains queryable with the previous build but will not reflect the new sources until you trigger a new build.

**Can I download and re-upload source configuration?**

Yes. In the corpus detail panel, use the Download Sources button to save the current sources as a JSON file. Use the Upload Sources button to replace the current source configuration with a previously downloaded file. This is useful for bulk editing or migrating configuration between deployments. A confirmation dialog is shown before the upload replaces existing sources.

---

## Source Types

A corpus can draw content from any combination of the following source types.

---

### GitHub (User Repositories)

Ingests selected files from all public repositories belonging to a GitHub user or organisation.

**Fields:**

- **GitHub User / Org**: The GitHub username or organisation name whose repositories to scan.
- **Personal Access Token**: Optional. A GitHub PAT increases the API rate limit and allows access to private repositories. The token is stored encrypted and is never returned to the browser; the UI shows only whether a token has been configured.
- **Files to fetch**: A comma-separated list of filenames to extract from each repository. Defaults to `README.md`. You can add or change filenames such as `CHANGELOG.md` or `CONTRIBUTING.md`.
- **Repo filter**: An optional comma-separated list of repository names. If provided, only repositories whose names match are ingested. Leave blank to ingest all repositories.

You can add multiple GitHub source entries if you need to include repositories from more than one user or organisation.

---

### GitHub Corpus (Single Repository)

Ingests the full content of a single GitHub repository, optionally scoped to a directory path and branch.

**Fields:**

- **Repository**: The full repository path in `owner/repo` format, for example `my-org/my-docs`.
- **Branch**: The branch to read from. Defaults to `main`.
- **Path**: An optional subdirectory path within the repository. Leave blank to ingest the entire repository.
- **Token**: A GitHub PAT or fine-grained access token for private repositories. Stored securely and never returned to the browser.

Use this source type when you want to ingest the complete content of a documentation or knowledge repository rather than just selected files across many repos.

---

### GitLab (User Repositories)

Ingests selected files from all repositories belonging to a GitLab user or group.

**Fields:**

- **GitLab host**: The GitLab instance hostname. Defaults to `gitlab.com`. Change this for self-hosted GitLab installations.
- **GitLab user or group**: The username or group name whose repositories to scan.
- **Files to include**: Filenames to extract from each repository. Defaults to `README.md`.
- **Repo filter**: Optional comma-separated list of repository names to limit ingestion.
- **Access Token**: A GitLab personal access token. Stored securely and the UI shows only whether one has been configured.

---

### GitLab Corpus (Single Repository)

Ingests the full content of a single GitLab repository, optionally scoped to a path and branch.

**Fields:**

- **GitLab host**: Hostname of the GitLab instance. Defaults to `gitlab.com`.
- **Repository**: Full path in `namespace/project` format.
- **Branch**: Branch to read from. Defaults to `main`.
- **Path**: Optional subdirectory to scope the ingestion.
- **Token**: GitLab access token for private repositories. Stored securely.

---

### YouTube

Ingests transcripts from all public videos on a YouTube channel.

**Fields:**

- **YouTube Channel ID**: The channel ID (the alphanumeric string starting with `UC`). This is not the channel name or handle; it can be found from the channel's About page or by using the Share menu on the channel page.
- **API Key**: A Google Cloud API key with the YouTube Data API v3 enabled. Required to list videos on the channel. Stored securely and the UI shows only whether one has been configured.

Only videos with available captions or auto-generated transcripts are ingested. Videos without transcripts are skipped.

---

### Q&A Pairs

Manually authored question-and-answer pairs that are included directly in the corpus. Use this source type to add curated content that may not exist in any document or web page, such as internal FAQs or policy statements.

**Fields:**

- **Question**: The question text.
- **Answer**: The answer text.

You can add as many Q&A pairs as needed. Each pair is treated as a single chunk.

---

### Web Pages

Ingests the text content of specific web pages. In add mode you can paste multiple URLs at once, one per line. In edit mode you adjust a single URL entry.

**Fields:**

- **URL(s)**: In add mode, paste one URL per line. In edit mode, a single URL field is shown.
- **Follow links on this page**: When enabled, the ingestor follows links found on the page and ingests those pages as well. Link crawling is limited to the same domain, one level deep, and a maximum of 100 pages per URL.

Page titles are auto-detected at crawl time and do not need to be entered manually. Duplicate URLs are deduplicated automatically.

---

### Paste Text

Allows you to paste plain text content directly into the corpus without uploading a file. Useful for content that is not in a file or web page, such as copied policy documents, meeting notes, or manually transcribed content.

Paste Text entries are write-once. To replace the content of an existing entry, delete it and add a new one.

**Fields:**

- **Title**: A display label for the document, shown in citations. Required.
- **Content**: The full text of the document, pasted into a text area. Required.
- **Source URL**: An optional URL to associate with the document, shown as a link in citations.

---

### Upload Files

Allows you to upload one or more files such as PDFs, Word documents (.docx), plain text, Markdown, CSV, source code, or other text-based formats. The ingestor extracts text from the uploaded files during the corpus build. You can select multiple files at once for bulk upload.

Upload entries are write-once. To replace an uploaded file, delete it and upload a new one.

**Fields:**

- **File(s)**: One or more files to upload. Files are transferred directly to storage using a secure presigned URL, so there is no practical file size limit.
- **Title**: An optional display label shown in citations. When uploading a single file, leave blank to use the filename. When uploading multiple files, the filename is always used as the title.

Unsupported formats (images, audio, video, archives, executables, old binary Office formats such as .doc and .xls, and fonts) are rejected immediately at selection time.

When a file-upload source appears as a citation in a chat answer, clicking the source link downloads the original file.

---

## Admin: CORPUS.md

This section is relevant only to users with admin or superadmin roles.

Each corpus has an associated CORPUS.md document. This is a plain-text description of what the corpus covers and when it should be used. It is an admin-only configuration field — regular users are never shown this content. It is primarily useful when the corpus is connected to Claude Desktop via the MCP integration, where it helps the AI decide which corpus to search for a given question.

**How do I edit CORPUS.md?**

In the corpus detail panel, click the **CORPUS.md** tab. You can type directly in the text area and click Save.

**Can the system generate CORPUS.md automatically?**

Yes. Click **Regenerate with AI** to generate a new description based on the corpus content. Review the generated text and click Save to keep it. If you leave the field blank, a description is generated automatically each time the corpus is built.

---

## Admin: Managing Users

This section is relevant only to users with admin or superadmin roles.

**Where do I manage users?**

Open the admin panel by clicking the Corpora button in the sidebar (visible to admins). Select the Users tab at the top of the admin panel.

**What roles are available?**

- **allowed**: The user can access the application and chat normally. This is the default for new users when the access mode is open.
- **denied**: The user cannot access the application. They will see an "Access required" message after signing in.
- **admin**: The user has full administrative access, including corpus management, user management, and settings.
- **superadmin**: Set at deployment time via the ADMIN\_EMAILS environment variable. Superadmins cannot be modified or deleted through the UI.

**How do I pre-authorise a user before they sign up?**

Set a role for the user's email address before they log in. Their role record will be created in advance (shown as "pre-authorized" in the user list) and applied when they first sign in.

**Can I delete a user?**

Yes. Deleting a user removes them from both the identity provider and the application's user database. Superadmins cannot be deleted. Deleted users lose access immediately.

---

## Admin: Token Tracking

This section is relevant only to users with admin or superadmin roles.

**How do I change the token tracking mode?**

In the admin panel, select the Users tab. Choose either Per User or Shared Pool, then click **Save**. The change takes effect immediately.

**What is the monthly token budget?**

The total monthly budget is set by your plan tier and cannot be changed from within the application. Contact support to upgrade your plan for a higher budget.

**How is the per-user limit calculated?**

In Per User mode, the effective limit for each user is the plan's total monthly budget divided by the configured user cap. For example, a plan with a 5-million-token budget and a 10-user cap gives each user 500,000 tokens per month. The effective limit is shown in the Users tab.

**Does the tracking mode affect the usage ring?**

Yes. In Shared Pool mode, the ring shows the shared pool's total consumption versus the plan limit. In Per User mode, the ring shows only the current user's consumption versus their individual limit. The ring updates every 30 seconds.

---

## Admin: Access Mode and Registration

This section is relevant only to users with admin or superadmin roles.

**What is access mode?**

Access mode determines what happens when a new user signs in for the first time.

- **Open (allowed)**: New users are automatically granted access. They can start chatting immediately after their first login.
- **Closed (denied)**: New users are blocked until an administrator explicitly sets their role to "allowed" or "admin". This allows you to pre-screen access.

**What is the registration toggle?**

The registration toggle controls whether the system accepts new user sign-ups at all. When registration is disabled, users without an existing account record will be rejected at sign-in even if their role has not been explicitly denied.

Access mode is available in the admin panel under the Users tab. The registration toggle is in the Identity tab.

---

## Admin: Appearance and Branding

This section is relevant only to users with admin or superadmin roles.

**Can the application be customised for my organisation?**

Yes. Administrators can configure the following in the admin panel:

- **Login Page tab — App Name**: Shown in the sidebar and on the sign-in screen.
- **Login Page tab — Tagline**: Displayed below the app name on the sign-in screen.
- **Login Page tab — Feature bullets**: Bullet points shown on the sign-in page, one per line.
- **Links tab — Navigation links**: Custom links displayed in the sidebar below the New Chat button, visible to all users. Each link has a label and a URL.

Changes to branding and links take effect immediately for new visitors.

**Can each corpus have its own display name?**

Yes. Each corpus has a **Display Title** and **Display Tagline** that are shown on the empty-state screen when that corpus is selected. Set them by selecting a corpus in the admin panel and clicking **Edit Appearance**. If the display title is left blank, the corpus name is used instead.

---

## Admin: Identity and SSO

This section is relevant only to users with admin or superadmin roles.

**What is the Identity tab?**

The Identity tab in the admin panel is where administrators configure single sign-on (SSO) login providers for the deployment. SSO options include Google OAuth and SAML / OIDC federation. Google login is available on Pro and Business plans. SAML / OIDC is available on Business plans only.

**How do I enable Google login?**

Open the admin panel, select the Identity tab, and follow the instructions to configure your Google OAuth client ID. Users will then see a "Sign in with Google" option on the login screen.

**How do I configure SAML or OIDC?**

Open the admin panel, select the Identity tab, and enter the details for your identity provider. This requires a Business plan. Contact support if you need assistance configuring enterprise SSO.

---

## Admin: Support

This section is relevant only to users with admin or superadmin roles.

**What is the Support tab?**

The Support tab in the admin panel provides contact information and links for getting help with your My Corpus deployment. The support email address shown there is also displayed on the Plan tab when users want to inquire about upgrading to a paid tier.

---

## Plan Tiers

My Corpus is offered on four plan tiers. Only the Free plan is currently available; paid plans are coming soon.

**Free — $0/month**

- Up to 5 users
- Up to 5 corpora
- Up to 20,000 chunks per corpus
- 1 million tokens per month
- Source types: GitHub, YouTube, URL, Q&A, Docs
- Google login: not included
- SAML / OIDC login: not included
- Scheduled corpus rebuilds: not included

**Basic — $19.99/month**

- Up to 10 users
- Up to 10 corpora
- Up to 30,000 chunks per corpus
- 5 million tokens per month
- Source types: GitHub, YouTube, URL, Q&A, Docs
- Google login: not included
- SAML / OIDC login: not included
- Scheduled corpus rebuilds: not included

**Pro — $49.99/month**

- Up to 25 users
- Up to 25 corpora
- Up to 50,000 chunks per corpus
- 15 million tokens per month
- Source types: GitHub, YouTube, URL, Q&A, Docs
- Google login: included
- SAML / OIDC login: not included
- Scheduled corpus rebuilds: included

**Business — $99.99/month**

- Unlimited users
- Up to 100 corpora
- Up to 100,000 chunks per corpus
- 30 million tokens per month
- Source types: GitHub, YouTube, URL, Q&A, Docs
- Google login: included
- SAML / OIDC login: included
- Scheduled corpus rebuilds: included

To inquire about a paid plan, contact support using the email address shown in the admin panel under the Plan tab.

---

## Troubleshooting

**"The knowledge base has not been built yet."**

This message appears when you send a question and the selected corpus has no completed build. An administrator needs to configure sources and click Build Corpus. Ask your administrator to build the corpus.

**"You have used your full token budget."**

Your monthly token budget for the current calendar month is exhausted. Tokens reset at the start of the next calendar month. Contact your administrator if you need an earlier reset or a plan with a higher budget.

**"You don't have access to this knowledge base."**

Your account has been denied by an administrator, or you logged in during a period when access was closed and no pre-authorisation exists for your email address. Contact your administrator to request access.

**"This knowledge base is currently at capacity."**

The deployment has reached its user limit for the current plan tier. No new users can register until an existing user is removed or the plan is upgraded. Contact your administrator.

**A query shows "Query timed out. Please try again."**

The application polls for an answer every 2 seconds for up to 2 minutes. If no answer arrives within that window, the interface gives up waiting. The backend worker may have failed silently. Try submitting the question again. If the problem persists, contact your administrator to check the backend logs.

**A query shows "Query failed. Please try again."**

The backend worker processed the query but encountered an error it could not recover from. The most common causes are a transient model or infrastructure failure. Submitting the same question again usually succeeds.

**The corpus status shows "pending changes" after I saved sources.**

This is expected. Saving source configuration marks the corpus as having pending changes. The corpus remains queryable with the previous build. Click Build Corpus to start a new build that incorporates the changes.

**The corpus status shows "error".**

The last build attempt failed. If a previous successful build exists, the corpus is still queryable using that build. Check the build log in the admin panel for details, resolve any source configuration issues, and trigger a new build.

**I uploaded a file but the corpus does not seem to include it.**

File uploads require a corpus rebuild to be included. After uploading, the corpus status will show "pending changes". Trigger a new build to incorporate the uploaded files.

**The usage ring says I have tokens remaining but queries are being rejected.**

The usage ring shows whichever limit is active for the current tracking mode — your individual allocation in Per User mode, or the shared pool total in Shared Pool mode. Queries are blocked if either the per-user limit or the overall plan total is exceeded, whichever comes first. In Shared Pool mode, another user may have exhausted the shared budget. In Per User mode, the overall plan budget may have been reached by the combined usage of all users. Contact your administrator to check current usage levels.

**Starter questions are not showing.**

Starter questions are loaded from the selected corpus's configuration. If the corpus has not been built, or if no starter questions have been configured for that corpus, the buttons will not appear. This is not an error.

**I pressed Back in my browser and lost my place.**

The application integrates with the browser history. Pressing Back restores the previous conversation or returns to the empty state. If the admin panel was open, Back will close it. The conversation history is fetched from the server on each load so no local data is lost.

**A file type was rejected when I tried to upload it.**

The Upload Files source type does not support images, audio, video, archive files, executables, fonts, or old binary Office formats (.doc, .xls, .ppt). Supported formats include PDF, .docx, plain text, Markdown, CSV, and source code files. If your file is in an unsupported format, convert it to a supported format before uploading, or use the Paste Text source type to paste the content directly.

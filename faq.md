# mycorpus Frequently Asked Questions

This document covers the most common questions about mycorpus — what it is, how it works, how data is protected, and how to get the most out of the system. It is intended for both end users and administrators.

---

## What is mycorpus?

mycorpus is a private AI assistant that answers questions using your organisation's own content. Rather than drawing on general internet knowledge, mycorpus searches a curated collection of documents, web pages, repositories, and other sources — called a corpus — and generates answers that are grounded in that specific content. Every answer includes citations showing which source material was used.

mycorpus is designed for organisations that need an AI assistant that stays within the boundaries of their own knowledge base: internal documentation, product manuals, policy documents, training materials, or any other structured content.

---

## Getting an Account

### How do I get access to mycorpus?

Access is granted by your organisation's mycorpus administrator. Depending on how the system is configured, you may be able to sign up directly on the login page, or your administrator may need to approve your account before you can log in. Contact your administrator if you are unsure.

### Can I sign up with Google or single sign-on?

If your administrator has configured Google login or enterprise SSO (SAML or OIDC), a login button for that provider will appear on the sign-in page. Click it to authenticate through your identity provider. You do not need a separate password in this case.

### Why is my account pending after I sign up?

Your administrator has enabled closed-access mode, which means new accounts must be manually approved before they can use the chat. There is no automatic notification — your administrator must check the Users tab in the admin panel to see pending accounts and approve yours from there. Contact your administrator directly if approval is taking too long.

### I forgot my password. How do I reset it?

On the login page, click **Forgot password** and enter your email address. A reset link will be sent to that address. If you log in with Google or SSO, password reset is handled by your identity provider and not by mycorpus directly.

---

## Using the Chat

### How do I ask a question?

Type your question in the message box at the bottom of the screen and press Enter or click the send button. mycorpus will search the knowledge base and return an answer with cited sources within a few seconds.

### Why does mycorpus sometimes say it does not know something?

mycorpus answers are grounded exclusively in the content loaded into the corpus. If a topic has not been included in the knowledge base, the system will acknowledge that it cannot find relevant information rather than guess. This is intentional — it prevents the system from generating plausible-sounding but incorrect answers.

### Can I ask follow-up questions?

Yes. mycorpus keeps track of your recent conversation history and uses it as context for follow-up questions. You can ask for clarification, more detail, or related information within the same conversation. If you want to start a completely fresh topic, start a new conversation from the sidebar.

### What are the starter questions on the chat screen?

Starter questions are automatically generated from the content in the knowledge base. They give you a quick sense of what topics are available and help you get started without knowing exactly what to ask. Clicking a starter question sends it as your first message.

### How do I start a new conversation?

Click **New conversation** in the left sidebar. Each conversation is independent and starts without any context from previous exchanges. You can have as many conversations as you like.

### Can I see my conversation history?

Yes. All your past conversations are listed in the left sidebar, grouped by recency (Today, Yesterday, Last 7 days, Last 30 days, Older). Click any conversation to reopen it. You can continue asking questions in any previous conversation.

### Can I delete a conversation?

Yes. Hover over the conversation in the sidebar and click the delete option. Deletion is permanent and cannot be undone.

### Can I cancel a query while it is processing?

Yes. While mycorpus is generating an answer, a **Cancel** button appears in the response area. Clicking it stops the polling and dismisses the pending response. The query may still complete on the server, but the result will not be displayed.

### How do I choose which corpus to search?

If your administrator has configured multiple corpora, a corpus picker appears above the chat input. Select the corpus you want to search before sending your question. New conversations are pinned to the selected corpus. When you reopen an existing conversation, the picker automatically switches to match that conversation's corpus.

---

## Sources and Citations

### What are the sources shown with each answer?

When mycorpus generates an answer, it retrieves the specific passages from the knowledge base that were most relevant to your question. The sources section shows where those passages came from — document names, URLs, repository paths, or other identifiers. This lets you verify the answer and read the original material.

### Can I trust the answers mycorpus gives?

mycorpus answers are grounded in your organisation's own content, so they are as reliable as that content. The system does not fabricate sources or invent information beyond what it can find in the corpus. Reviewing the cited sources is always a good way to confirm an answer, especially for important decisions.

### Why does the same question sometimes give a different answer?

AI language models have a small amount of variability in how they express answers. The underlying source retrieval is deterministic, but the way the answer is phrased may vary slightly between requests. If you are getting meaningfully different answers on the same question, it may indicate that the corpus contains conflicting information on that topic.

---

## Token Budget

### What is a token budget?

A token is the basic unit of text that the AI model processes — roughly one word. Each time mycorpus generates a response, it consumes tokens. Your plan includes a monthly token budget that covers all users on the tenant. Tokens are used to process the search results, the conversation history, and the generated answer.

### How many tokens do I have?

Your available tokens depend on your plan's monthly budget and how your administrator has configured token tracking. The system always enforces two limits simultaneously: a shared pool limit (the total monthly plan budget across all users) and a per-user limit (the plan budget divided equally among the user cap). A query is blocked if either limit is exceeded. The token tracking setting controls which of these figures is shown in the usage display — per-user mode shows your individual allocation, while shared mode shows the combined pool — but both limits are always active regardless of how the display is set. You can see your current usage and remaining budget in the interface.

### What happens when I run out of tokens?

You will see a message indicating that your monthly token budget is exhausted and when it resets. You can still browse and read your past conversations but cannot submit new questions until the budget resets on the 1st of the next calendar month.

---

## Data Protection and Privacy

### Who owns the data loaded into mycorpus?

You own your data. Each mycorpus tenant runs in a dedicated, isolated AWS account managed by mycorpus. Your corpus content, user conversations, and configuration data are contained within that account and are never co-mingled with another organisation's data. No other tenant can access your account, and mycorpus staff access is governed by standard AWS IAM controls.

### Does AWS use my data to train AI models?

No. AWS Bedrock, which mycorpus uses for AI inference, does not use data submitted through the API to train or improve foundation models. This is contractually guaranteed in AWS's service terms. Your prompts and the model's responses are processed in memory and are not stored or logged by Bedrock after the API call completes.

### Does Anthropic see my data?

No. The Claude model used by mycorpus runs inside AWS's infrastructure, not Anthropic's. When you submit a question, it goes to AWS Bedrock, which handles the inference entirely within AWS. Anthropic supplies the model weights but does not receive or have access to your runtime data.

### Is my data shared between different mycorpus deployments?

No. Each organisation gets a dedicated AWS account. There is no shared infrastructure, shared database, or shared model context between tenants. Your data physically cannot be accessed from another organisation's environment.

### Is my data encrypted?

Yes. Data at rest in S3 and DynamoDB is encrypted using AWS KMS. Data in transit between services uses TLS. For enhanced data isolation, your administrator can configure a customer-managed KMS key (CMK) per deployment. Deleting the CMK cryptographically destroys all associated data even if the underlying storage objects still exist.

### Where is my data stored geographically?

Your data is stored in the AWS region your administrator chose at deployment time. It does not leave that region except as explicitly configured. If your organisation has data residency requirements, confirm the deployment region with your administrator.

### Who can see my conversations?

Your conversations are private to your account. Other regular users cannot see your conversations. Administrators can manage user accounts but do not have a built-in admin interface to browse individual user conversations. Conversations are stored in S3 under a path keyed to your email address.

### What data does mycorpus store about me?

mycorpus stores your email address (used as your user identifier), your conversation history (questions and answers), and your token usage counters. It does not store payment information, browsing behaviour outside the application, or any data beyond what is needed to operate the chat service.

### Can my data be deleted?

Yes. An administrator can delete your user account from the admin panel. This removes your account from the authentication system and your usage record from the database. Your conversation files in S3 are associated with your email address and can be removed as part of an offboarding process. Contact your administrator to request data deletion.

---

## Corpus and Knowledge Base

### What is a corpus?

A corpus is a named, searchable collection of content. Administrators build corpora by configuring sources (web pages, documents, repositories, etc.) and triggering a build process. The build process downloads the content, splits it into searchable chunks, generates AI embeddings for each chunk, and stores the result. When you ask a question, mycorpus searches the active corpus to find relevant passages.

### How current is the information in the knowledge base?

The knowledge base reflects the content at the time of the last corpus build. If the source material has changed since then, the answers may not reflect those changes. Administrators can rebuild the corpus at any time to pick up updated content.

### Why can't mycorpus answer my question even though I know the information is in the documents?

Several things can affect retrieval quality. The document may not have been included in the most recent build, the content may be in a format the ingestor could not process, or the way the question is phrased may not closely match the relevant passage. Try rephrasing the question. If the problem persists, let your administrator know so they can check whether the relevant source is correctly configured and included in the corpus.

### Can I upload my own documents to the knowledge base?

You cannot upload documents as a regular user. Administrators can upload documents through the admin panel. If you have a document that should be added to the knowledge base, share it with your administrator.

---

## Source Types (for Administrators)

### What types of sources can be loaded into a corpus?

mycorpus supports nine source types:

**GitHub** — fetches specific files (e.g. README.md) from all public repositories belonging to a GitHub user account. Useful for indexing documentation spread across many repos.

**GitHub Corpus Repo** — downloads every supported file from a single GitHub repository (or subdirectory). Treats the repo as a document store. Supports .txt, .md, .rst, .pdf, .docx, and .url files.

**GitLab** — equivalent to the GitHub source but for GitLab users and groups.

**GitLab Corpus Repo** — equivalent to GitHub Corpus Repo but for GitLab projects.

**YouTube** — indexes video titles and descriptions from a YouTube channel's public videos. Requires a YouTube Data API v3 key.

**Web Page** — fetches and indexes content from one or more URLs. Optional link crawling follows same-domain links found on the root page (one level deep), up to 100 pages in total.

**Q&A** — lets administrators enter question-and-answer pairs directly. Ideal for FAQs, policies, and known issues.

**Paste Text** — lets administrators paste plain text content directly into the corpus. Useful for short documents, policy snippets, or any text that does not exist as a file.

**Upload Files** — upload files directly through the admin interface. Supports PDF, DOCX, and any text-based file (TXT, MD, CSV, source code, etc.). Multiple files can be uploaded in one operation.

### What is a .url file and how does it work?

A `.url` file is a special file type recognised by the GitHub Corpus Repo and GitLab Corpus Repo sources. When the ingestor encounters a file with a `.url` extension in the repository, it reads the file and triggers a web crawl on the URL it contains.

The file can contain either a plain URL on the first line, or a JSON object:

```json
{"url": "https://example.com", "crawl_links": true, "title": "Optional title"}
```

When `crawl_links` is `true`, the crawler follows same-domain links found on the root page (one level deep), fetching up to 100 pages in total. This allows you to use a GitHub or GitLab repo as a corpus configuration file that also triggers web crawls.

### How do I set up automatic corpus updates?

Use the GitHub Corpus Repo or GitLab Corpus Repo source pointing to a repository that your team maintains. When documents in the repository are updated, the next corpus build will pick them up automatically. Administrators can trigger a build at any time from the corpus detail panel. On Pro and Business plans, corpus builds can also be scheduled to run automatically on a recurring basis.

---

## Claude Connector

### What is the Claude Connector?

The Claude Connector lets you search your mycorpus knowledge bases directly from claude.ai. Instead of switching between applications, you ask Claude a question and Claude searches your corpus automatically to find relevant answers. The connection uses the Model Context Protocol (MCP), an open standard for connecting AI assistants to external data sources.

### Do I need a special plan to use the Claude Connector?

No. The Claude Connector is available to all registered users regardless of plan tier.

### How do I connect claude.ai to mycorpus?

Open your settings in mycorpus (the person icon in the sidebar) and go to the **Claude Connector** tab. Copy the MCP Server URL shown there. In claude.ai, go to **Settings → Connectors → Add custom connector**, paste the MCP Server URL into the URL field, and click **Connect**. A login window will open — sign in with your mycorpus account. Once authenticated, your knowledge bases are available as search tools in every claude.ai conversation.

### What is CORPUS.md?

CORPUS.md is a description of what a corpus covers. It tells Claude which knowledge base to use for which questions. When Claude calls `list_corpora`, it receives the CORPUS.md description for each corpus. A well-written CORPUS.md helps Claude pick the right corpus automatically.

Administrators can write CORPUS.md manually from the corpus detail panel, upload it as a file in a GitHub or GitLab source repository, or let mycorpus generate one automatically during the corpus build.

### What happens if I have multiple corpora — how does Claude know which one to search?

Claude calls `list_corpora` to see all available corpora and their CORPUS.md descriptions. Based on the content of the question and the descriptions, Claude selects the most relevant corpus to search. You can also ask Claude explicitly to search a specific corpus by name.

---

## Administrators and Roles

### What can an administrator do that a regular user cannot?

There are two distinct levels of administrative access in mycorpus.

A user promoted to the **Admin role** through the Users tab can access the admin panel to manage users (approve, deny, promote, delete) and configure identity providers (Google, SAML, OIDC). Regular users can only access the chat interface.

A **Superadmin** — an account whose email is listed in the `ADMIN_EMAILS` system configuration — has all of the above capabilities and additionally can create and configure corpora, manage branding, and trigger corpus builds. Corpus management and branding are restricted exclusively to Superadmin accounts.

### What is a Superadmin account?

Superadmin accounts are defined at deployment time by the system operator via the `ADMIN_EMAILS` configuration. They bypass all user caps and registration gates, cannot be deleted or denied through the admin interface, and always have full access regardless of plan tier. The Superadmin role is intended for the system operator and is separate from the Admin role that can be assigned through the panel.

### Can there be multiple administrators?

Yes. Any user can be promoted to Admin role through the Users tab. There can be as many admins as needed. Promoted admins can manage users and configure identity providers. Creating and configuring corpora, managing branding, and triggering builds require the Superadmin role, which is limited to the email addresses specified at deployment time.

### What is the difference between closed-access mode and disabling registrations?

These are two separate controls. Closed-access mode (the access mode setting) means new accounts are created in a denied state and must be manually approved by an admin before the user can access the chat. Disabling registrations prevents new accounts from being created at all — users who attempt to sign up will be blocked before a record is created. Existing users and admins are unaffected by either setting. The registration toggle is available in the Identity tab of the admin panel. The closed-access mode control is available in the Users tab.

### Can I pre-authorise a user before they register?

Yes. Admins can set a user's role to "allowed" or "admin" by email address before the user has registered. When that user signs up, their pre-set role is applied immediately, bypassing any approval requirement even in closed-access mode.

---

## Troubleshooting

### The chat is slow to respond. What is happening?

Response time depends on the size of the corpus (more chunks = more search time), the complexity of the question, and the speed of the AI model. Typical responses arrive in two to five seconds. If responses are consistently slow, contact your administrator — the system may need tuning.

### I am getting an error when I try to log in.

Make sure you are using the correct email address and password. If you log in with Google or SSO, make sure your browser allows the redirect. If the problem persists, try clearing your browser cache and cookies, or contact your administrator.

### The answer I received seems outdated.

The knowledge base reflects content from the last corpus build. If the source material has been updated since then, the answers will not reflect those changes. Ask your administrator to rebuild the corpus to pick up the latest content.

### I am an administrator and the corpus build failed. What should I check?

Open the build log in the corpus detail view. Failed sources are clearly marked. Common causes include expired API keys or access tokens, private repositories whose tokens have been rotated, URLs that have gone offline or returned non-200 responses, and PDF or DOCX files that are password-protected or corrupted. Fix the source configuration and trigger a new build.

After every build completes or fails, superadmin email addresses receive an automated build summary. The email lists each source, its document count, and any errors, and includes the last 1,000 log events from the build as an attachment. This makes it straightforward to diagnose failures without opening the admin panel.

### Why does the corpus build take a long time?

Build time depends on the volume of content being processed. Embedding each text chunk through the AI model takes a fraction of a second, but a corpus with tens of thousands of chunks can take an hour or more. Web crawls that follow links add time proportional to the number of pages fetched. Large PDF files are also slower to process than plain text.

### Can I run multiple corpus builds at the same time?

Each corpus has its own independent build process. You can build multiple corpora simultaneously. Within a single corpus, only one build runs at a time — triggering a new build while one is running is not recommended.

---

## Plans and Pricing

### What plan tiers are available?

mycorpus is available in four tiers: Free, Basic, Pro, and Business. The tier controls the number of users, the number of corpora, the chunk limit per corpus, the monthly token budget, which identity providers are available, and whether scheduled corpus rebuilds are supported.

### What is the difference between the plans?

The Free plan supports up to 5 users, 5 corpora, 20,000 chunks per corpus, and a 1 million token monthly budget. Google, SAML, and OIDC login are not available. Scheduled corpus rebuilds are not available. The Free plan includes a 90-day trial period, after which new queries are blocked until the plan is upgraded.

The Basic plan supports up to 10 users, 10 corpora, 30,000 chunks per corpus, and a 5 million token monthly budget. Google, SAML, and OIDC login are not available. Scheduled corpus rebuilds are not available.

The Pro plan supports up to 25 users, 25 corpora, 50,000 chunks per corpus, and a 15 million token monthly budget. Google login is available. SAML and OIDC login are not available. Scheduled corpus rebuilds are available.

The Business plan supports unlimited users, 100 corpora, 100,000 chunks per corpus, and a 30 million token monthly budget. Google, SAML, and OIDC login are all available. Scheduled corpus rebuilds are available.

The monthly token budget is the total available to all users on the tenant each calendar month. Both a shared pool limit and a per-user limit are always enforced simultaneously. The token tracking setting controls which figure is shown in the usage display.

### How do I upgrade my plan?

Contact the mycorpus team to discuss plan options. The active plan tier is stored in the system configuration and is updated as part of the account management process.

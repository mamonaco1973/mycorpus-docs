# mycorpus Documentation

This repository contains the official end-user and administrator documentation for [mycorpus](https://mycorpus.ai) — a private AI assistant grounded in your organisation's own knowledge base.

## Documents

| File | Audience | Contents |
|------|----------|----------|
| [user-guide.md](user-guide.md) | End users | Getting started, chat interface, conversations, token budget, privacy |
| [admin-guide.md](admin-guide.md) | Administrators | Source types, user management, identity providers, branding, plan tiers, data security |
| [faq.md](faq.md) | Everyone | Comprehensive Q&A covering usage, data protection, source types, plans, and troubleshooting |

## Using This Repo as a Help Corpus

This repository is designed to be loaded directly into a mycorpus corpus using the **GitHub Corpus Repo** source type. Each document is written with corpus-friendly structure — self-contained sections, dense Q&A format, and full answers within each section so chunks remain meaningful after splitting.

To add this documentation as a source in your mycorpus deployment:

1. In the admin panel, open the corpus you want to use for help content
2. Go to **Sources → Add Source → GitHub Corpus Repo**
3. Set **Repository** to `mamonaco1973/mycorpus-docs`
4. Leave **Branch** as `main` and **Path prefix** blank
5. No Personal Access Token is needed — this repo is public
6. Click **Save**, then **Build Corpus**

Once built, users can ask questions like "How do I reset my password?" or "What source types are supported?" and receive answers grounded in this documentation.

## Updating the Documentation

When documentation is updated in this repository, rebuild the corpus in the mycorpus admin panel to pick up the changes. On Pro and Business plans, scheduled corpus rebuilds can keep the help content automatically up to date.

## Contributing

If you find errors, gaps, or outdated information in these documents, please open an issue or submit a pull request.

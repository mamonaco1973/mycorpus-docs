# tools

This directory contains maintenance scripts for the mycorpus-docs repository.

## update-docs.ps1

Regenerates the product documentation (`user-guide.md`, `admin-guide.md`,
`faq.md`) from the mycorpus-runtime source code using a multi-agent loop.

### How it works

Each document is processed in three phases. Every phase runs as a separate
`claude` subprocess with no shared context, which prevents the model from
anchoring on what it previously generated.

1. **Writer** — reads the runtime source files and the existing doc, writes
   an updated version grounded in the current code.
2. **Reviewer** — reads the source files and the updated doc with no memory
   of the writer phase, then lists every factual error or omission.
3. **Fixer** — reads the source files, the updated doc, and the error list,
   then writes a corrected version.

The reviewer/fixer loop repeats up to `MaxPasses` times. If the reviewer
reports no errors it stops early.

### Source files

The script globs source files automatically — no manual updates needed when
new ingestors or frontend modules are added:

- `03-core/code/*.py` — Lambda functions (conversations, RAG, corpus, users, etc.)
- `02-ingest/ingestors/*.py` — corpus ingestor plugins
- `04-webapp/js/**/*.js` — frontend JavaScript modules
- `04-webapp/index.html` — app shell
- `03-core/cognito.tf`, `variables.tf` — admin-relevant infrastructure (admin-guide only)

### Exclusions

Features listed in `NODOC.md` (repo root) are injected into every prompt.
All three agents are instructed not to document those features even if they
appear in the source code.

### Usage

Run from any directory — paths are absolute:

```powershell
.\tools\update-docs.ps1
.\tools\update-docs.ps1 -MaxPasses 2
```

Requires Claude Code (`claude` CLI) to be installed and authenticated.
Runs under the Claude Max plan — no separate API key needed.

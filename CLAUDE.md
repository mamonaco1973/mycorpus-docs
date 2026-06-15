# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## What This Repo Is

This is the documentation repository for mycorpus-runtime. It contains the
end-user guide, administrator guide, and FAQ that are loaded into the default
corpus of every mycorpus deployment via the GitHub Corpus Repo source type.

The runtime stack lives at: https://github.com/mamonaco1973/mycorpus-runtime

## Writing Standards for Corpus Documents

These documents are designed to be ingested by a RAG system. Every edit must
preserve corpus-friendliness:

- **Self-contained sections** — each section must make sense in isolation.
  Do not write "as mentioned above" or "see the section below." A chunk that
  lands in a retrieval result should answer the question without context from
  surrounding sections.

- **Q&A format preferred** — the FAQ especially should be dense with
  question-and-answer pairs. Each question is a retrieval target; the answer
  must be complete and specific.

- **Full answers, not references** — if two sections cover related topics,
  repeat the key facts rather than cross-referencing. Redundancy is acceptable
  and desirable for chunked retrieval.

- **Plain prose** — avoid heavy markdown structure inside answers (nested
  lists, tables). Short bullet lists are fine. Long tables inside answers
  make poor chunks.

- **No relative links** — do not link to other sections within the documents.
  Links in corpus chunks are not navigable and add noise.

## What to Update When

When mycorpus-runtime adds a new feature:

1. Add a Q&A entry to `faq.md` covering the most likely user question
2. Update `admin-guide.md` if the feature requires admin configuration
3. Update `user-guide.md` if the feature is visible to end users

After pushing changes, rebuild the corpus in the admin panel (or wait for the
next scheduled rebuild on Pro/Business plans) to make the updated content
searchable.

## Comment Standards

Follow the project-level commenting standards: comment the why, not the what.
Section headers use `---` dividers. No multi-line comment blocks.

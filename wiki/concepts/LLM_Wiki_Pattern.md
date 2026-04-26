---
tags: [concept, llm_wiki, knowledge_compilation]
summary: "The LLM Wiki pattern compiles raw sources into a persistent, interconnected Markdown knowledge base."
---

# LLM Wiki Pattern

## Core Synthesis

The LLM Wiki pattern replaces repeated query-time rediscovery with durable synthesis. Instead of asking an LLM to search raw documents from scratch for every question, the LLM reads sources once, extracts stable knowledge, and integrates that knowledge into an evolving Markdown wiki.

**Who**: A human curator and an LLM agent working together.

**What**: A persistent wiki made of source summaries, concept pages, analyses, indexes, and logs.

**Where**: A local Git-tracked Cursor workspace, optionally opened as an Obsidian vault.

**When**: Used whenever knowledge accumulates over time and should compound across sessions.

**Why**: It reduces repeated summarization, preserves synthesis, exposes contradictions, and makes knowledge navigable.

**How**: The user places source documents in `raw/`; the LLM creates and maintains Markdown pages in `wiki/`; Cursor rules and commands guide ingest, query, and lint workflows.

## Provenance Tracking

* *Pattern description*: Derived from `raw/sample_llm_wiki_source.md` (2026-04-26)

## Related Notes

* [[Sample_Source]]
* [[overview]]
* [[glossary]]

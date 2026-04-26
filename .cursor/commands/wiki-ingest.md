# /wiki-ingest

Ingest the requested source into the LLM Wiki.

Steps:

1. Read `AGENTS.md`.
2. Read `manifest.md`.
3. If a source path is provided, ensure it has a manifest row.
4. Read the source from `raw/`.
5. Create or update a source page in `wiki/sources/`.
6. Create or update concept/entity pages in `wiki/concepts/`.
7. Update `wiki/index.md`, `wiki/overview.md`, `wiki/glossary.md`, and `wiki/log.md`.
8. Mark the manifest row `COMPILED`.
9. Run `python3 scripts/wiki_ingest.py --validate`.
10. Summarize what changed and list new or updated pages.

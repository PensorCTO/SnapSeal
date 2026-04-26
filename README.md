# Karpathy LLM Wiki for Cursor

This is a Cursor-native implementation of a Karpathy-style LLM Wiki.

## Quick Start

1. Add source documents to `raw/`.
2. Add a row to `manifest.md` with status `PENDING`.
3. Ask Cursor Agent: `/wiki-ingest raw/<your-source>.md`.
4. Review generated pages in `wiki/`.
5. Run validation:

```bash
python3 scripts/wiki_ingest.py --validate
```

## Querying

Ask Cursor:

```text
/wiki-query What does this wiki currently know about <topic>?
```

The agent should read `wiki/index.md` first, then inspect relevant pages.

## Maintenance

Run:

```text
/wiki-lint
```

This checks schema compliance, broken links, orphan pages, provenance gaps, and stale index entries.

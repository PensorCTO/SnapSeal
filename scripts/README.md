# Wiki Ingestion Scripts

Utilities for checking the LLM Wiki ingestion pipeline.

## Commands

```bash
python3 scripts/wiki_ingest.py --status
python3 scripts/wiki_ingest.py --check
python3 scripts/wiki_ingest.py --validate

./scripts/wiki_ingest.sh status
./scripts/wiki_ingest.sh check
./scripts/wiki_ingest.sh validate
```

## Validation

The validator checks:

- YAML frontmatter.
- `tags` and `summary`.
- Required sections.
- Broken wiki links.
- Pending manifest rows.

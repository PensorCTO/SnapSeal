# /wiki-lint

Perform a health check of the LLM Wiki.

Check:

- Schema compliance.
- Broken wiki links.
- Missing backlinks.
- Missing source provenance.
- Stale or contradictory claims.
- Manifest/wiki mismatches.
- Index coverage.
- Glossary gaps.

Run:

```bash
python3 scripts/wiki_ingest.py --status
python3 scripts/wiki_ingest.py --validate
```

Return:

- Critical issues.
- Recommended fixes.
- Pages that need review.

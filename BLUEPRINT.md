# Workspace Blueprint: Cursor Karpathy LLM Wiki

## Overview

This workspace implements a Markdown-first LLM Wiki in Cursor. It transforms raw sources into a persistent, linked knowledge graph.

## Architecture

```text
raw/ -> manifest.md -> Cursor Agent -> wiki/ -> validation -> git history
```

## Key Ideas

- Raw sources are immutable.
- The wiki is LLM-maintained.
- The schema is explicit and version-controlled.
- `wiki/index.md` is the navigation hub.
- `wiki/log.md` preserves chronological history.
- `.cursor/rules/` makes the workflow Cursor-native.

## Main Workflows

- Ingest: Compile new source material into wiki pages.
- Query: Answer from the compiled wiki.
- Lint: Maintain graph health and schema consistency.

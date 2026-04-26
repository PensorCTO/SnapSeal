#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/wiki_ingest.py"

case "${1:-status}" in
  status|--status)
    python3 "$PYTHON_SCRIPT" --status
    ;;
  check|--check)
    python3 "$PYTHON_SCRIPT" --check
    ;;
  validate|--validate)
    python3 "$PYTHON_SCRIPT" --validate
    ;;
  help|--help|-h)
    cat <<'HELP'
LLM Wiki ingestion helper

Commands:
  status      Show wiki status
  check       Fail if manifest has PENDING entries
  validate    Validate wiki schema and links
  help        Show this message
HELP
    ;;
  *)
    echo "Unknown command: $1"
    echo "Run scripts/wiki_ingest.sh help"
    exit 1
    ;;
esac

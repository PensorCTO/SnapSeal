#!/usr/bin/env python3
"""
LLM Wiki ingestion helper.

Provides simple status, pending-entry, and schema-validation checks.
"""

from pathlib import Path
import re
import sys

WORKSPACE_ROOT = Path(__file__).parent.parent
MANIFEST_FILE = WORKSPACE_ROOT / "manifest.md"
RAW_DIR = WORKSPACE_ROOT / "raw"
WIKI_DIR = WORKSPACE_ROOT / "wiki"


class WikiIngestionManager:
    def __init__(self):
        self.workspace_root = WORKSPACE_ROOT
        self.manifest_file = MANIFEST_FILE
        self.raw_dir = RAW_DIR
        self.wiki_dir = WIKI_DIR

    def audit_pending(self):
        if not self.manifest_file.exists():
            print("ERROR: manifest.md not found.")
            return []

        pending = []
        for line in self.manifest_file.read_text(encoding="utf-8").splitlines():
            if "`PENDING`" not in line:
                continue

            parts = [part.strip() for part in line.split("|")]
            if len(parts) >= 5:
                pending.append({
                    "source": parts[1],
                    "timestamp": parts[2],
                    "status": parts[3],
                    "target": parts[4],
                })

        return pending

    def wiki_files(self):
        if not self.wiki_dir.exists():
            return []
        return sorted(self.wiki_dir.rglob("*.md"))

    def validate_schema(self):
        results = []
        for wiki_file in self.wiki_files():
            content = wiki_file.read_text(encoding="utf-8")
            relative = wiki_file.relative_to(self.workspace_root)

            checks = {
                "file": str(relative),
                "has_frontmatter": content.startswith("---"),
                "has_tags": "tags:" in content,
                "has_summary": "summary:" in content,
                "has_core_synthesis": "## Core Synthesis" in content or wiki_file.name in {"index.md", "log.md", "glossary.md"},
                "has_provenance": "## Provenance Tracking" in content or wiki_file.name in {"index.md", "log.md"},
                "has_related_notes": "## Related Notes" in content or wiki_file.name in {"index.md", "log.md"},
            }
            results.append(checks)

        return results

    def broken_wiki_links(self):
        page_stems = {path.stem for path in self.wiki_files()}
        broken = []

        for wiki_file in self.wiki_files():
            content = wiki_file.read_text(encoding="utf-8")
            for match in re.findall(r"\[\[([^\]]+)\]\]", content):
                target = match.split("|", 1)[0].strip()
                if target not in page_stems:
                    broken.append((str(wiki_file.relative_to(self.workspace_root)), target))

        return broken

    def print_status(self):
        print("LLM Wiki Status")
        print("=" * 60)
        print(f"Raw files: {len(list(self.raw_dir.glob('*'))) if self.raw_dir.exists() else 0}")
        print(f"Wiki pages: {len(self.wiki_files())}")

        pending = self.audit_pending()
        print(f"Pending manifest rows: {len(pending)}")
        for entry in pending:
            print(f"  - {entry['source']} -> {entry['target']}")

        broken = self.broken_wiki_links()
        print(f"Broken wiki links: {len(broken)}")
        for source, target in broken:
            print(f"  - {source}: [[{target}]]")

    def print_validation(self):
        results = self.validate_schema()
        failed = False

        for result in results:
            checks = {k: v for k, v in result.items() if k != "file"}
            missing = [name for name, ok in checks.items() if not ok]
            if missing:
                failed = True
                print(f"[WARN] {result['file']}: missing {', '.join(missing)}")
            else:
                print(f"[OK] {result['file']}")

        broken = self.broken_wiki_links()
        if broken:
            failed = True
            for source, target in broken:
                print(f"[WARN] broken link in {source}: [[{target}]]")

        if failed:
            sys.exit(1)


def main():
    manager = WikiIngestionManager()
    command = sys.argv[1] if len(sys.argv) > 1 else "--status"

    if command in {"--status", "status"}:
        manager.print_status()
    elif command in {"--check", "check"}:
        pending = manager.audit_pending()
        if pending:
            print("PENDING entries found:")
            for entry in pending:
                print(f"  - {entry['source']}")
            sys.exit(1)
        print("No pending entries.")
    elif command in {"--validate", "validate"}:
        manager.print_validation()
    else:
        print(f"Unknown command: {command}")
        print("Use --status, --check, or --validate.")
        sys.exit(2)


if __name__ == "__main__":
    main()

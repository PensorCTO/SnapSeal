#!/usr/bin/env python3
"""Emit factlockcam_app/dart_defines.json for `flutter run --dart-define-from-file`.

Only keys required by `AppConfig` are written so secrets from `.env.local`
(e.g. SUPABASE_DB_PASSWORD) are never embedded in the compiled app.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

ALLOWED_KEYS = ("SUPABASE_URL", "SUPABASE_ANON_KEY")


def parse_env_file(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    text = path.read_text(encoding="utf-8")
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[7:].strip()
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$", line)
        if not m:
            continue
        key, val = m.group(1), m.group(2)
        if len(val) >= 2 and val[0] == val[-1] and val[0] in "\"'":
            val = val[1:-1]
        out[key] = val
    return out


def resolve_values(env_file: Path | None) -> dict[str, str]:
    file_vals: dict[str, str] = {}
    if env_file is not None and env_file.is_file():
        file_vals = parse_env_file(env_file)

    merged: dict[str, str] = {}
    for key in ALLOWED_KEYS:
        v = (file_vals.get(key) or os.environ.get(key, "")).strip()
        if v:
            merged[key] = v
    return merged


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--env-file",
        type=Path,
        default=None,
        help="Optional .env-style file (e.g. repo-root .env.local). Values override empty env.",
    )
    ap.add_argument(
        "--out",
        type=Path,
        required=True,
        help="Output JSON path (e.g. factlockcam_app/dart_defines.json).",
    )
    args = ap.parse_args()

    merged = resolve_values(args.env_file)
    missing = [k for k in ALLOWED_KEYS if k not in merged or not merged[k]]
    if missing:
        src = args.env_file if args.env_file else "environment"
        print(
            f"Missing non-empty values for: {', '.join(missing)} (checked {src} + process env).",
            file=sys.stderr,
        )
        return 1

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(
        json.dumps(merged, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env bash
# Local Supabase hard reset: diagnostics, stop without backup, remove project volumes,
# start stack, reset migrations, print status.
# Requires: Docker running, Supabase CLI (match versions — see https://supabase.com/docs/guides/cli/getting-started#updating-the-supabase-cli).
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$ROOT"

echo "=== 1. Diagnostic Verification ==="
supabase -v
if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker daemon not reachable. Start Docker Desktop (or your engine), then retry." >&2
  exit 1
fi
echo "Docker: daemon OK"

echo "=== 2. State Purge ==="
supabase stop --no-backup || true

# If containers remain attached (some CLI versions), force-stop project containers so volumes can be removed.
if docker ps -q --filter 'name=factlockcam' | grep -q .; then
  echo "Force-stopping lingering Supabase containers..."
  ids="$(docker ps -q --filter 'name=factlockcam')"
  [ -n "$ids" ] && docker stop $ids 2>/dev/null || true
  ids="$(docker ps -aq --filter 'name=factlockcam')"
  [ -n "$ids" ] && docker rm -f $ids 2>/dev/null || true
fi

echo "Removing Docker volumes for this Supabase project (factlockcam naming)..."
while read -r vol; do
  [ -z "$vol" ] && continue
  docker volume rm -f "$vol" || true
done < <(docker volume ls -q | grep -iE 'factlockcam' || true)

echo "=== 3. Environment Rebuild ==="
supabase start
supabase db reset

echo "=== 4. Validation ==="
supabase status

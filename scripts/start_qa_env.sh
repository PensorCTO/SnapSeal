#!/usr/bin/env bash
# Single-command ephemeral QA: Flutter Web (:3000) + Ngrok + iOS Simulator with WEB_VAULT_BASE_URL.
#
# Prerequisites: Flutter, Ngrok, Xcode/iOS Simulator; repo-root `.env.local` with SUPABASE_URL
# and SUPABASE_ANON_KEY (sync writes factlockcam_app/dart_defines.json).
#
# Usage: from repo root, `bash scripts/start_qa_env.sh`
# Ctrl+C tears down Web + Ngrok and removes local log files.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/factlockcam_app"
DEFINES_JSON="$APP_DIR/dart_defines.json"
WEB_LOG="$ROOT_DIR/qa_web_server.log"
NGROK_LOG="$ROOT_DIR/qa_ngrok.log"

WEB_PID=""
NGROK_PID=""

kill_children() {
  if [[ -n "$WEB_PID" ]] && kill -0 "$WEB_PID" 2>/dev/null; then
    kill "$WEB_PID" 2>/dev/null || true
  fi
  if [[ -n "$NGROK_PID" ]] && kill -0 "$NGROK_PID" 2>/dev/null; then
    kill "$NGROK_PID" 2>/dev/null || true
  fi
}

cleanup_logs() {
  rm -f "$WEB_LOG" "$NGROK_LOG"
}

on_abort() {
  echo ""
  echo "Shutting down QA environment (Flutter Web + Ngrok)..."
  kill_children
  cleanup_logs
  exit 130
}

trap on_abort SIGINT SIGTERM SIGQUIT

echo "=========================================="
echo " INITIATING FACTLOCKCAM QA ENVIRONMENT"
echo "=========================================="

if [[ ! -f "$DEFINES_JSON" ]]; then
  echo "Syncing dart_defines.json from .env.local..."
  bash "$ROOT_DIR/scripts/sync_flutter_dart_defines.sh" || {
    echo "ERROR: Could not write $DEFINES_JSON. Set SUPABASE_URL and SUPABASE_ANON_KEY in .env.local."
    exit 1
  }
fi

echo "Starting Flutter Web on port 3000 (logs: $WEB_LOG)..."
cd "$APP_DIR"
flutter run -d chrome --web-port 3000 \
  --dart-define-from-file="$DEFINES_JSON" >"$WEB_LOG" 2>&1 &
WEB_PID=$!

echo "Starting Ngrok tunnel (logs: $NGROK_LOG)..."
ngrok http 3000 >"$NGROK_LOG" 2>&1 &
NGROK_PID=$!

echo "Waiting for Ngrok HTTPS URL..."
NGROK_URL=""
for _ in $(seq 1 45); do
  NGROK_URL="$(
    curl -fsS http://127.0.0.1:4040/api/tunnels 2>/dev/null \
      | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for t in data.get('tunnels') or []:
    u = t.get('public_url') or ''
    if u.startswith('https://'):
        print(u)
        break
" || true
  )"
  if [[ -n "$NGROK_URL" ]]; then
    break
  fi
  sleep 1
done

if [[ -z "$NGROK_URL" ]]; then
  echo "ERROR: Failed to read HTTPS tunnel URL from http://127.0.0.1:4040/api/tunnels"
  echo "Check Ngrok auth and that port 4040 is free (no duplicate ngrok agent)."
  kill_children
  cleanup_logs
  exit 1
fi

echo "Web vault tunnel (WEB_VAULT_BASE_URL): $NGROK_URL"

echo "Launching iOS Simulator target with injected WEB_VAULT_BASE_URL..."
set +e
flutter run -d ios \
  --dart-define-from-file="$DEFINES_JSON" \
  --dart-define="WEB_VAULT_BASE_URL=$NGROK_URL"
IOS_EXIT=$?
set -e

echo "iOS session ended (exit $IOS_EXIT). Stopping Web + Ngrok..."
kill_children
cleanup_logs
trap - SIGINT SIGTERM SIGQUIT
exit "$IOS_EXIT"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/factlockcam_app"
ENV_FILE="${FACTLOCKCAM_ENV_FILE:-$ROOT_DIR/.env.local}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

usage() {
  cat <<'HELP'
FactLockCam Supabase development pipeline

Usage:
  scripts/factlockcam_supabase_pipeline.sh <command>

Commands:
  doctor        Show local tool versions and configured env variable presence
  login         Login to Supabase CLI, using SUPABASE_ACCESS_TOKEN when set
  link          Link local Supabase config to FACTLOCKCAM_SUPABASE_PROJECT_REF
  status        Show local Supabase service status
  start         Start local Supabase stack
  stop          Stop local Supabase stack
  reset         Reset local DB and apply migrations
  lint          Run local Supabase DB lint
  push-dry-run  Preview remote migration push
  push          Push migrations to linked remote project
  migration-list  Local vs remote migration history (loads .env.local; needs SUPABASE_DB_PASSWORD)
  config-push   Push supabase/config.toml Auth/project settings to remote
  flutter-defines  Write factlockcam_app/dart_defines.json from .env.local (filtered)
  app-run       Run Flutter app using dart_defines.json from .env.local

Environment:
  FACTLOCKCAM_ENV_FILE                 Defaults to .env.local
  FACTLOCKCAM_SUPABASE_PROJECT_REF     Remote project ref from dashboard URL
  SUPABASE_ACCESS_TOKEN             Personal access token for CLI login
  SUPABASE_DB_PASSWORD              Remote database password for link/push
  SUPABASE_URL                      Project API URL for the Flutter app
  SUPABASE_ANON_KEY                 Rotated public anon key for the Flutter app
  WEB_VAULT_BASE_URL                Optional → dart_defines: public HTTPS origin
                                    of the Flutter *web* build that serves /courier
                                    (required for QA/prod courier links — not localhost)
HELP
}

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: $name" >&2
    echo "Create .env.local from .env.example or export it in your shell." >&2
    exit 1
  fi
}

supabase_cmd() {
  (cd "$ROOT_DIR" && supabase "$@")
}

case "${1:-help}" in
  doctor)
    (cd "$ROOT_DIR" && supabase --version)
    (cd "$APP_DIR" && flutter --version | sed -n '1p')
    for name in FACTLOCKCAM_SUPABASE_PROJECT_REF SUPABASE_ACCESS_TOKEN SUPABASE_DB_PASSWORD SUPABASE_URL SUPABASE_ANON_KEY WEB_VAULT_BASE_URL; do
      if [[ -n "${!name:-}" ]]; then
        echo "$name=set"
      else
        echo "$name=missing"
      fi
    done
    ;;
  login)
    if [[ -n "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
      supabase_cmd login --token "$SUPABASE_ACCESS_TOKEN"
    else
      supabase_cmd login
    fi
    ;;
  link)
    require_env FACTLOCKCAM_SUPABASE_PROJECT_REF
    if [[ -n "${SUPABASE_DB_PASSWORD:-}" ]]; then
      supabase_cmd link --project-ref "$FACTLOCKCAM_SUPABASE_PROJECT_REF" --password "$SUPABASE_DB_PASSWORD"
    else
      supabase_cmd link --project-ref "$FACTLOCKCAM_SUPABASE_PROJECT_REF"
    fi
    ;;
  status)
    supabase_cmd status
    ;;
  start)
    supabase_cmd start
    ;;
  stop)
    supabase_cmd stop
    ;;
  reset)
    supabase_cmd db reset
    ;;
  lint)
    supabase_cmd db lint --local --fail-on warning
    ;;
  push-dry-run)
    supabase_cmd db push --dry-run
    ;;
  push)
    supabase_cmd db push
    ;;
  migration-list)
    supabase_cmd migration list
    ;;
  config-push)
    require_env FACTLOCKCAM_SUPABASE_PROJECT_REF
    supabase_cmd config push --project-ref "$FACTLOCKCAM_SUPABASE_PROJECT_REF"
    ;;
  flutter-defines)
    require_env SUPABASE_URL
    require_env SUPABASE_ANON_KEY
    python3 "$ROOT_DIR/scripts/write_flutter_dart_defines.py" \
      --env-file "$ENV_FILE" \
      --out "$APP_DIR/dart_defines.json" \
      --dart-out "$APP_DIR/lib/core/config/generated_dart_defines.dart"
    echo "Wrote $APP_DIR/dart_defines.json and lib/core/config/generated_dart_defines.dart"
    ;;
  app-run)
    require_env SUPABASE_URL
    require_env SUPABASE_ANON_KEY
    python3 "$ROOT_DIR/scripts/write_flutter_dart_defines.py" \
      --env-file "$ENV_FILE" \
      --out "$APP_DIR/dart_defines.json" \
      --dart-out "$APP_DIR/lib/core/config/generated_dart_defines.dart"
    (cd "$APP_DIR" && flutter run --dart-define-from-file dart_defines.json)
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    echo "Unknown command: ${1:-}" >&2
    usage
    exit 1
    ;;
esac

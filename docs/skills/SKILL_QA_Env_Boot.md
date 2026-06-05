# SKILL: FactLockCam QA Environment Bootstrapping

## Description

A safe, interactive operational procedure to establish the QA environment, synchronize Dart defines, and execute a physical device cold-start without logging or exposing Supabase secrets.

## Prerequisites

- Physical iOS device connected via USB.
- Xcode installed with a development team that can sign the app bundle.
- [`factlockcam_app/ios/Flutter/Signing.local.xcconfig`](../../factlockcam_app/ios/Flutter/Signing.local.xcconfig) — auto-provisioned from `Signing.local.xcconfig.example` by `run_device.sh` if missing (see [wiki/log.md](../../wiki/log.md) 2026-06-04 entry).
- Repo-root [`.env.qa.example`](../../.env.qa.example) as the template for QA defines.

## Expected QA defines

From `.env.qa.example` (non-secret defaults):

| Key | Expected value |
|-----|----------------|
| `WEB_ARCHIVE_BASE_URL` | `https://archive.factlockcam.com` (hosted archive) |
| `ENABLE_PROOF_LINKS` | `true` |
| `APP_ENVIRONMENT` | `development` |
| `USE_POLYGON_NOTARIZER` | `true` |

**Ngrok alternative:** Uncomment and set `WEB_ARCHIVE_BASE_URL` to your Ngrok HTTPS origin when testing against local Flutter Web instead of the hosted archive.

## Critical wiring

[`scripts/sync_flutter_dart_defines.sh`](../../scripts/sync_flutter_dart_defines.sh) and [`factlockcam_app/run_device.sh`](../../factlockcam_app/run_device.sh) default to `.env.local`, not `.env.qa.local`. Steps 3 and 4 **must** export:

```bash
export FACTLOCKCAM_ENV_FILE="${WORKSPACE_ROOT}/.env.qa.local"
```

This matches the VS Code **iOS (QA Tunnel)** launch config in [`.vscode/tasks.json`](../../.vscode/tasks.json).

## Step 1: Environment scaffold

Copy the QA template. Do not attempt to guess or generate API keys.

```bash
cp .env.qa.example .env.qa.local
```

If `.env.qa.local` already exists, ask the user whether to overwrite before copying.

**Agent constraint:** Do not read or echo file contents after copy.

## Step 2: Manual intervention pause

**HALT all execution.** Tell the user:

> The `.env.qa.local` file is ready. Please paste your QA Supabase keys into the file, save it, and type **Ready** to continue.

Wait for user confirmation before proceeding. Never guess keys; never `cat` the file.

## Step 3: Define synchronization

After user confirms **Ready**:

```bash
export FACTLOCKCAM_ENV_FILE="$PWD/.env.qa.local"
./scripts/sync_flutter_dart_defines.sh
```

Verify **only** the non-secret archive origin (do not `cat dart_defines.json` — it contains the anon key):

```bash
jq -r '.WEB_ARCHIVE_BASE_URL' factlockcam_app/dart_defines.json
```

- Exit code 0 from sync confirms `SUPABASE_URL` and `SUPABASE_ANON_KEY` are non-empty.
- Confirm the printed URL matches intent (`https://archive.factlockcam.com` or Ngrok origin).

## Step 4: Device launch

Cold start only — hot reload does not refresh compile-time defines.

```bash
export FACTLOCKCAM_ENV_FILE="$PWD/.env.qa.local"
./factlockcam_app/run_device.sh
```

`run_device.sh` re-syncs defines (inheriting `FACTLOCKCAM_ENV_FILE`), then runs `flutter run --dart-define-from-file=dart_defines.json`.

### Send Proof QA checklist (user manual verification)

1. Log in via OTP.
2. Archive → **Send Proof** → create courier package.
3. Confirm share link format: `{WEB_ARCHIVE_BASE_URL}/courier?pkg={uuid}`.
4. Optional: open link in Safari and verify unlock flow.

## Security guardrails

- Never `echo`, `cat`, or paste `SUPABASE_ANON_KEY` / `SUPABASE_URL` values in chat or terminal.
- Never commit `.env.qa.local`, `factlockcam_app/dart_defines.json`, or `factlockcam_app/lib/core/config/generated_dart_defines.dart` (all gitignored).
- Only verify non-secret keys in output (`WEB_ARCHIVE_BASE_URL`, `ENABLE_PROOF_LINKS`, `APP_ENVIRONMENT`).
- If sync fails with "Missing non-empty values", re-prompt the user to check `.env.qa.local` — do not attempt to fix keys.

## Wiki reconciliation

After the user confirms successful device spin-up and Send Proof QA:

1. Append a brief entry to [`wiki/log.md`](../../wiki/log.md) noting the successful `--dart-define-from-file` cold-start and QA device spin-up.
2. Run `python3 scripts/wiki_ingest.py --validate`.

---
tags: [analysis, factlockcam, ios, flutter, tooling, qa]
summary: "Physical iOS 26 device QA: build/install/manual launch, flutter run attach caveats, and audit reinstall discipline."
---

# iOS Device Development Workflow

## Core Synthesis

As of **May 2026**, FactLockCam on a **physical iPhone** (iOS 26.x) with **Flutter 3.38.4** and **Xcode 26.x** routinely **builds and installs** debug binaries. **`flutter run` may fail after launch** when attaching the Dart VM Service (`Error connecting to the service protocol`, `Connection reset by peer`, or `Connection closed before full header was received`). That terminal error is often a **debugger-bridge / toolchain** issue — **not** proof the app failed to start. Always verify the **home-screen UI** before treating attach failure as a crash.

**QA gate (verified 2026-06-05):** Send Proof device cold-start via `docs/skills/SKILL_QA_Env_Boot.md`: copy `.env.qa.example` → `.env.qa.local`, fill Supabase keys locally, then `FACTLOCKCAM_ENV_FILE=$PWD/.env.qa.local ./scripts/sync_flutter_dart_defines.sh` and `./factlockcam_app/run_device.sh`. Courier links must resolve to `{WEB_ARCHIVE_BASE_URL}/courier?pkg={uuid}` (hosted archive or Ngrok tunnel).

**QA gate (verified 2026-05-20):** After `flutter build ios --debug` + `flutter install` from the **canonical repo** (`ProofLockCleanup`), manual launch passes logon → hub → Picture/Video/Archive on iPhoneTanto when Supabase defines are synced from `.env.local`. Requires **lazy camera mount** in `VaultHomeView` (PR0, [[Polygon_Try1_Postmortem]]) so hidden panels do not initialize dual cameras at hub load.

### What succeeds vs what fails

| Step | Typical result on iPhoneTanto (iOS 26.4) |
|------|------------------------------------------|
| `flutter build ios --debug --dart-define-from-file dart_defines.json` | Success |
| `flutter install -d <device> --debug` | Success |
| Launch app from home screen | Product UI (logon or `/vault-home` hub) |
| `flutter run -d <device>` (auto attach) | Often fails **after** install at VM Service WebSocket |
| `flutter attach -d <device>` after manual launch | Preferred when hot reload is needed |

### Recommended workflow

#### Send Proof QA (preferred, 2026-06-05)

1. Scaffold QA env (keys stay local — never commit):

   ```bash
   cp .env.qa.example .env.qa.local
   # Edit .env.qa.local: SUPABASE_URL, SUPABASE_ANON_KEY
   ```

2. Sync defines and cold-start on device:

   ```bash
   export FACTLOCKCAM_ENV_FILE="$PWD/.env.qa.local"
   ./scripts/sync_flutter_dart_defines.sh
   ./factlockcam_app/run_device.sh
   ```

   Or use VS Code **iOS (QA Tunnel)** — preLaunchTask syncs from `.env.qa.local` automatically.

3. Verify Send Proof share link uses `WEB_ARCHIVE_BASE_URL` from `.env.qa.example` defaults (`https://archive.factlockcam.com`) unless tunnel QA overrides it.

See `docs/skills/SKILL_QA_Env_Boot.md` for the agent-safe interactive procedure.

#### General device install

1. Sync compile-time Supabase keys (never commit `dart_defines.json`):

   ```bash
   ./scripts/factlockcam_supabase_pipeline.sh flutter-defines
   ```

2. **Device signing:** copy `ios/Flutter/Signing.local.xcconfig.example` → `Signing.local.xcconfig` (gitignored; `run_device.sh` creates it). Uses `com.factlockcam.dev` when `com.factlockcam.app` is reserved for App Store production.

3. Build and install from the **main repo** (not a forensic worktree):

   ```bash
   cd factlockcam_app
   ./run_device.sh --release
   # or: flutter build ios --debug --dart-define-from-file dart_defines.json
   #       flutter install -d iPhoneTanto --debug
   ```

4. Open **FactLockCam** on the device from the home screen.

5. Optional debugger (second terminal):

   ```bash
   cd factlockcam_app
   flutter attach -d iPhoneTanto --debug
   ```

6. Alternative: **Xcode** → open `factlockcam_app/ios/Runner.xcworkspace` → Run on device.

### Solo tester hosted ledger reset

After a device reinstall wipes local SQLite, hosted `proof_ledger` may still list stale hashes. Trim to the current keeper capture:

```bash
./scripts/factlockcam_supabase_pipeline.sh query-file scripts/solo_tester_remote_data_reset.sql
```

Edit `v_keep_asset_hash` in that script before running if the legitimate capture changed.

### Audit / forensic discipline

If an agent or developer runs bisect QA from a **git worktree** or applies `stash@{0}` WIP locally, **`flutter install` overwrites the device binary**. After forensic sessions, **reinstall from the canonical branch** before signing off QA. See [[Polygon_Try1_Postmortem]] (2026-05-20 restoration).

### Environment stack (reference)

| Component | Typical version |
|-----------|-----------------|
| Flutter | 3.38.4 stable |
| Dart | 3.10.3 |
| Xcode | 26.1 |
| iOS device | 26.4.x |

### Do not “fix” attach errors in `main.dart`

Do not wrap `main()` in `runZonedGuarded` or add `[CRASH_DIAG]` logging when investigating VM Service errors. A clean `main()` that reaches `runApp()` is sufficient; attach failures often occur **after** the process is running.

## Provenance Tracking

* *Send Proof QA env boot*: Twenty-fifth pass 2026-06-05 — `SKILL_QA_Env_Boot`, `.env.qa.local`, `--dart-define-from-file` cold-start.
* *Workflow and attach symptoms*: May 2026 device QA on `cursor/wiki-supabase-local-reset-audit`.
* *Rollback stash*: `pre-rollback: debug session + polygon WIP 2026-05-19`.
* *Restoration QA + audit reinstall note*: 2026-05-20, [[Polygon_Try1_Postmortem]].

## Related Notes

* [[Polygon_Try1_Postmortem]]
* [[FactLockCam_Master_Blueprint]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[MASTER_CONTEXT16MAY2026]]
* [[Send_Proof_Courier_2026-05]]
* [[index]]

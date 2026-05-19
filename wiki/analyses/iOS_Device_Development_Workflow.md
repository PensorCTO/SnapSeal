---
tags: [analysis, factlockcam, ios, flutter, tooling, qa]
summary: "Physical iOS device development on iOS 26: build/install vs flutter run VM attach, and recommended QA workflow."
---

# iOS Device Development Workflow

## Core Synthesis

As of **May 2026**, FactLockCam on a **physical iPhone** (iOS 26.x) with **Flutter 3.38.4** and **Xcode 26.x** routinely **builds and installs** debug binaries, but **`flutter run` may fail after launch** when attaching the Dart VM Service (`Error connecting to the service protocol`, `Connection reset by peer`, or `Connection closed before full header was received`). That failure is a **debugger-bridge / toolchain** issue, not evidence that application code at commit `19269d2` failed to start.

**QA gate (May 2026):** Manual device launch after `flutter build ios --debug` + `flutter install` passes full product workflows when Supabase defines are synced from `.env.local`.

### What succeeds vs what fails

| Step | Typical result on iPhoneTanto (iOS 26.4) |
|------|------------------------------------------|
| `flutter build ios --debug --dart-define-from-file dart_defines.json` | Success |
| `flutter install -d <device> --debug` | Success |
| Launch app from home screen | Product UI (logon or `/vault-home` hub) |
| `flutter run -d <device>` (auto attach) | Often fails **after** install at VM Service WebSocket |
| `flutter attach -d <device>` after manual launch | Preferred when hot reload is needed |

### Recommended workflow

1. Sync compile-time Supabase keys (never commit `dart_defines.json`):

   ```bash
   ./scripts/factlockcam_supabase_pipeline.sh flutter-defines
   ```

2. Build and install without relying on attach:

   ```bash
   cd factlockcam_app
   flutter build ios --debug --dart-define-from-file dart_defines.json
   flutter install -d iPhoneTanto --debug
   ```

3. Open **FactLockCam** on the device from the home screen.

4. Optional debugger (second terminal):

   ```bash
   cd factlockcam_app
   flutter attach -d iPhoneTanto --debug
   ```

5. Alternative: **Xcode** → open `factlockcam_app/ios/Runner.xcworkspace` → Run on device (native lldb, bypasses Flutter port forwarding).

### Environment stack (reference)

| Component | Typical version |
|-----------|-----------------|
| Flutter | 3.38.4 stable |
| Dart | 3.10.3 |
| Xcode | 26.1 |
| iOS device | 26.4.x |

### Do not “fix” attach errors in `main.dart`

Per project rule **bootstrap integrity**: do not wrap `main()` in `runZonedGuarded` or add `[CRASH_DIAG]` spam when investigating VM Service errors. A clean `main()` that reaches `runApp()` is sufficient; attach failures occur **after** the process is running.

### Rollback note (May 2026)

A local debug session (crash instrumentation, partial Polygon retrofit, Podfile experiments) was **stashed** and the tree restored to last push `19269d2` (*Hub refactor*). Attach behavior was **unchanged** after restore, confirming the issue is environmental, not those uncommitted edits.

## Provenance Tracking

* *Workflow and symptoms*: Observed during May 2026 device QA on `cursor/wiki-supabase-local-reset-audit` at `19269d2`; rollback stash `pre-rollback: debug session + polygon WIP 2026-05-19`.

## Related Notes

* [[FactLockCam_Master_Blueprint]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[MASTER_CONTEXT16MAY2026]]
* [[index]]

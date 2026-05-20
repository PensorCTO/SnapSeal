---
tags: [analysis, polygon, postmortem, factlockcam, blockchain, refactor]
summary: "May 2026 Polygon retrofit Try 1 postmortem: mixed-batch rollback, bisect evidence clearing Polygon DI, device-specific blank screen, and Try 2 PR sequencing."
---

# Polygon Try 1 Postmortem

## Core Synthesis

On **2026-05-19** an uncommitted **Polygon Live Retrofit** batch (DI scaffolding for `WalletService`, `VaultBlockchainHandler`, `NotarizationMonitorService`, and an `anchor-relay` Edge Function stub) was combined with **UI shell refactors** and **crash-debug instrumentation** on branch `cursor/wiki-supabase-local-reset-audit`. The user reported the app would not start on a physical **iPhone (iOS 26.4)** — blank/black screen — after a full day of debugging the team rolled back to morning commit **`19269d2`** and preserved the WIP in **`git stash@{0}`**.

A **2026-05-20 audit** (see repo-root [`POSTMORTEM_POLYGON_TRY1.md`](../../POSTMORTEM_POLYGON_TRY1.md)) applied automated bisect on snapshot commit `c87ac99`:

- **Polygon DI alone (B1):** 33/33 tests pass — **not** a startup regression.
- **UI changes alone (B2):** `widget_test` fails (Cupertino vs Material back button after camera bisect); iOS **simulator** `flutter run` still succeeds.
- **Full WIP:** compiles and installs on physical device; user-confirmed blank screen on May 19; simulator runtime OK.

**Conclusion:** Try 1 failed primarily due to **process** (mixed concerns, misread VM attach errors, bootstrap instrumentation pollution) and a **device-specific runtime issue** likely involving the pre-existing **dual `CameraView` in `IndexedStack`** pattern plus WIP UI/camera layout changes — not the Polygon DI layer itself. Try 2 should sequence **lazy camera mount (PR0)** before any Polygon PRs, keep `USE_POLYGON_NOTARIZER=false`, and use **`app-install` + manual launch** for device QA per [[iOS_Device_Development_Workflow]].

## Symptom vs tooling

| Layer | May 19 observation | Audit 2026-05-20 |
|-------|-------------------|------------------|
| Terminal VM attach | `Connection closed before full header was received` | Parallel tooling issue; not proof of Dart crash |
| Device UI | Blank/black screen (user-confirmed) | Build/install succeed; sim runtime OK; points to native/camera/device path |
| Unit tests | Not run as gate during session | Baseline 33/33; WIP 32/33 (nav icon mismatch) |

## Salvageable from stash

- Domain interfaces and feature-flagged DI (`wallet_service.dart`, `vault_blockchain_handler.dart`, `notarization_monitor_service.dart`, updated `chain_notarizer.dart`, `injection.dart`)
- `supabase/functions/anchor-relay/index.ts` stub
- Pipeline `app-install` / `app-attach` in `factlockcam_supabase_pipeline.sh`
- `bootstrap-integrity.mdc` cursor rule (after frontmatter fix)

## Discard

- `[CRASH_DIAG]` / `runZonedGuarded` bootstrap pollution
- Camera bisect (`BISECT: Always use Scaffold`)
- Premature `polygon-live-retrofit.mdc` (references non-existent `recordImmediateProof`)

## Try 2 sequencing

1. **PR0** — Lazy-mount cameras in `VaultHomeView` (fix IndexedStack dual-init)
2. **PR1** — Polygon contracts + DI only (flag off)
3. **PR2** — `anchor-relay` Edge Function + contract test
4. **PR3** — `web3dart` wallet implementation
5. **PR4** — `VaultService.proofLockFile` integration
6. **PR5** — Realtime `NotarizationMonitorService`

See [[ProofLock_Refactor_Scope]] phase 5 for manifest alignment.

## Provenance Tracking

* *Incident and rollback*: User report + `git stash@{0}` on `cursor/wiki-supabase-local-reset-audit` (2026-05-19); wiki note in [[log]] 2026-05-19 entry.
* *Session debug analysis*: `DEEPSEEK_FAILURE.md` in stash commit `33d0fd4` (conclusions partially superseded by user-confirmed blank screen).
* *Automated bisect and device/sim QA*: Audit 2026-05-20 on commits `bc9a379` (baseline), `c87ac99` (WIP snapshot); iPhoneTanto wireless + iPhone 17 simulator.

## Related Notes

* [[ProofLock_Refactor_Scope]]
* [[iOS_Device_Development_Workflow]]
* [[FactLockCam_Master_Blueprint]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[glossary]] — `PolygonChainNotarizer`, `SimulatedChainNotarizer`
* Repo root: [`POSTMORTEM_POLYGON_TRY1.md`](../../POSTMORTEM_POLYGON_TRY1.md)

---
tags: [analysis, polygon, postmortem, factlockcam, blockchain, refactor]
summary: "May 2026 Polygon Try 1: mixed-batch rollback, bisect cleared Polygon DI, PR0 lazy-camera fix restored device QA; Try 2 starts at PR1."
---

# Polygon Try 1 Postmortem

## Core Synthesis

On **2026-05-19** an uncommitted **Polygon Live Retrofit** batch was combined with UI refactors and crash-debug instrumentation. The app failed on a physical **iPhone (iOS 26.4)** with a blank/black screen; the team rolled back to **`19269d2`** and preserved WIP in **`git stash@{0}`**.

A **2026-05-20 audit** (repo-root [`POSTMORTEM_POLYGON_TRY1.md`](../../POSTMORTEM_POLYGON_TRY1.md)) proved **Polygon DI alone does not break startup** (33/33 tests). The incident was **process** (mixed batch, misread VM attach errors) plus **device runtime** (eager dual `CameraView` init in `IndexedStack`, worsened when audit accidentally installed the WIP binary on the QA device).

**Status (2026-05-20, restored):** **PR0 complete** — `VaultHomeView._cameraPanel()` lazy-mounts each `CameraView` only when its panel is active. Main-repo **`flutter test` 33/33**; **physical iPhone QA passes** (logon → hub → capture panels). Try 2 Polygon work starts at **PR1** (contracts + DI from stash, flag off).

## Incident vs resolution

| Phase | What happened |
|-------|----------------|
| May 19 Try 1 | Mixed Polygon + UI + debug instrumentation; rollback to `19269d2`; stash WIP |
| May 20 audit | Bisect cleared Polygon DI; documented root causes; **mistakenly installed WIP on iPhoneTanto** from forensic worktree |
| May 20 restore | Rebuild/install from main repo + PR0 lazy camera; **QA integrity confirmed** |

## Bisect summary (2026-05-20)

| Variant | `flutter test` |
|---------|----------------|
| Baseline / B1 Polygon DI only / B3 Podfile / B4 main instrumentation | 33/33 pass |
| B2 UI only / Full WIP | 32/33 (`widget_test` back-button mismatch after camera bisect) |

## Try 2 sequencing (updated)

| PR | Status |
|----|--------|
| **PR0** Lazy camera mount in `VaultHomeView` | **Done** |
| **PR1** Polygon contracts + DI (`USE_POLYGON_NOTARIZER=false`) | Next |
| **PR2** `anchor-relay` Edge Function + contract test | Pending |
| **PR3** `web3dart` wallet | Pending |
| **PR4** `VaultService.proofLockFile` integration | Pending |
| **PR5** Realtime `NotarizationMonitorService` | Pending |

Salvage from stash: domain interfaces, `anchor-relay` stub, pipeline `app-install`/`app-attach`. Discard: `[CRASH_DIAG]` bootstrap pollution, camera bisect, premature `polygon-live-retrofit.mdc`.

## Provenance Tracking

* *Incident and rollback*: `git stash@{0}` (2026-05-19); [[log]] 2026-05-19.
* *Audit bisect*: `audit/polygon-try1-bisect` @ `c87ac99`; [[log]] 2026-05-20 AM entry.
* *Restoration + PR0*: `factlockcam_app/lib/ui/mobile/vault_home_view.dart` `_cameraPanel()` (2026-05-20); user QA pass; [[log]] 2026-05-20 PM entry.
* *Session debug log*: `DEEPSEEK_FAILURE.md` in stash (attach-focused conclusions superseded).

## Related Notes

* [[ProofLock_Refactor_Scope]]
* [[iOS_Device_Development_Workflow]]
* [[FactLockCam_Master_Blueprint]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[glossary]] — `Lazy camera mount`, `Hub-first vault shell`
* [`POSTMORTEM_POLYGON_TRY1.md`](../../POSTMORTEM_POLYGON_TRY1.md)

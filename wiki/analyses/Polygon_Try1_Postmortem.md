---
tags: [analysis, polygon, postmortem, factlockcam, blockchain, refactor]
summary: "May 2026 Polygon Try 1 rollback postmortem; Try 2 saga live and QA-verified — see [[Polygon_Saga_Live]]."
---

# Polygon Try 1 Postmortem

## Core Synthesis

On **2026-05-19** an uncommitted **Polygon Live Retrofit** batch was combined with UI refactors and crash-debug instrumentation. The app failed on a physical **iPhone (iOS 26.4)** with a blank/black screen; the team rolled back to **`19269d2`** and preserved WIP in **`git stash@{0}`**.

A **2026-05-20 audit** (repo-root [`POSTMORTEM_POLYGON_TRY1.md`](../../POSTMORTEM_POLYGON_TRY1.md)) proved **Polygon DI alone does not break startup** (33/33 tests). The incident was **process** (mixed batch, misread VM attach errors) plus **device runtime** (eager dual `CameraView` init in `IndexedStack`, worsened when audit accidentally installed the WIP binary on the QA device).

**Status (2026-05-21):** **Try 2 complete** — async Polygon saga live; physical iPhone QA passes (~2s proof finalization). See [[Polygon_Saga_Live]] for architecture and ops.

## Incident vs resolution

| Phase | What happened |
|-------|----------------|
| May 19 Try 1 | Mixed Polygon + UI + debug instrumentation; rollback to `19269d2`; stash WIP |
| May 20 audit | Bisect cleared Polygon DI; documented root causes; **mistakenly installed WIP on iPhoneTanto** from forensic worktree |
| May 20 restore | Rebuild/install from main repo + PR0 lazy camera; hub QA confirmed |
| May 20–21 Try 2 | PR1–PR5 landed; hosted migration + `anchor-relay` deploy; pending-sync bug fixed; **QA pass** |

## Bisect summary (2026-05-20)

| Variant | `flutter test` |
|---------|----------------|
| Baseline / B1 Polygon DI only / B3 Podfile / B4 main instrumentation | 33/33 pass |
| B2 UI only / Full WIP | 32/33 (`widget_test` back-button mismatch after camera bisect) |

## Try 2 sequencing (final)

| PR | Status |
|----|--------|
| **PR0** Lazy camera mount in `VaultHomeView` | **Done** |
| **PR1** Domain contracts + DI | **Done** |
| **PR2** `anchor-relay` Edge Function + migrations | **Done** |
| **PR3** `web3dart` / `PolygonWalletService` | **Done** |
| **PR4** `VaultService` async saga | **Done** |
| **PR5** Realtime monitor + Riverpod UI + `ProofSyncNotifier` | **Done** |

Salvage from stash informed interfaces; Try 2 avoided mixing UI shell refactors. Cursor rule: `.cursor/rules/polygon-saga-architecture.mdc`.

## Provenance Tracking

* *Incident and rollback*: `git stash@{0}` (2026-05-19); [[log]] 2026-05-19.
* *Audit bisect*: `audit/polygon-try1-bisect` @ `c87ac99`; [[log]] 2026-05-20 AM entry.
* *Restoration + PR0*: `vault_home_view.dart` `_cameraPanel()` (2026-05-20).
* *Try 2 live*: [[Polygon_Saga_Live]]; [[log]] 2026-05-21 entry.

## Related Notes

* [[Polygon_Saga_Live]]
* [[ProofLock_Refactor_Scope]]
* [[iOS_Device_Development_Workflow]]
* [[FactLockCam_Master_Blueprint]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [`POSTMORTEM_POLYGON_TRY1.md`](../../POSTMORTEM_POLYGON_TRY1.md)

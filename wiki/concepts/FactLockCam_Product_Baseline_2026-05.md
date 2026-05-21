---
tags: [concept, factlockcam, baseline, supabase, product_status]
summary: "Authoritative May 2026 baseline: verified hub/archive/capture workflow and compressed Supabase repair/backfill narrative with migration pointers."
---

# FactLockCam Product Baseline (2026-05)

## Core Synthesis

As of this baseline, the **primary product workflow is verified end-to-end** on hosted Supabase: **logon** → **vault hub** → **capture or browse** → sealed assets with remote proof when online. **Second QA pass 2026-05-20** on branch `cursor/wiki-supabase-local-reset-audit`: user-confirmed after proof-progress + certificate tx-hash fixes; `flutter test` **33/33**, Polygon saga live (capture overlay **Generating Proof…**, ~2s relay on physical iPhone), **ledger tx hash on certificate**, branded app icon ([[Polygon_Saga_Live]]). PR0 lazy camera mount remains prerequisite ([[Polygon_Try1_Postmortem]]).

### Verified workflow (happy path)

1. Authenticate via Magic Number (6-digit email OTP) when Supabase is configured with Dart defines.
2. From **`/vault-home`**, use the **four-tile hub** (Vault, Picture, Video, Account & Settings). **Picture** and **Video** open embedded `CameraView` panels (`AcquisitionMode.photo` / `video`) inside `VaultHomeView`'s `IndexedStack` — cameras **lazy-mount** only when that panel is active (PR0). **Vault** opens the unified archive omni-surface. Photo mode uses `ShutterIrisPainter`; video mode enables audio with long-press/toggle recording. **Back** on each panel returns to the hub launcher.
3. When **`USE_POLYGON_NOTARIZER=true`** (default after dart-defines sync), capture runs the **Polygon saga**: **`check_proof_status`** → device sign + **EIP-191 EVM sign** → local **AES-GCM** vault + SQLite → **`proof_ledger`** insert (`pending_notarization`) → **await `anchor-relay`** (camera overlay **Generating Proof…**) → local **`chain_tx_hash`** + `pending_sync` cleared ([[Polygon_Saga_Live]]). **Certificate draft** includes the ledger transaction hash (local SQLite or remote `proof_ledger` fetch). When the flag is **false**, the legacy synchronous **`SimulatedChainNotarizer`** path applies unchanged.
4. Browse sealed media from the **Vault** hub tile (`UnifiedArchiveViewport`: grid/chronology omni-surface with filters), not a separate `/archive` route. Rows render local thumbnails from SQLite metadata; `video/*` rows use native video-frame JPEG thumbnails where possible and retain a play-badge overlay. **Background pending-sync retries** (timer + hub/archive lifecycle hooks) and a **“Retry now”** banner attempt to clear pending rows when connectivity/auth returns. Archive item actions flow through the **Domain Interaction Contract**: `AssetActionRegistry` maps the asset `mime_type`/`mediaType` to allowed `MediaActionType`s, `UniversalAssetToolbar` renders the Cupertino action surface, and `AssetAction` delegates verify/delete to the vault service layer. Tapping a video row opens `ArchiveVideoView` via the in-memory courier-decrypt path; tapping a photo row can open `ArchivePhotoView` to decrypt, verify, and view the full-size original. Per-item local delete removes SQLite metadata plus encrypted/thumbnail files from the device but does not erase historical remote proof rows.

### Branding

- **App icon:** FactLockCam camera/lock artwork at `factlockcam_app/assets/images/FactLockCamAppIcon.png` (1024×1024 source). Regenerate platform launchers with `dart run flutter_launcher_icons` (`flutter_launcher_icons` in `pubspec.yaml`). Covers iOS `AppIcon.appiconset`, Android adaptive icons, and web PWA icons/favicon.

### Supabase / database baseline (compressed)

- **Remote drift (May 2026):** Hosted databases could diverge from repo migrations (legacy `proof_ledger` shapes, missing `simulated_chain_ledger`, missing or mismatched RPCs such as `simulate_chain_notarize` / `check_proof_status`). **Repair:** `supabase/migrations/20260509160000_repair_remote_prooflock_schema.sql` drops and recreates the canonical simulated-chain + `proof_ledger` surface and RPCs to match `20260503120000_prooflock_simulated_chain.sql`. **Destructive:** prior rows in old `proof_ledger` tables are not preserved across that repair.
- **Profiles gap:** Historic `auth.users` rows sometimes had no `public.profiles` row (trigger timing/failures), blocking `wallet_id` and ledger/RPC paths. **Repair:** `supabase/migrations/20260509200000_backfill_profiles_from_auth_users.sql` inserts missing profiles and ensures non-null `wallet_id`.
- **Flutter runtime:** `SUPABASE_URL`, `SUPABASE_ANON_KEY`, optional **`USE_POLYGON_NOTARIZER`** (sync script defaults **true**), `WEB_VAULT_BASE_URL`, `REQUIRE_HARDWARE_ATTESTATION` (latter **not wired**). See `scripts/write_flutter_dart_defines.py`.
- **Polygon saga migrations:** `20260520120000_polygon_saga_proof_ledger.sql`, `20260521000000_proof_ledger_replica_identity.sql`; Edge Function **`anchor-relay`** must be deployed on hosted projects.
- **CLI / ops:** Bare `supabase` CLI does not load repo root `.env.local`; use `scripts/factlockcam_supabase_pipeline.sh` (or source `.env.local`) for linked push and consistent env when operating against remote projects.

### Still not product-complete (pointers)

- **Live Polygon mainnet broadcast:** relay finalizes DB rows with **simulated** `chain_tx_hash` until RPC + contract + gas-station secrets are configured ([[Polygon_Saga_Live]]).
- **Hardware-backed signing:** native channel still returns **developer-simulated** device signatures; EVM wallet is software-keyed in Secure Storage.
- **Courier / verification UX:** service-layer extraction and owner-side full-size photo/video viewing exist; manifest-style RPC-only courier and outsider verification surfaces are not implemented.
- **C2PA** and full **ProofLock manifest** assurance: see [[ProofLock_Refactor_Scope]] and [[ProofLock_Architectural_Manifest]].
- Automated tests improved (retry, dashboard/archive, enclave channel, action registry/toolbar, photo-view rebuild caching, and video-thumbnail MIME extension checks) but remain **thinner than a production bar** on capture/crypto/sync edge cases.

Post-baseline reconciliation: [[Project_Audit_2026-05-11]].

## Provenance Tracking

* *Verified workflow and ops*: Confirmed against app routing and vault flow (`factlockcam_app/lib/app/router/app_router.dart`, `factlockcam_app/lib/ui/views/vault_home_view.dart`, `factlockcam_app/lib/ui/views/archive_view.dart`, `factlockcam_app/lib/ui/views/archive_item_actions.dart`, `factlockcam_app/lib/core/archive/domain/services/asset_action_registry.dart`, `factlockcam_app/lib/core/archive/presentation/widgets/universal_asset_toolbar.dart`, `factlockcam_app/lib/features/archive/presentation/providers/asset_action_provider.dart`, `factlockcam_app/lib/ui/views/archive_photo_view.dart`, `factlockcam_app/lib/ui/views/archive_video_view.dart`, `factlockcam_app/lib/ui/views/camera/camera_view.dart`, `factlockcam_app/lib/ui/views/camera/acquisition_mode.dart`, `factlockcam_app/lib/core/ui/painters/shutter_button_painter.dart`, `factlockcam_app/lib/domain/services/vault_service.dart`) (2026-05-09; seal + sync paths re-audited 2026-05-11, [[Project_Audit_2026-05-11]]; hub/archive split, per-item delete, full-size photo view, video thumbnails, and custom shutter painter added 2026-05-11; Domain Interaction Contract, cached photo-view extraction, REC-state failure reset, and MIME-aware video thumbnail regeneration refreshed 2026-05-12)
* *Database repairs*: Derived from `supabase/migrations/20260509160000_repair_remote_prooflock_schema.sql`, `supabase/migrations/20260509200000_backfill_profiles_from_auth_users.sql`, and `scripts/factlockcam_supabase_pipeline.sh` (2026-05-09)
* *Branding + QA*: App icon via `flutter_launcher_icons`; QA passes 2026-05-20 including proof-progress UX + certificate tx hash (2026-05-20)

## Related Notes

* [[FactLockCam_Master_Blueprint]]
* [[Polygon_Saga_Live]]
* [[Polygon_Try1_Postmortem]]
* [[ProofLock_Refactor_Scope]]
* [[ProofLock_Architectural_Manifest]]
* [[overview]]
* [[Project_Audit_2026-05-11]]

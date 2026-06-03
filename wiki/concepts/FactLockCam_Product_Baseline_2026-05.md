---
tags: [concept, factlockcam, baseline, supabase, product_status]
summary: "Authoritative May 2026 baseline: verified hub/archive/capture workflow and compressed Supabase repair/backfill narrative with migration pointers."
---

# FactLockCam Product Baseline (2026-05)

## Core Synthesis

As of this baseline, the **primary product workflow is verified end-to-end** on hosted Supabase: **logon** → **archive hub** → **capture or browse** → sealed assets with remote proof when online.

- **Seventeenth structural pass 2026-06-02**: **Dual-layer Archive quota & credit metering** — byte layer (`archive_quotas`, `QuotaTelemetryWidget`, mock paywall) + credit layer (`subscription_cycles`, `quotaStateProvider`, camera gas gauge, Egress Pass badge, Verification Credit modal); migrations pushed hosted; device QA pass; `flutter test` **72/72** ([[Archive_Quota_Telemetry_2026-06]]).
- **Sixteenth QA pass 2026-05-30**: **Archive owner UX** — Download Media (decrypt + share sheet), Send Proof password-only with certificate title/description from asset metadata, **View/Play media** labels, chronology **⋯** action sheet; debug `enableProofLinks` when archive URL set; **55/55** tests ([[Archive_Owner_UX_2026-05]]).
- **Fifteenth QA pass 2026-05-30**: **App Store hardening** — Secure Enclave / Keystore device signing, `ENABLE_PROOF_LINKS` compile-time gate, `MissingPluginException` terminal in sync classifier, DB-first `deleteArchiveItem`, DI cleanup, `run_device.sh`; user-confirmed device login + seal path; `flutter test` **55/55** ([[App_Store_Hardening_2026-05]]).
- **Fourteenth QA pass 2026-05-29**: **Decoupled public web** — Astro sales pitch at **`factlockcam.com`**; **`archive.factlockcam.com`** Flutter bundle is **courier-only** (`WebArchiveGateView` + `/courier`); browser capture disabled; Cloudflare Pages deploy scripts; Send Proof recipient links verified in QA; `flutter test` **52/52** ([[Web_Deployment_Architecture_2026-05]]).
- **Thirteenth QA pass 2026-05-29**: **Sovereign multi-key lifecycle** — `.factlock` export/import, brick/restore gate, burn hardening, compliance URL routing; **52/52** tests ([[Sovereign_Key_Lifecycle_2026-05]]).
- **Eleventh QA pass 2026-05-24**: **UI polish** — shared `factlockcam_logoheader.jpg` on hub/logon/archive; Account & Settings heavy-metal backdrop + `HeavyMetalHubTile` legal/support rows; chronology scroll opacity dimming removed; `unified_archive_viewport_test.dart`; `flutter test` **41/41** ([[UI_Polish_Hub_Archive_2026-05]]).
- **Tenth QA pass 2026-05-24**: **App Store remediation** — `WEB_ARCHIVE_BASE_URL` rename (default `https://archive.factlockcam.com`), deleted `professional_nav_bar.dart`, `TransactionalArchivePersister`, forensic camera permission string, migration **`20260524150000_optimize_courier_archive.sql`** pushed hosted; defines re-synced; TestFlight-first (domains/trademark deferred); `flutter test` **40/40** ([[App_Store_Remediation_2026-05]]).
- **Ninth QA pass 2026-05-24**: **Production transition** — `APP_ENVIRONMENT=production`, courier lookup migrations + trigger; iOS privacy manifest + export compliance; test isolation; `flutter test` **40/40** ([[Production_Transition_2026-05]]).
- **Eighth QA pass 2026-05-22**: **Live Polygon mainnet on physical iPhone** — `ALCHEMY_API_URL` + `RELAYER_PRIVATE_KEY` on hosted Supabase, real `notarize()` broadcast + Polygonscan-confirmed tx, sim-hash fallback **removed**, relay errors propagate to callers ([[Polygon_Mainnet_Wiring_2026-05]]).
- **Seventh QA pass 2026-05-22**: **Polygon mainnet wiring** — `prooflock_production` relay pattern, initial pending-sync fix, `PolygonChainNotarizer` + `transactionHash` contract, RPC receipt polling, web `journal_repository` stub/io split, `proof_ledger` indexing migration ([[Polygon_Mainnet_Wiring_2026-05]]).
- **Sixth QA pass 2026-05-21**: **Identity lifecycle** — `wallet_history`, `proof_ledger.evm_address`, cascade `perform_full_burn`, local SQLite v6 wallet lineage, `ProofCourierService` JIT upload + iOS background scope, historical archive placeholders + restore banner ([[Identity_Lifecycle_And_Data_Lineage]]).
- **Fifth QA pass 2026-05-21**: App Store prep — bundled ToS/Privacy, support URL, GPS telemetry HUD, multi-shot capture (buffered bytes + seal queue), archive delete/view/thumbnail fixes, proof bundle zip share ([[App_Store_Prep_Capture_Seal_2026-05]]).
- **Fourth QA pass 2026-05-21**: Sprint 4 **isolate lock coordinator** + securing overlays on archive tiles; sidecar advisory locks on staging promote (not payload truncate); `PrivacyInfo.xcprivacy` + App Store checklist doc ([[Isolate_Lock_Coordinator]]).
- **Third QA pass 2026-05-21**: Sprint 2 **transactional journal** + SQLite single-flight fix; physical iPhone capture + **Polygon `proof_ledger` insert** verified; hub shell fixes (lazy archive/account panels, unique Cupertino nav `heroTag`, 2×2 hub grid + scroll in landscape).
- **Second QA pass 2026-05-20**: proof-progress + certificate tx-hash fixes; `flutter test` **33/33** core suite (expanded to **40/40** by ninth QA); Polygon saga live (overlay **Generating Proof…**, ~2s relay), **ledger tx hash on certificate**, branded app icon ([[Polygon_Saga_Live]]).
- PR0 lazy camera mount remains prerequisite ([[Polygon_Try1_Postmortem]]). Journal details: [[Archive_Transactional_Journal]].

### Verified workflow (happy path)

1. Authenticate via Magic Number (6-digit email OTP) when Supabase is configured with Dart defines.
2. From **`/vault-home`**, use the **four-tile hub** (Archive, Picture, Video, Account & Settings). **Picture** and **Video** open embedded `CameraView` panels (`AcquisitionMode.photo` / `video`) inside `VaultHomeView`'s `IndexedStack` — cameras **lazy-mount** only when that panel is active (PR0). Photo mode uses `ShutterIrisPainter`, **`ImageFormatGroup.jpeg`**, live GPS/UTC HUD, and **stays on the viewfinder** after each shot (background seal badge). **Archive** opens the unified archive omni-surface. Video mode enables audio with long-press/toggle recording. **Back** on each panel returns to the hub launcher.
3. When **`USE_POLYGON_NOTARIZER=true`** (default after dart-defines sync), capture runs the **Polygon saga**: **`check_proof_status`** → device sign + **EIP-191 EVM sign** → local **AES-GCM** vault + SQLite → **`proof_ledger`** insert (`pending_notarization`) → **await `anchor-relay`** (camera overlay **Generating Proof…**) → local **`chain_tx_hash`** + `pending_sync` cleared ([[Polygon_Saga_Live]]). On successful seal, **`pro_proof`** credit is debited optimistically (`quotaStateProvider`) with RPC reconcile ([[Archive_Quota_Telemetry_2026-06]]). **Certificate draft** includes the ledger transaction hash (local SQLite or remote `proof_ledger` fetch). When the flag is **false**, the legacy synchronous **`SimulatedChainNotarizer`** path applies unchanged.
4. Browse sealed media from the **Archive** hub tile (`UnifiedArchiveViewport`: grid/chronology omni-surface with filters), not a separate `/archive` route. **Egress Pass** badge shows verification credit balance; **QuotaTelemetryWidget** shows byte storage/egress bars ([[Archive_Quota_Telemetry_2026-06]]). Default **chronology** view: tap card → asset inspector; **⋯** (top-left) or grid tap → action sheet. Chronology scroll keeps scale/fan transforms without opacity dimming ([[UI_Polish_Hub_Archive_2026-05]]). **SECURING FILE…** overlay during writes ([[Isolate_Lock_Coordinator]]). **View/Play media** decrypts via `extractForCourier` (inspector or action sheet). **Download Media** and **verify/export** actions consume a **Verification Credit** after pre-flight modal ([[Archive_Quota_Telemetry_2026-06]]). **Send Proof** (password-only dialog; certificate uses saved title/description) builds PDF + courier URL → share sheet; recipient unlocks at **`{WEB_ARCHIVE_BASE_URL}/courier?pkg=…`** ([[Send_Proof_Courier_2026-05]], [[Web_Deployment_Architecture_2026-05]]). **DELETE FROM DEVICE** removes local SQLite + files (remote ledger may remain).

### Branding

- **App icon:** FactLockCam camera/lock artwork at `factlockcam_app/assets/images/FactLockCamAppIcon.png` (1024×1024 source). Regenerate platform launchers with `dart run flutter_launcher_icons` (`flutter_launcher_icons` in `pubspec.yaml`). Covers iOS `AppIcon.appiconset`, Android adaptive icons, and web PWA icons/favicon.

### Supabase / database baseline (compressed)

- **Remote drift (May 2026):** Hosted databases could diverge from repo migrations (legacy `proof_ledger` shapes, missing `simulated_chain_ledger`, missing or mismatched RPCs such as `simulate_chain_notarize` / `check_proof_status`). **Repair:** `supabase/migrations/20260509160000_repair_remote_prooflock_schema.sql` drops and recreates the canonical simulated-chain + `proof_ledger` surface and RPCs to match `20260503120000_prooflock_simulated_chain.sql`. **Destructive:** prior rows in old `proof_ledger` tables are not preserved across that repair.
- **Profiles gap:** Historic `auth.users` rows sometimes had no `public.profiles` row (trigger timing/failures), blocking `wallet_id` and ledger/RPC paths. **Repair:** `supabase/migrations/20260509200000_backfill_profiles_from_auth_users.sql` inserts missing profiles and ensures non-null `wallet_id`.
- **Flutter runtime:** `SUPABASE_URL`, `SUPABASE_ANON_KEY`, optional **`USE_POLYGON_NOTARIZER`** (sync script defaults **true**), **`POLYGON_RPC_URL`** (receipt polling; debug-only generated fallback), **`WEB_ARCHIVE_BASE_URL`** (production default: `https://archive.factlockcam.com`; Ngrok for TestFlight), **`ENABLE_PROOF_LINKS`** (release/profile **false** until archive verified; **debug** enables Send Proof when archive URL is set — [[Archive_Owner_UX_2026-05]]), **`APP_ENVIRONMENT`**, **`SUPPORT_URL`**, **`REQUIRE_HARDWARE_ATTESTATION`**. Device QA: `./run_device.sh` or sync + `flutter run --dart-define-from-file=dart_defines.json`. See `scripts/write_flutter_dart_defines.py` and `scripts/sync_flutter_dart_defines.sh`.
- **Courier lookup migrations:** **`20260524130000_optimize_courier_lookups.sql`**, **`20260524140000_courier_lookup_trigger.sql`**, **`20260524150000_optimize_courier_archive.sql`** (archive indices pushed hosted tenth QA).
- **Archive quota migrations:** **`20260602120000_archive_quotas_and_tiers.sql`** (byte layer), **`20260602140000_subscription_cycles_metering.sql`** (credit layer) — tier catalog, per-user quotas, subscription cycles, metered ledger, strict RLS; pushed hosted seventeenth pass ([[Archive_Quota_Telemetry_2026-06]]).
- **Polygon saga migrations:** `20260520120000_polygon_saga_proof_ledger.sql`, `20260521000000_proof_ledger_replica_identity.sql`, **`20260521120000_identity_lifecycle.sql`**, **`20260523000000_polygon_tx_indexing.sql`**; Edge Function **`anchor-relay`** deployed with `--no-verify-jwt` on hosted projects (JWT validated in-function).
- **Live Polygon mainnet (eighth QA):** Hosted secrets `ALCHEMY_API_URL` + `RELAYER_PRIVATE_KEY` configured; relay broadcasts to contract `0x83508c78104b8b58ff844EE5654FaaC06cFFc155` — no sim-hash fallback ([[Polygon_Mainnet_Wiring_2026-05]]).
- **CLI / ops:** Bare `supabase` CLI does not load repo root `.env.local`; use `scripts/factlockcam_supabase_pipeline.sh` (or source `.env.local`) for linked push and consistent env when operating against remote projects.

### Still not product-complete (pointers)

- **Archive quota wiring:** Byte + credit UI and schema landed; production billing (StoreKit/Stripe), `VaultSyncCoordinator` storage increment, and byte-layer capture/Send Proof interceptors remain follow-ups ([[Archive_Quota_Telemetry_2026-06]]).
- **Relayer wallet ops:** Active payer is a funded hot wallet (`RELAYER_PRIVATE_KEY` in Supabase secrets); rotate or fund as needed — not the user's profile EVM address ([[Polygon_Mainnet_Wiring_2026-05]]).
- **Hardware-backed signing:** **Device** `signHash` uses Secure Enclave / Keystore (fifteenth QA); EVM wallet remains software-keyed in Secure Storage. Server-side P-256 verify of `device_signature` is follow-up.
- **Courier / Send Proof:** Certificate PDF + courier package + share sheet wired; recipient unlock on **`archive.factlockcam.com/courier`** (Flutter courier-only deploy). Bind custom domain in Cloudflare Pages before App Store review ([[Web_Deployment_Architecture_2026-05]], [[Send_Proof_Courier_2026-05]]).
- Automated tests: **72/72** passing under production notarizer defaults (includes archive quota + credit metering tests); still thinner than a production bar on some crypto/sync edge cases.
- **C2PA** and full **ProofLock manifest** assurance: see [[ProofLock_Refactor_Scope]] and [[ProofLock_Architectural_Manifest]].

Post-baseline reconciliation: [[Project_Audit_2026-05-11]].

## Provenance Tracking

* *Verified workflow and ops*: Confirmed against app routing and vault flow (`factlockcam_app/lib/app/router/app_router.dart`, `factlockcam_app/lib/ui/views/vault_home_view.dart`, `factlockcam_app/lib/ui/views/archive_view.dart`, `factlockcam_app/lib/ui/views/archive_item_actions.dart`, `factlockcam_app/lib/core/archive/domain/services/asset_action_registry.dart`, `factlockcam_app/lib/core/archive/presentation/widgets/universal_asset_toolbar.dart`, `factlockcam_app/lib/features/archive/presentation/providers/asset_action_provider.dart`, `factlockcam_app/lib/ui/views/archive_photo_view.dart`, `factlockcam_app/lib/ui/views/archive_video_view.dart`, `factlockcam_app/lib/ui/views/camera/camera_view.dart`, `factlockcam_app/lib/ui/views/camera/acquisition_mode.dart`, `factlockcam_app/lib/core/ui/painters/shutter_button_painter.dart`, `factlockcam_app/lib/domain/services/vault_service.dart`) (2026-05-09; seal + sync paths re-audited 2026-05-11, [[Project_Audit_2026-05-11]]; hub/archive split, per-item delete, full-size photo view, video thumbnails, and custom shutter painter added 2026-05-11; Domain Interaction Contract, cached photo-view extraction, REC-state failure reset, and MIME-aware video thumbnail regeneration refreshed 2026-05-12)
* *Database repairs*: Derived from `supabase/migrations/20260509160000_repair_remote_prooflock_schema.sql`, `supabase/migrations/20260509200000_backfill_profiles_from_auth_users.sql`, and `scripts/factlockcam_supabase_pipeline.sh` (2026-05-09)
* *Branding + QA*: App icon via `flutter_launcher_icons`; QA passes 2026-05-20 including proof-progress UX + certificate tx hash (2026-05-20)

## Related Notes

* [[Archive_Quota_Telemetry_2026-06]]
* [[Production_Transition_2026-05]]
* [[Send_Proof_Courier_2026-05]]
* [[App_Store_Prep_Capture_Seal_2026-05]]
* [[Identity_Lifecycle_And_Data_Lineage]]
* [[FactLockCam_Master_Blueprint]]
* [[Archive_Transactional_Journal]]
* [[Isolate_Lock_Coordinator]]
* [[Polygon_Mainnet_Wiring_2026-05]]
* [[Polygon_Saga_Live]]
* [[Polygon_Try1_Postmortem]]
* [[ProofLock_Refactor_Scope]]
* [[ProofLock_Architectural_Manifest]]
* [[overview]]
* [[Project_Audit_2026-05-11]]

---
tags: [concept, factlockcam, baseline, supabase, product_status]
summary: "Authoritative May 2026 baseline: verified hub/archive/capture workflow, Certificate Studio pivot (2026-06-08), and compressed Supabase repair/backfill narrative."
---

# FactLockCam Product Baseline (2026-05)

## Core Synthesis

As of this baseline, the **primary product workflow is verified end-to-end** on hosted Supabase: **logon** → **archive hub** → **capture or browse** → sealed assets with remote proof when online.

**Submission readiness (2026-06-12):** **Unified Archive Studio** + final HUD/Quota/Pricing polish. Secure Comm hub entry **unmounted**, Send Proof + web courier unlock **decommissioned** (backend retained). Primary owner workflow: capture (now in 3:4 framed cover-cropped viewport with interactive `ProofQuotaHudChip`) → browse → **Certificate Studio**. Thirtieth pass resolved elongated camera frames and switched paywall presentation to proof/seal counts (Intro $0.99/25, Weekly $4.99, Annual $49.99/500). Restore Purchases + Delete Account labels added for App Store guidelines. **User QA passed** on device (stale-binary issue resolved via explicit rebuild + install).

- **Twenty-ninth QA pass 2026-06-08**: **Unified Archive Studio stable** — four-tile hub; hub backdrop auto-play on return + end-of-video click/haptic; `CertificateStudioView`; toolbar View / Download / Print Certificate / Delete; `enableProofLinks=false` default; web `/courier` redirects to gate; **98/98** tests ([[Unified_Archive_Studio_2026-06]]).
- **Thirtieth / final pre-submission pass 2026-06-12**: Camera HUD & framing polish + proof-centric subscription presentation + compliance labels. Interactive `ProofQuotaHudChip` (tappable, warning pulse) in Picture/Video tabs; live preview + `RepaintBoundary` + centered 3:4 `AspectRatio` framed window with cover-crop (no elongation); paywall now shows Intro Week / Weekly / Annual proof plans; Account panel has Restore Purchases + Delete Account; `SubscriptionBillingGateway.restorePurchases()` scaffolding; **100 passed + 4 skips** tests ([[Camera_HUD_Quota_Pricing_Polish_2026-06]]). Device binary required explicit `flutter build ios --debug --dart-define-from-file` + `flutter install` (see [[iOS_Device_Development_Workflow]]).
- **Twenty-ninth structural pass 2026-06-08**: **Unified Archive Studio** — same scope as QA pass (structural + QA consolidated in one release).
- **Twenty-eighth QA pass 2026-06-06**: **Secure Comm capture stable** — superseded by decommission (module unmounted, source retained) ([[Zero_Click_Capture_2026-06]]).
- **Twenty-seventh QA pass 2026-06-05**: **Application stable** — user **QA passed** on Send Proof → web courier E2E (phased console, hosted schema repair, Pages deploy); **101/101** tests at that pass ([[Secure_Communications_Console_2026-06]]).
- **Twenty-sixth structural pass 2026-06-05**: **Secure Communications Console** — web courier unlock phased UI (hash cascade animation, deferred decrypt, Proof Panel + `get_public_proof_attestation`, viral loop CTA); `docs/skills/SKILL_Secure_Comm_Console.md`; **101/101** tests ([[Web_Deployment_Architecture_2026-05]], [[Secure_Communications_Console_2026-06]]).
- **Twenty-fifth QA pass 2026-06-05**: **QA env boot + Send Proof device cold-start** — `.env.qa.local` + `FACTLOCKCAM_ENV_FILE`; VS Code / `run_device.sh` `--dart-define-from-file`; user **QA passed** on physical iPhone Send Proof ([[iOS_Device_Development_Workflow]], `docs/skills/SKILL_QA_Env_Boot.md`).
- **Twenty-fourth QA pass 2026-06-05**: **Zero-trust compliance alignment** — user **QA passed** on hosted report/block + async moderation scan ([[UGC_Safety_Reporting_2026-06]]); migration `20260605120000` + `courier-content-scan` pushed/deployed (`jqvnwtslmoxjwzusmtxs`); Archive service-layer rename with shims ([[Zero_Trust_RLS_Audit_2026-06]], [[Provisional_Patent_Technical_Exhibit_2026-06]]); **96/96** tests.
- **Twenty-third structural pass 2026-06-04**: **Device QA pass** — `Signing.local.xcconfig` → `com.factlockcam.dev`; solo tester hosted ledger reset; payload pipeline foundation; **94/94** tests ([[Institution_Grade_Payload_Seal_Backlog]], [[iOS_Device_Development_Workflow]]).
- **Foundation pass 2026-06-04**: **Payload pipeline foundation** — `courier_packages.content_mime_type` / `content_category`, Dart `ArchiveContentCategory` + `ENABLE_ARBITRARY_FILE_SEAL=false`; consumer workflow **unchanged** (Picture/Video only); institution-grade arbitrary file import deferred ([[Institution_Grade_Payload_Seal_Backlog]]).
- **Twenty-second structural pass 2026-06-03**: **App Store audit remediation** — removed dead legal PDF links + site deploy; Podfile `platform :ios, '15.0'`; Info.plist tab fix; `audit_submission_readiness.sh`; **90/90** tests; `ENABLE_PROOF_LINKS=false` preserved.
- **Twenty-first structural pass 2026-06-03**: **UI layout polish** — responsive hub (`HapticHubPanel`), archive omni (`UnifiedArchiveViewport`), inspector, account settings; device QA passed; **90/90** tests ([[UI_Layout_Polish_2026-06]]).
- **Twentieth structural pass 2026-06-03**: **Key custody scenario matrix** — keys-only `.factlock` backup; Lock vs uninstall vs Burn; hosted Terms/Privacy/Support deployed; in-app `disclaimers.dart` + Account/Burn/Restore/onboarding UX; user **QA passed**; **82/82** tests ([[Data_Custody_And_Backup_Model_2026]]).
- **Nineteenth structural pass 2026-06-03**: **Archive subscription foundation** — local SQLite quota pre-flight (`LocalArchiveQuotaGate`), free-tier 50 MB video stop, subscription onboarding + paywall disclaimer, compliant tier display names ([[Archive_Subscription_Tiers_2026]]).
- **Eighteenth structural pass 2026-06-03**: **Compliance refactor** — `/archive` hub route, `disclaimers.dart`, UI `ArchiveHomeView` / `lib/ui/mobile/archive/`, marketing ban test, Account key-custody dialog UX; **74/74** tests ([[Compliance_Refactor_2026-06]]).
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
2. From **`/archive`** (legacy **`/vault-home`** redirects), land on the **hub launcher** (`HapticHubPanel`): **Archive**, **Picture**, **Video**, **Account & Settings** (four tiles). Heavy Metal backdrop video **auto-plays** on hub mount (including return from sub-panels); end-of-loop emits subtle system click + light haptic ([[Unified_Archive_Studio_2026-06]]). Picture/Video open **lazy-mounted** `CameraView` (PR0) with back to hub. Photo mode uses `ShutterIrisPainter`, **`ImageFormatGroup.jpeg`**, live GPS/UTC HUD, and **stays on the viewfinder** after each shot (background seal badge). Video mode enables audio with long-press/toggle recording. **Archive** opens `UnifiedArchiveViewport` omni-surface with back to hub. Child panels mount only while selected (`_panelWhenSelected`).
3. When **`USE_POLYGON_NOTARIZER=true`** (default after dart-defines sync), capture runs the **Polygon saga**: **`check_proof_status`** → device sign + **EIP-191 EVM sign** → local **AES-GCM** archive + SQLite → **`proof_ledger`** insert (`pending_notarization`) → **await `anchor-relay`** (camera overlay **Generating Proof…**) → local **`chain_tx_hash`** + `pending_sync` cleared ([[Polygon_Saga_Live]]). On successful seal, **`pro_proof`** credit is debited optimistically (`quotaStateProvider`) with RPC reconcile ([[Archive_Quota_Telemetry_2026-06]]). Camera viewport is a centered 3:4 framed window with cover-cropped live preview (thirtieth pass) and an interactive `ProofQuotaHudChip` top-right showing remaining proofs and pulsing near zero. **Certificate draft** includes the ledger transaction hash (local SQLite or remote `proof_ledger` fetch). When the flag is **false**, the legacy synchronous **`SimulatedChainNotarizer`** path applies unchanged.
4. Browse sealed media from the **Archive** hub tile (`UnifiedArchiveViewport`: grid/chronology omni-surface with filters), not a separate `/archive` route. **Egress Pass** badge shows verification credit balance; **QuotaTelemetryWidget** shows byte storage/egress bars ([[Archive_Quota_Telemetry_2026-06]]). Default **chronology** view: tap card → asset inspector; **⋯** (top-left) or grid tap → action sheet. Chronology scroll keeps scale/fan transforms without opacity dimming ([[UI_Polish_Hub_Archive_2026-05]]). **SECURING FILE…** overlay during writes ([[Isolate_Lock_Coordinator]]). **View/Play media** decrypts via `extractForCourier` (inspector or action sheet). **Download Media** consumes a **Verification Credit** after pre-flight modal ([[Archive_Quota_Telemetry_2026-06]]). **Print Certificate** opens **`CertificateStudioView`**: edit local title/description (SQLite only), live PDF preview (Polygon hash, timestamp, thumbnail), print or share PDF — **no courier link**. **DELETE FROM DEVICE** removes local SQLite + files (remote ledger may remain).

### Web archive capability matrix (2026-06-08)

| Capability | Status |
|------------|--------|
| Archive subdomain gate (`WebArchiveGateView`) | **Active** — native-app + Certificate Studio positioning |
| Courier unlock (`/courier`) | **Decommissioned** — redirects to gate; source retained |
| Phased Secure Communications Console UI | **Decommissioned** from routing (orphaned source) |
| Browser capture / mobile web hub | **Disabled** (unchanged) |

### Mobile Secure Comm capability matrix (2026-06-08)

| Capability | Status |
|------------|--------|
| Secure Comm hub tile | **Unmounted** — source retained, not routed |
| Zero-Click capture (`SecureCommCaptureView`) | **Orphaned** — not reachable from hub |
| Send Proof / courier origination | **Decommissioned** — use Certificate Studio |

### Certificate Studio capability matrix (2026-06-08)

| Capability | Status |
|------------|--------|
| Local title/description edit (SQLite only) | **Active** — `assetMetadataProvider` |
| Live PDF preview (`CertificateStudioView`) | **Active** — `printing` + `CertificateExportService` |
| Print / Share PDF | **Active** — utility export, no in-app messaging |
| Polygon tx hash + thumbnail in PDF | **Active** — read-only ledger fetch |

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

- **Archive quota wiring:** Local pre-flight + camera/Send Proof interceptors landed nineteenth pass ([[Archive_Subscription_Tiers_2026]]); production billing (StoreKit), `VaultSyncCoordinator` storage increment RPC remain follow-ups ([[Archive_Quota_Telemetry_2026-06]]).
- **Relayer wallet ops:** Active payer is a funded hot wallet (`RELAYER_PRIVATE_KEY` in Supabase secrets); rotate or fund as needed — not the user's profile EVM address ([[Polygon_Mainnet_Wiring_2026-05]]).
- **Hardware-backed signing:** **Device** `signHash` uses Secure Enclave / Keystore (fifteenth QA); EVM wallet remains software-keyed in Secure Storage. Server-side P-256 verify of `device_signature` is follow-up.
- **Courier / Send Proof:** **Decommissioned (2026-06-08)** — app no longer originates packages or unlocks `/courier`. Supabase courier tables/RPCs remain for data retention. Owner workflow: **Certificate Studio** print/share PDF locally.
- Automated tests: **98/98** passing under production notarizer defaults (courier/Secure Comm widget suites skipped or short-circuited); still thinner than a production bar on some crypto/sync edge cases.
- **C2PA** and full **ProofLock manifest** assurance: see [[ProofLock_Refactor_Scope]] and [[ProofLock_Architectural_Manifest]].

Post-baseline reconciliation: [[Project_Audit_2026-05-11]].

## Provenance Tracking

* *Page intent*: Updated 2026-06-08 — twenty-ninth pass QA passed; Unified Archive Studio; Secure Comm unmounted; courier decommissioned.
* *Database repairs*: Derived from `supabase/migrations/20260509160000_repair_remote_prooflock_schema.sql`, `supabase/migrations/20260509200000_backfill_profiles_from_auth_users.sql`, and `scripts/factlockcam_supabase_pipeline.sh` (2026-05-09)
* *Branding + QA*: App icon via `flutter_launcher_icons`; QA passes 2026-05-20 including proof-progress UX + certificate tx hash (2026-05-20)

## Related Notes

* [[Unified_Archive_Studio_2026-06]]
* [[Zero_Click_Capture_2026-06]]
* [[Secure_Communications_Console_2026-06]]
* [[Institution_Grade_Payload_Seal_Backlog]]
* [[UI_Layout_Polish_2026-06]]
* [[Compliance_Refactor_2026-06]]
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

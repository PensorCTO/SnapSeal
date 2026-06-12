---
tags: [maintenance, log, llm_wiki]
summary: "Append-only chronology of wiki maintenance and major documentation events."
---

# Wiki log

## 2026-06-12

- **Thirtieth / final pre-submission pass — Camera HUD, interactive quota chip, proof pricing & framing QA fixes** — **user QA passed on device**:
  - **Interactive HUD**: New `ProofQuotaHudChip` (reads `quotaStateProvider` credit layer). Renders `PROOFS REMAINING: n/base` in monospaced forensic style with `verifiedNeon` border. Pulses (amber) + shows "UPGRADE" when `<=1` remaining; tap opens subscription paywall. Own `RepaintBoundary`; animation gated to warning state only.
  - **Camera framing & performance**: Picture/Video viewports now use a centered `AspectRatio(3/4)` framed window (no more elongated full-bleed strip). Live `CameraPreview` wrapped in `FittedBox(BoxFit.cover)` for undistorted cover-crop of the sensor feed + `RepaintBoundary` so heavy AES-GCM sealing does not drop viewfinder frames. Overlays and shutter iris already bounded.
  - **Subscription presentation (QA fix #1)**: Paywall (`SubscriptionUpgradeView`) restructured to proof/seal language per user feedback — **Intro Week** $0.99 first week (25 seals, INTRO badge), **Weekly** $4.99 (ongoing access), **Annual** $49.99 (500 proofs/year, BEST VALUE). Block reasons and cards updated; `archiveSubscriptionTierDisclaimer` refined to "additional sealing proofs only, with zero data recovery" (compliance test phrases preserved). Old GB tier names (Core Pro / Sovereign Archivist) superseded in the consumer modal while byte-enforcement substrate remains.
  - **App Store compliance (Guideline 3.1.1 / 5.1.1)**: `SubscriptionBillingGateway` extended with `restorePurchases()`; notifier gained `restore()`. Account panel now shows prominent **Restore Purchases** button + **Delete Account** label for the existing typed-`OBLITERATE` burn flow (token and `BurnAccountView` unchanged).
  - **Shell preserved**: Hub-first `IndexedStack` + `HapticHubPanel` + lazy camera mount (per `factlockcam-hub-refactor.mdc` and PR0 rule) — no `ProfessionalNavBar` or bottom tabs reintroduced.
  - **Device QA gotcha**: After code changes, simple app relaunch showed stale binary (edits invisible). Resolved by `flutter build ios --debug --dart-define-from-file=dart_defines.json` + `flutter install` to `iPhoneTanto` (followed [[iOS_Device_Development_Workflow]]).
  - **Tests**: **100 passed + 4 intentional skips** (decommissioned courier/Secure Comm suites). Forensic viewfinder tests migrated `PROOFS` assertions to the new chip (including tap-to-paywall); layout tests updated for new button labels. `flutter analyze` clean.
  - **Wiki**: New [[Camera_HUD_Quota_Pricing_Polish_2026-06]]; index "Start here" and Analyses (active) updated; baseline + overview + glossary + subscription tiers concept reconciled; `python3 scripts/wiki_ingest.py --validate`.
  - New file: `factlockcam_app/lib/features/archive_quota/presentation/widgets/proof_quota_hud_chip.dart`.
- **Wiki maintenance & git push**: All session changes (camera framing, HUD chip, subscription UI, gateway restore, disclaimers, tests, account panel) + wiki updates committed and pushed per user request after QA sign-off.

## 2026-06-08

- **Twenty-ninth pass QA — Unified Archive Studio stable** — **user QA passed**:
  - **E2E:** Four-tile hub → capture/browse → **Print Certificate** → Certificate Studio (metadata + live PDF) → print/share PDF; hub backdrop **auto-plays** on return from sub-panels; end-of-video **click + light haptic**.
  - **Hub backdrop fix:** `_panelWhenSelected` remount → `onBackdropReady()` + `playBackdropFromStart()`; `signalBackdropEnd()` in `HeavyMetalBackdropMixin`.
  - **Wiki:** [[Unified_Archive_Studio_2026-06]]; baseline + overview + index reconciled.
  - **Tests:** **98/98** `flutter test`.
  - Validation: `python3 scripts/wiki_ingest.py --validate`.
- **Unified Archive Studio & Secure Comm decommission** — product pivot to local certificate workflow:
  - **Hub:** Restored canonical **four-tile** launcher (Archive, Picture, Video, Account & Settings); Secure Comm tile **unmounted** (source retained, not routed).
  - **Actions:** Removed Send Proof / courier dispatch from `UniversalAssetToolbar`, inspector, and active Riverpod UI paths; retained View, Download Media, Delete, **Print Certificate**.
  - **Certificate Studio:** New `CertificateStudioView` — local title/description edit (SQLite only via `assetMetadataProvider`), debounced live `PdfPreview` (`printing` package), Print + Share PDF.
  - **Courier decommission:** `enableProofLinks` defaults false; web `/courier` redirects to gate; `WebArchiveGateView` copy updated; marketing site `/courier` redirects to guide. Supabase courier RPCs **unchanged** (backend retained).
  - **Metadata:** No SQLite migration — `title`/`description` columns already present (schema v3+).
  - **Wiki:** [[FactLockCam_Product_Baseline_2026-05]] reconciled; hub refactor cursor rule updated.
  - **Tests:** Courier/Secure Comm widget tests `@Skip`; hub/action/inspector tests updated.

## 2026-06-06

- **Twenty-eighth pass QA — Zero-Click Secure Comm capture stable** — **user QA passed**:
  - **E2E:** Hub → Secure Comm → record (lens flip) → stop → **Anchoring to Archive…** → Access Control → **TRANSMIT PROOF** → share sheet.
  - **Isolate fix:** seal byte read uses top-level `readAsBytesSync` inside `Isolate.run` (async `readAsBytes` futures are illegal isolate return values).
  - **UX hardening:** camera released before seal; framed 9:16 viewport; consumption/quota panel; keyboard gated until `canTransmit`.
  - **Wiki:** [[Zero_Click_Capture_2026-06]]; baseline + overview reconciled.
  - **Tests:** **115/115** `flutter test`.
  - Validation: `python3 scripts/wiki_ingest.py --validate`.
- **Zero-Click Capture Architecture** — Secure Comm refactor (structural):
  - Replaced legacy two-step `CourierDispatchView` asset picker with `SecureCommCaptureView` (capture-first flow).
  - `SecureCommCameraPool` pre-warms front camera on `HapticHubPanel` idle; releases when Picture/Video mount.
  - Hot lens swap during recording via `CameraController.setDescription()` + blur/crossfade + light haptic.
  - Post-capture: looping preview + `ArchiveAccessControlPanel` (Recipient Key, Link Lifespan, Exposure Limit) → `maxDownloads` / `linkTtlDays` RPC params.
  - Seal path: `sealAndStoreCapture` with **Anchoring to Archive…** UI; transmit via `sendProofProvider` + SharePlus.
  - Dispatch Primitive Tasks 1–3: UGC schema repair migration, dispatch package params, hub shell restored (see entries below same date).
  - Skill: `docs/skills/SKILL_Zero_Click_Capture_Architecture.md`.

## 2026-06-05

- **Hub landing + Secure Comm entry** (post–Task 3 UX correction):
  - Restored `HapticHubPanel` as post-login landing (index 0); removed `DispatchPrimitiveNavBar` from production shell.
  - Added fifth hub tile **Secure Comm** → `CourierDispatchView` with two-step flow (select asset → configure/password/transmit).
  - Picture/Video/Archive/Account return to hub via `ArchivePanelNavigationBar` / `onBackToHub`.
  - Tests: `hub_secure_comm_nav_test.dart`; updated dashboard/widget/hub layout tests; **110+** `flutter test`.
- **Task 3 — Mobile Dispatch Console** (Dispatch Primitive Framework):
  - Replaced `CourierDispatchPlaceholder` with production `CourierDispatchView` on DISPATCH CONSOLE tab.
  - New: `dispatch_console_state.dart`, `dispatch_console_provider.dart`, `dispatch_error_copy.dart`, `courier_dispatch_view.dart`.
  - `SendProofRequest` + `createCourierPackage` + `get_or_create_courier_package` accept optional `maxDownloads` / `linkTtlDays` (presets 1|3|5 downloads, 1|7|30 day link window).
  - Migration **`20260606140000_dispatch_package_params.sql`** pushed hosted.
  - TRANSMIT PROOF uses full `sendProofProvider` path (certificate PDF + courier URL + share sheet); quota gate via `ensureArchiveQuotaForSendProof`.
  - **Audit follow-up:** stall was hung `flutter analyze` (env), not code; TRANSMIT now disabled until asset + password set; `scripts/task3_dispatch_params_verify.sql` confirms hosted RPC params.
  - Tests: `courier_dispatch_view_test.dart` (6 cases); updated `dispatch_primitive_nav_test.dart`; **110/110** `flutter test`; scoped `flutter analyze` clean.
- **Task 2 — Tri-State Navigation Shell** (Dispatch Primitive Framework):
  - Replaced four-tile `HapticHubPanel` launcher with persistent `DispatchPrimitiveNavBar`: **CAPTURE**, **ARCHIVE**, **DISPATCH CONSOLE**.
  - New widgets: `capture_root_panel.dart`, `archive_tab_shell.dart` (gear → Account), `courier_dispatch_placeholder.dart`, `dispatch_primitive_nav_bar.dart`.
  - PR0 lazy tab + camera mount preserved via `_panelWhenSelected` in `archive_home_view.dart`.
  - `UnifiedArchiveViewport.onCaptureRequested` now uses `AcquisitionMode`; empty-state tiles switch to CAPTURE tab.
  - Tests: `dispatch_primitive_nav_test.dart`; updated `archive_dashboard_view_test.dart`, `widget_test.dart`; **104/104** `flutter test`.
  - Rule: `.cursor/rules/factlockcam-hub-refactor.mdc` superseded for Dispatch Primitive nav.
- **Task 1 — Dispatch Primitive UGC schema verification** (Dispatch Primitive Framework):
  - **Skill:** `docs/skills/SKILL_Dispatch_Primitive.md` — Tasks 1–5 decoupled toolkits; cross-links Compliance + Secure Comm Console skills.
  - **Hosted drift detected:** migration `20260605120000` recorded in history but `courier_content_reports`, `courier_sender_blocks`, `courier_moderation_queue`, and report/block RPCs were absent on linked project.
  - **Repair pushed:** `20260606120000_repair_ugc_reporting_schema.sql` — idempotent re-apply of UGC tables + RPCs; `report_courier_package` now flags at **≥3** reports (no Postgres storage purge — Edge Function lifecycle per plan).
  - **Verification:** `scripts/task1_ugc_schema_verify.sql`, `scripts/task1_rpc_probe.sh` — anon attestation returns only safe fields; report RPC never leaks `owner_id`.
  - **Purge policy:** quarantine via `moderation_status` + `courier-content-scan`; human-reviewed blob delete deferred to future Edge Function.
  - **Tests:** **101/101** `flutter test`; `python3 scripts/wiki_ingest.py --validate`.
- **Twenty-seventh pass QA — application stable** — **user QA passed**:
  - **E2E:** iPhone Send Proof → recipient unlock on `{WEB_ARCHIVE_BASE_URL}/courier?pkg=…` through full console phases (gate → cascade → decrypt → media + Proof Panel → viral CTA).
  - **Hosted repair:** `20260605210000_repair_send_proof_schema.sql` restored metering RPCs and 7-param `get_or_create_courier_package` after accidental `my_schema` drift; `get_public_proof_attestation` live.
  - **Deploy:** Archive web on `main.factlockcam-archive.pages.dev`; custom domain DNS deferred.
  - **Tests:** **101/101** `flutter test`; `flutter analyze` clean on web courier paths.
  - **Wiki:** [[Secure_Communications_Console_2026-06]]; baseline + overview reconciled.
  - Validation: `python3 scripts/wiki_ingest.py --validate`.
- **Twenty-sixth structural pass — Secure Communications Console (web courier)**:
  - **Web target:** Unauthenticated `/courier?pkg=…` refactored from utility downloader into phased **Secure Communications Console** — Gate → 1.5s hash cascade → deferred browser decrypt → media + Proof Panel → viral loop CTA overlay.
  - **State machine:** `CourierUnlockPhase` (`idle`, `processing`, `cascadeAnimation`, `playbackReady`, `viralLoop`); encrypted blob downloaded immediately after RPC; `CourierCrypto` runs only after cascade completes.
  - **Backend:** `get_public_proof_attestation` anon-safe RPC (`20260605140000`); `courier-unlock` forwards `content_mime_type`.
  - **Skill:** `docs/skills/SKILL_Secure_Comm_Console.md`.
  - **Tests:** **101/101** `flutter test` (`courier_unlock_console_test.dart`, `courier_unlock_notifier_test.dart`).
  - Validation: `python3 scripts/wiki_ingest.py --validate`.
- **Twenty-fifth pass — QA env boot + Send Proof device cold-start** — **user QA passed**:
  - **Env split:** `.env.qa.example` → gitignored `.env.qa.local`; `FACTLOCKCAM_ENV_FILE` selects QA vs production `.env.local` in sync + VS Code **iOS (QA Tunnel)** preLaunchTask.
  - **Launch path:** All VS Code configs + `run_device.sh` use `--dart-define-from-file=dart_defines.json`; cold start required after define changes.
  - **Skill:** `docs/skills/SKILL_QA_Env_Boot.md` — interactive boot without exposing Supabase secrets to agent context.
  - **Device QA:** Archive → Send Proof on physical iPhone; courier links `{WEB_ARCHIVE_BASE_URL}/courier?pkg={uuid}` verified against hosted archive.
  - Validation: `python3 scripts/wiki_ingest.py --validate`.
- **Twenty-fourth pass — Zero-Trust & App Store Compliance Alignment**:
  - **UGC safety (Guideline 1.2):** `features/ugc_safety/` module; `CourierUnlockView` report/block affordances; `UniversalAssetToolbar` owner report via `additionalActions`; migration `20260605120000_ugc_safety_infrastructure.sql`; Edge Function `courier-content-scan` (async metadata scan off capture hot path).
  - **Archive lexicon (PR3–PR6):** `ArchiveService`, `ArchiveDatabase`, `LocalArchiveStorage`, `ArchiveSyncCoordinator`, `ArchiveBlockchainHandler`, `SupabaseArchiveService`, `ArchiveEncryptionHandler`; deprecated `Vault*` typedef shims retained; `ArchiveCourier.tsx` on marketing site.
  - **Patent exhibit:** [[Provisional_Patent_Technical_Exhibit_2026-06]] + `docs/patent/` export.
  - **RLS audit:** [[Zero_Trust_RLS_Audit_2026-06]].
  - **Skill:** `docs/skills/SKILL_Compliance_Architecture.md`.
  - **Tests:** **96/96** `flutter test` (includes `courier_unlock_reporting_test.dart`).
  - **Deferred PR9:** `factlock_vault` bucket, SQL `vault_key`, Secure Storage `factlockcam:vault_key`, on-disk `factlockcam_vault.db` filename.
  - Validation: `python3 scripts/wiki_ingest.py --validate`.
- **Hosted deploy (2026-06-05)** — `scripts/factlockcam_supabase_pipeline.sh push` applied **`20260605120000_ugc_safety_infrastructure.sql`** to project `jqvnwtslmoxjwzusmtxs` (fix: `attempt_courier_unlock` drop/recreate with `content_mime_type` + `increment_archive_egress` parity). Edge Function **`courier-content-scan`** deployed (`--no-verify-jwt`). Validation: `python3 scripts/wiki_ingest.py --validate`.
- **Twenty-fourth pass QA (2026-06-05)** — **user QA passed** on hosted UGC safety: courier report/block on `CourierUnlockView`, owner **Report shared proof** action sheet, async `courier-content-scan` after Send Proof upload; **96/96** `flutter test`. Wiki: [[UGC_Safety_Reporting_2026-06]].

## 2026-06-04

- **Twenty-third pass — Device QA + hosted ledger reset** — **user QA passed**:
  - **iOS:** `Signing.local.xcconfig` (gitignored) → `com.factlockcam.dev` for team **G8968T57MB**; App Store ID `com.factlockcam.app` unchanged for production archives.
  - **Hosted reset:** `scripts/solo_tester_remote_data_reset.sql` — solo tester `proof_ledger` trimmed to keeper hash `a283f677…` (2026-06-04 capture); `courier_packages`, metered credits, and `archive_quotas` zeroed for that user.
  - **Tooling:** `run_device.sh` auto-provisions signing local file; pipeline `query-file` command.
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

- **Payload pipeline foundation** (no consumer UX change):
  - **Product:** Picture + Video capture only; arbitrary file sealing **deferred** to institution-grade app ([[Institution_Grade_Payload_Seal_Backlog]]).
  - **Supabase:** `20260604120000_courier_payload_metadata_foundation.sql` (`content_mime_type`, `content_category`, RPC extensions); `20260604130000_courier_bucket_octet_stream_only.sql`.
  - **Flutter:** `ArchiveContentCategory`, `mime_extension_map.dart`, `ArchiveIngressPort` / `FileArchiveIngress` stub, `ENABLE_ARBITRARY_FILE_SEAL=false`; Send Proof passes image/video metadata to `get_or_create_courier_package`.
  - **Tests:** `archive_content_category_test.dart`; **94/94** `flutter test` (was 90/90).
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

## 2026-06-03

- **Twenty-second pass — App Store Audit Remediation** — **P1/P2 closed (2026-06-03)**:
  - **P1:** Removed dead `/legal/*.pdf` links from `privacy.astro` and `terms.astro`; deployed FactLockCam marketing site (Cloudflare Pages `factlockcam`); Podfile `platform :ios, '15.0'`; `flutter analyze` clean; **90/90** `flutter test`.
  - **P2:** Info.plist tab normalization (L48–55); `factlockcam_app/tools/audit_submission_readiness.sh` (privacy manifest, export compliance, production URL hygiene, analyze + test).
  - **Skill:** `factlockcam_app/tools/SKILL_Audit_Remediation.md`.
  - **Constraint:** `ENABLE_PROOF_LINKS=false` submission default preserved (`generated_dart_defines.dart`).
  - **Wiki:** [[FactLockCam_Product_Baseline_2026-05]] → **100% Pre-Connect Submission Ready**.
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

- **Twenty-first pass — UI Layout Polish** (presentation-only) — **user QA passed (2026-06-03)**:
  - **Wiki:** [[UI_Layout_Polish_2026-06]]; skill `docs/skills/SKILL_FORENSIC_UI_REFINEMENT.md`.
  - **Hub / archive / inspector:** Responsive `LayoutBuilder` stacks; dense headers when height &lt; 520; chronology `chronologyLayoutMetrics()`; Archive-only user copy (`archive_presentation_copy.dart`).
  - **Account:** `AccountSettingsPanel` — unified scroll (legal + actions); fixes landscape `RenderFlex` overflow (~119px) on iPhone.
  - **Tests:** **90/90** `flutter test`; layout tests for hub, omni, inspector, account; `presentation_archive_copy_test`.
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

- **Twentieth pass — Key custody scenario matrix** (legal + wiki) — **user QA passed**:
  - **Model:** Keys-only `.factlock` backup; losing keys = total loss; Lock (keys purged, local `.seal` remain) vs uninstall (reimport keys for cloud) vs Burn (account + cloud destroyed, prior `.factlock` useless).
  - **Wiki:** [[Data_Custody_And_Backup_Model_2026]] — canonical scenario table, Lock vs Burn, re-export cadence, implementation anchors.
  - **App:** `disclaimers.dart` (`keyBackupOnlyDisclaimer`, `keyCustodyScenarioSummary`, `lockArchiveDisclaimer`, `archiveOnboardingParagraphs`); `LegalDisclosureColumn`; `account_settings_panel` package imports + `service_providers` exports; `app_config` → `generated_dart_defines.stub.dart`; `vault_service_web` quota params for analyzer parity.
  - **Hosted:** Terms §6–9 (keys-only, scenario table, Burn irreversible), Privacy §7, Support FAQs — deployed via `scripts/deploy_factlockcam_site_cf.sh` (Cloudflare Pages `factlockcam`).
  - **Edge:** `supabase/functions/deno.json`; `anchor-relay` fee-data null guard.
  - **Tests:** **82/82** `flutter test`; `flutter analyze` clean.
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

- **Legal QA — backup/custody copy correction** (merged into twentieth pass):
  - Removed “back up encrypted assets”; distinguished `.seal`, `.factlock`, blind `factlock_vault` ciphertext.

- **Nineteenth pass — Three-Tiered Archive Subscription Foundation**:
  - **Raw:** `raw/compliant_subscription_architecture.md` ingested → [[Compliant_Subscription_Architecture_Source]].
  - **Skill:** `docs/skills/SKILL_IMPLEMENT_ARCHIVE_SUBSCRIPTIONS.md`.
  - **Supabase:** `20260603120000_archive_tiers_compliant_labels.sql` — compliant display names, `max_single_capture_bytes`, `get_my_archive_quota` JSON.
  - **Flutter:** `LocalArchiveQuotaGate`, `VaultDatabase.sumLocalByteLength()`, camera/send-proof/seal pre-flight, free-tier video 50 MB heuristic stop, `ArchiveSubscriptionOnboardingSheet`, subscription disclaimer on paywall.
  - **Tests:** **80/80** `flutter test`.
  - **Wiki:** [[Archive_Subscription_Tiers_2026]]; refreshed index, overview, glossary.
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

- **Eighteenth pass — compliance refactor (A + B + C)** — user-confirmed device QA after Account panel fix:
  - **Copy:** `disclaimers.dart` — epistemic integrity, sovereign key custody, Polygon no-SLA; certificate PDF footer; logon, restore, capture HUD, inspector, burn scoped to account.
  - **Routing:** Canonical **`/archive`** (`ArchiveHomeView`); legacy **`/vault-home`**, **`/vault-dashboard`**, **`/camera`** redirect.
  - **UI:** `lib/ui/mobile/archive/` panel tree; `ArchivePanelNavigationBar`; Account **Key custody & limits** dialog tile; hub tiles without footnote clutter.
  - **Marketing:** `marketing.ts` + `approved_pitch.dart`; `marketing_compliance_test.dart`.
  - **Tests:** **74/74**.
  - **Wiki:** [[Compliance_Refactor_2026-06]]; refreshed baseline, index, glossary, overview.
  - **Open task:** Hosted **factlockcam.com** ToS/Privacy HTML (glossary + overview).
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

## 2026-06-02

- **Seventeenth pass — dual-layer Archive quota & credit metering** — user-confirmed device QA:
  - **Byte layer:** Migration `20260602120000_archive_quotas_and_tiers.sql` — `archive_tiers`, `archive_quotas`, RPCs, courier egress hook.
  - **Credit layer:** Migration `20260602140000_subscription_cycles_metering.sql` — `subscription_cycles`, `metered_consumption_ledger`, `get_current_quota_status`, `record_metered_consumption`; pushed hosted (**23/23** migrations); fixed `(user_id, cycle_start)` unique index (rejected `now()` partial predicate).
  - **Flutter:** `features/archive_quota/` — byte (`ArchiveQuotaService`, `QuotaTelemetryWidget`) + credit (`quotaStateProvider`, `MeteringQuotaService`, `EgressPassBadge`, camera gas gauge, Verification Credit pre-flight).
  - **Rules:** `.cursor/rules/SKILL_Archive_Quota_Telemetry.mdc`, `.cursor/rules/factlockcam-metering-ui.mdc`.
  - **Tests:** `archive_quota_*`, `metering_quota_service_test`, forensic gas-gauge test; full suite **72/72**.
  - **Wiki:** [[Archive_Quota_Telemetry_2026-06]] refined; refreshed [[FactLockCam_Product_Baseline_2026-05]], [[index]], [[overview]], [[glossary]].
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

## 2026-05-30

- **Sixteenth QA pass — archive owner UX** — user-confirmed on device:
  - **Download Media:** Decrypt + share-sheet export (`archive_media_download_io.dart`, `archive_media_extension.dart`); primary action-sheet row; inspector tile; chronology **⋯** opens sheet (default view had hidden long-press-only path).
  - **Send Proof:** Password-only dialog; certificate title/description from `ArchiveItem` metadata; fresh row from dashboard before PDF.
  - **Labels:** **View/Play media** for photo and video in toolbar + inspector.
  - **Config:** `AppConfig.enableProofLinks` — debug enables Send Proof when `WEB_ARCHIVE_BASE_URL` set even if `ENABLE_PROOF_LINKS=false` in defines; release/profile unchanged.
  - **Tests:** **55/55**.
  - **Wiki:** [[Archive_Owner_UX_2026-05]]; refreshed [[Send_Proof_Courier_2026-05]], [[App_Store_Hardening_2026-05]], [[index]], [[overview]], [[glossary]], [[FactLockCam_Product_Baseline_2026-05]].

- **Fifteenth QA pass — App Store hardening (architectural manifest)** — user-confirmed on physical iPhone:
  - **Config:** `ENABLE_PROOF_LINKS` dart-define + `AppConfig.enableProofLinks` (default false for submission); `POLYGON_RPC_URL` generated fallback debug-only; `.cursor/rules/factlock-remediation.mdc`; `run_device.sh` (sync + `--dart-define-from-file`).
  - **Auth pitfall fixed:** Empty `generated_dart_defines.dart` stub broke plain `flutter run` login — requires `sync_flutter_dart_defines.sh` or `run_device.sh` + cold restart.
  - **Sync/delete:** `MissingPluginException` terminal in `_isRecoverableRemoteFailure`; `deleteArchiveItem` DB-before-files; `reloadVaultKey` validates restored key.
  - **DI:** `KeyCustodyService`, `IsolateLockCoordinator`, `JournalRepository` injected into `VaultService`; UI `getIt` leaves bridged via `service_providers.dart`.
  - **Native:** iOS `EnclaveSigner.swift` (Secure Enclave P-256); Android `DeviceEnclaveSigner.kt` (Keystore/StrongBox); `SIMULATED_DEV` removed; `REQUIRE_HARDWARE_ATTESTATION` wired in Dart.
  - **Tests:** **55/55**; `MockVideoPlayerPlatform` in `test/helpers/mock_platform_interfaces.dart`.
  - **Wiki:** [[App_Store_Hardening_2026-05]]; refreshed [[index]], [[overview]], [[glossary]], [[FactLockCam_Product_Baseline_2026-05]], [[ProofLock_Refactor_Scope]].

## 2026-05-29

- **Decoupled public web + fourteenth QA pass**:
  - **Marketing:** Astro master sales pitch at `factlockcam.com` (`FactLockCam_Site/src/pages/index.astro`, hero `factlockcam-hero-sales.png`); deploy via `scripts/deploy_factlockcam_site_cf.sh`.
  - **Archive subdomain:** Flutter courier-only gate — `WebArchiveGateView` at `/`, `CourierUnlockView` at `/courier`; web router blocks logon/hub; browser capture disabled (`capture_panel` conditional exports, hub tile gating).
  - **Deploy:** `scripts/build_web_archive.sh`, `scripts/deploy_web_archive_cf.sh`, `scripts/verify_web_archive_deploy.sh`; Cloudflare Pages project `factlockcam-archive`.
  - **Defines:** `WEB_BASE_URL` default → `https://factlockcam.com`; `WEB_ARCHIVE_BASE_URL` → `https://archive.factlockcam.com`.
  - **Rules:** `.cursor/rules/web-subdomain-deployment.mdc`, `.cursor/rules/cli-execution-gating.mdc`.
  - **Tests:** **52/52**; user-confirmed QA pass.
  - **Wiki:** Added [[Web_Deployment_Architecture_2026-05]]; refreshed [[index]], [[overview]], [[glossary]], [[FactLockCam_Product_Baseline_2026-05]], [[Send_Proof_Courier_2026-05]].

- **Sovereign multi-key lifecycle + thirteenth QA pass**:
  - **Key custody:** `KeyCustodyService`, `FactlockKeystore`, `WalletBackupService`, `AppLockCoordinator` under `lib/core/ghost_key/`; composite `.factlock` (EVM + archive AES).
  - **UX:** Export/Lock/Burn in Account panel; `BurnAccountView` (typed OBLITERATE); `/restore` bricked shell; stable `GoRouter` refreshListenable.
  - **Compliance:** Decoupled legal URLs via `ComplianceNavigation`; removed bundled legal markdown assets.
  - **Tests:** **52/52** (`factlock_keystore_test`, `key_custody_service_test`, `app_lock_coordinator_test`, `burn_account_view_test`).
  - **Rules:** `.cursor/rules/factlockcam-key-lifecycle.mdc`, `.cursor/rules/decoupled-web-routing.mdc`, `.cursor/rules/apple-privacy-compliance.mdc`.
  - **Wiki:** Added [[Sovereign_Key_Lifecycle_2026-05]]; refreshed [[index]], [[overview]], [[glossary]].

## 2026-05-27

- **Cloud vault wiring + twelfth QA pass**:
  - **Supabase:** Migration **`20260527120000_vault_storage.sql`** — private **`factlock_vault`** bucket, `file_size_bytes` on `courier_packages`, Storage RLS; remote **21/21** migrations synced.
  - **Flutter:** `VaultSyncCoordinator` wired into `VaultService.proofLockFile` after ledger commit, before source unlink; isolate encrypt + iOS background upload; `CourierCrypto.encrypt`, `SupabaseVaultService`, `QuotaExceededException`.
  - **Rules:** `.cursor/rules/supabase-cloud-vault.mdc`, `.cursor/rules/factlockcam-wiring.mdc`.
  - **Tests:** `test/cloud_vault_e2e_test.dart` passing; user-confirmed QA pass.
  - **Wiki:** Added [[Cloud_Vault_Wiring_2026-05]]; refreshed [[index]], [[overview]], [[glossary]].
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

## 2026-05-24

- **UI polish + eleventh QA pass**:
  - **Brand header:** `HeavyMetalLogoBanner` defaults to `factlockcam_logoheader.jpg` on hub, logon, and Archive.
  - **Account & Settings:** Heavy Metal backdrop; `HeavyMetalHubTile` rows for legal/support (+ App Web Page / User Guide placeholders).
  - **Archive chronology:** Removed scroll-driven opacity dimming; restored layout constants; added `unified_archive_viewport_test.dart`.
  - **Tests:** `flutter test` **41/41**; user-confirmed QA pass.
  - **Wiki:** Added [[UI_Polish_Hub_Archive_2026-05]]; refreshed [[FactLockCam_Product_Baseline_2026-05]], [[Heavy_Metal_Design_System]], [[index]], [[overview]], [[glossary]].
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

- **App Store remediation + tenth QA pass**:
  - **Nomenclature:** `WEB_VAULT_BASE_URL` → **`WEB_ARCHIVE_BASE_URL`**; default origin **`https://archive.factlockcam.com`**; `TransactionalVaultPersister` → **`TransactionalArchivePersister`**.
  - **Dead code:** Deleted `professional_nav_bar.dart`; hub remains `HapticHubPanel` only.
  - **iOS:** Forensic `NSCameraUsageDescription`; privacy manifest unchanged (already compliant).
  - **Supabase:** Pushed **`20260524150000_optimize_courier_archive.sql`** — courier btree indices on `asset_hash`, `(package_id, expires_at)`, `(owner_id, asset_hash)`; remote **20/20** migrations synced.
  - **Defines:** Re-synced via `sync_flutter_dart_defines.sh`.
  - **Rules:** Added `.cursor/rules/app_store_compliance.mdc`.
  - **Posture:** TestFlight-first; trademark/domains deferred; Ngrok acceptable for Send Proof E2E.
  - **Tests:** `flutter test` **40/40**; user-confirmed QA pass.
  - **Wiki:** Added [[App_Store_Remediation_2026-05]]; refreshed [[Production_Transition_2026-05]], [[Send_Proof_Courier_2026-05]], [[FactLockCam_Product_Baseline_2026-05]], [[index]], [[overview]], [[glossary]].
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

- **Production transition + ninth QA pass**:
  - **Config:** `APP_ENVIRONMENT=production`, `WEB_VAULT_BASE_URL=https://vault.factlockcam.com`, `SUPPORT_URL=https://factlockcam.com/support` in dart-defines sync; account panel + courier error copy updated.
  - **Supabase:** Migrations `20260524130000_optimize_courier_lookups.sql`, `20260524140000_courier_lookup_trigger.sql` pushed local + hosted.
  - **iOS:** `PrivacyInfo.xcprivacy` DiskSpace/Email/Location declarations; `ITSAppUsesNonExemptEncryption=false`.
  - **Tests:** `setupTestDependencies()`, Flutter-test isolation guards, polygon retry defer parity; `flutter test` **40/40**.
  - **QA:** User-confirmed pass.
  - **Wiki:** Added [[Production_Transition_2026-05]]; refreshed [[FactLockCam_Product_Baseline_2026-05]], [[Send_Proof_Courier_2026-05]], [[index]], [[overview]], [[glossary]], [[FactLockCam_Master_Blueprint]].
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

- **Send Proof & courier synthesis (agent session)**:
  - **Product:** Certificate PDF + password-protected courier link via iOS share sheet only; **no in-app email** (App Store utility positioning). Recipient E2E unlock **deferred** until public Flutter Web vault deployed at `WEB_VAULT_BASE_URL` (stealth pre–App Store; no marketing domain required for ongoing dev).
  - **Code:** `SendProof` notifier wired to UI; `CertificateExportService` PDF; `courier-unlock` edge function; migration `20260524120000_courier_download_limits.sql`; `ProofCourierService` isolate fix; removed `dispatch-courier` from repo.
  - **Wiki:** Added [[Send_Proof_Courier_2026-05]]; refreshed [[FactLockCam_Product_Baseline_2026-05]], [[index]], [[overview]], [[glossary]].
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

## 2026-05-22

- **Live Polygon mainnet + eighth QA pass**:
  - **Code:** Removed `polygon-sim:` fallback from `anchor-relay`; structured 500 on missing secrets; client sim-hash guard + relay error surfacing; `_dispatchPolygonRelay` propagates failures; `POLYGON_RPC_URL` in dart-defines sync.
  - **Ops:** `ALCHEMY_API_URL` + `RELAYER_PRIVATE_KEY` set on hosted `jqvnwtslmoxjwzusmtxs`; `anchor-relay` redeployed.
  - **QA:** Physical iPhone capture — real Polygon tx confirmed on-chain; user-confirmed pass.
  - **Wiki:** Refreshed [[Polygon_Mainnet_Wiring_2026-05]], [[Polygon_Saga_Live]], [[FactLockCam_Product_Baseline_2026-05]], [[index]], [[overview]], [[glossary]].
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

- **Polygon mainnet wiring + seventh QA pass**:
  - **Code:** `anchor-relay` live broadcast + QA sim fallback; `PolygonChainNotarizer`; `transactionHash` API contract; RPC receipt polling; `journal_repository` web stub/io split; `seal_ledger_repository` syntax fix; migration `20260523000000_polygon_tx_indexing.sql`.
  - **Ops:** `supabase functions deploy anchor-relay`; `supabase db push`; repaired stuck `pending_notarization` rows during QA.
  - **QA:** User-confirmed pass (capture + sync no longer stuck).
  - **Wiki:** Added [[Polygon_Mainnet_Wiring_2026-05]]; refreshed [[Polygon_Saga_Live]], [[FactLockCam_Product_Baseline_2026-05]], [[index]], [[overview]], [[glossary]].
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

## 2026-05-21

- **Identity lifecycle + sixth QA pass** (committed to `main`):
  - **Code:** `wallet_history` + `proof_ledger.evm_address` migration; SQLite v6 wallet lineage columns; `ArchiveRepository`, `ProofCourierService`, `PlatformChannelCoordinator`, `ArchiveGridItem` / restore banner; iOS background task + document picker; `.cursor/rules/prooflock-identity-lifecycle.mdc`.
  - **Ops:** `supabase db push` to hosted project; iOS simulator startup verified (`Supabase init completed`).
  - **Wiki:** Added [[Identity_Lifecycle_And_Data_Lineage]]; refreshed [[FactLockCam_Product_Baseline_2026-05]], [[index]], [[overview]], [[glossary]].
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

- **App Store prep + fifth QA pass** (committed to `main`):
  - **Code:** Bundled legal docs + `LegalDocumentView`; multi-shot capture (`sealAndStoreCapture` buffered bytes, `_enqueueCaptureSeal`); GPS/UTC HUD; archive delete/view/thumbnail fixes; sidecar-lock staging promote (fixes 0-byte `.seal`); caller-isolate vault I/O; proof bundle zip share; `cipher_engine_roundtrip_test`, `locked_rename_test`.
  - **QA:** User-confirmed pass on physical device (rapid photos, thumbnails, view/decrypt, delete).
  - **Wiki:** Added [[App_Store_Prep_Capture_Seal_2026-05]]; refreshed [[FactLockCam_Product_Baseline_2026-05]], [[Archive_Transactional_Journal]], [[Isolate_Lock_Coordinator]], [[index]], [[overview]], [[glossary]].
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

- **Sprint 4 reactive UI locks + fourth QA pass** (committed to `main`):
  - **Code:** `IsolateLockCoordinator`, advisory file locks, `AssetSecuringOverlay` on chronology/grid, `PrivacyInfo.xcprivacy`, `docs/app_store_submission_checklist.md`, `integration_test` stub.
  - **QA:** User-confirmed pass on physical device.
  - **Wiki:** Refined [[Isolate_Lock_Coordinator]]; cross-links in [[Archive_Transactional_Journal]], [[FactLockCam_Product_Baseline_2026-05]], [[overview]], [[glossary]], [[index]].
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

- **Sprint 2 vault integrity + third device QA** on `cursor/wiki-supabase-local-reset-audit`:
  - **Code:** WAL journal (`factlockcam_journal.db`), `TransactionalVaultPersister`, boot recovery before `runApp`, sqflite single-flight + eager open, hub lazy archive/account panels, unique `VaultPanelNavigationBar` hero tags, landscape 2×2 hub grid, dart-defines sync → `GeneratedDartDefines` (gitignored generated file).
  - **QA:** User-confirmed physical iPhone capture + Polygon ledger insert after SQLite race fix; hub RenderFlex overflow fixed.
  - **Wiki:** Added [[Archive_Transactional_Journal]]; refreshed [[FactLockCam_Product_Baseline_2026-05]], [[FactLockCam_Master_Blueprint]], [[Polygon_Saga_Live]], [[index]], [[overview]], [[glossary]].
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

## 2026-05-20

- **Polygon proof UX + certificate tx hash** (user-confirmed QA pass) on branch `cursor/wiki-supabase-local-reset-audit`:
  - **Code:** Await `anchor-relay` during capture (fixes missing post-capture progress); persist `chain_tx_hash` in SQLite v5; `CertificateExportService` includes ledger tx hash; monitor seeds initial `ProofState`; vault badges use **Generating Proof…** copy.
  - **Tests:** `vault_service_retry_test.dart` updated for `markSyncSucceeded(chainTxHash:)`; 33/33 pass.
  - **Wiki:** Refreshed [[Polygon_Saga_Live]] (await-relay sequence, QA table); [[FactLockCam_Product_Baseline_2026-05]], [[FactLockCam_Master_Blueprint]], [[overview]], [[glossary]], [[index]] aligned.
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

- **Final QA pass + wiki cleanup** on branch `cursor/wiki-supabase-local-reset-audit`:
  - User-confirmed QA pass; `flutter test` **33/33**; analyzer warnings cleared in vault UI (`Matrix4.translateByDouble`, unused catch params) and web crypto lint.
  - **App icon** committed: `FactLockCamAppIcon.png` + `flutter_launcher_icons` for iOS/Android/web (commit `b476f37`).
  - **Wiki optimized:** [[index]] reorganized — active analyses vs archived snapshots; [[FactLockCam_Product_Baseline_2026-05]] updated with branding + final QA status; [[FactLockCam_Master_Blueprint]] test count corrected (33); [[Polygon_Saga_Live]] QA date aligned; [[glossary]] adds `flutter_launcher_icons`, app icon, fixes `SimulatedChainNotarizer` vs live Polygon saga; [[overview]] points to baseline first.
  - Validation: `python3 scripts/wiki_ingest.py --validate` — 22/22 pages OK.

## 2026-05-21

- **Polygon Try 2 live + QA pass** on physical iPhone (~2s proof finalization):
  - Landed PR1–PR5: `WalletService`, `VaultBlockchainHandler`, async `VaultService` saga, `anchor-relay` Edge Function, migrations (`notarization_status`, `evm_address`, finalize RPCs), Realtime monitor, `ProofSyncNotifier` local pending clear.
  - Fixed indefinite pending UI: relay HTTP 200 did not call `markSyncSucceeded` until `ProofSyncNotifier` + `_finalizeLocalPolygonSync`.
  - Hosted deploy: `supabase db push`, `supabase functions deploy anchor-relay`; `USE_POLYGON_NOTARIZER` default **true** in dart-defines sync.
  - Added [[Polygon_Saga_Live]]; updated [[Polygon_Try1_Postmortem]], [[FactLockCam_Product_Baseline_2026-05]], [[glossary]], [[index]], [[overview]], [[ProofLock_Refactor_Scope]] (partial).

## 2026-05-20

- **Polygon Try 1 postmortem audit** after May 19 rollback:
  - Added repo-root [`POSTMORTEM_POLYGON_TRY1.md`](../POSTMORTEM_POLYGON_TRY1.md) and wiki [[Polygon_Try1_Postmortem]].
  - Automated bisect on stash snapshot `c87ac99`: Polygon DI alone passes 33/33 tests; UI-only changes fail `widget_test` back-button finder; full WIP builds/installs on device and sim.
  - Updated root-cause ranking: process failure + device-specific runtime (dual IndexedStack cameras + UI bisect) — Polygon DI rejected as startup cause.
  - Documented Try 2 PR sequence (PR0 lazy camera → PR1–PR5 Polygon path).
  - Forensic branch: `audit/polygon-try1-bisect` (worktree `ProofLockCleanup-audit`).
- **Integrity restoration + wiki refinement** after post-audit device regression:
  - Root cause of post-audit "broken app": audit worktree installed WIP binary on iPhoneTanto; main repo source was docs-only.
  - **PR0 landed:** `VaultHomeView._cameraPanel()` lazy-mounts `CameraView` only when Picture/Video panel active — fixes physical-device blank screen from eager dual-camera init.
  - **QA re-verified:** `flutter test` 33/33 (10 files); iPhoneTanto manual launch passes full hub workflow (user-confirmed).
  - Refined [[Polygon_Try1_Postmortem]], [[iOS_Device_Development_Workflow]], [[FactLockCam_Master_Blueprint]], [[FactLockCam_Product_Baseline_2026-05]], [[glossary]], [[overview]], repo-root postmortem Resolution section; Try 2 entry point → PR1.

## 2026-05-19

- **Device QA + wiki reconciliation** after hub refactor commit `19269d2`:
  - Added [[iOS_Device_Development_Workflow]]: physical iOS 26 + Flutter 3.38 `flutter run` VM Service attach failures vs successful build/install/manual launch; recommended `flutter attach` and Xcode paths.
  - Updated [[FactLockCam_Master_Blueprint]], [[MASTER_CONTEXT16MAY2026]], [[FactLockCam_Product_Baseline_2026-05]], [[glossary]], [[index]], [[overview]] to replace stale **ProfessionalNavBar** / bottom-tab / standalone `/archive` descriptions with **hub-first** `HapticHubPanel` + five `IndexedStack` panels (hub, photo, video, archive omni, account).
  - Documented May 2026 rollback: uncommitted debug/Polygon WIP stashed. VM attach failures are tooling-layer; blank device screen was addressed by PR0 lazy camera mount (see [[Polygon_Try1_Postmortem]]).

## 2026-05-17

- Performed comprehensive LLM Wiki review and cleanup: updated stale references across 7 wiki pages for accuracy with the current codebase state.
  - Fixed broken wiki links (`CourierRepository`, `VaultPathResolver` glossary terms).
  - **[[FactLockCam_Master_Blueprint]]**: Updated test count 31→36, replaced `ShutterButtonPainter`→`ShutterIrisPainter`, corrected standalone `/camera` route → tab-embedded `IndexedStack`/`ProfessionalNavBar` hub model.
  - **[[FactLockCam_Blueprints_14May2026]]**: Updated companion reference from [[MASTER_CONTEXT13MAY2026]]→[[MASTER_CONTEXT16MAY2026]], removed standalone `/camera` route from routing table, test count 31→36.
  - **[[FactLockCam_Product_Baseline_2026-05]]**: Replaced `ShutterButtonPainter`→`ShutterIrisPainter`, updated camera routing description for tab-embedded model.
  - **[[overview]]**: Updated Related Notes to reference [[MASTER_CONTEXT16MAY2026]] instead of 13MAY.
  - **[[index]]**: Updated Blueprints and Master Blueprint descriptions for current architecture.
  - **[[Heavy_Metal_Design_System]]**: Added [[MASTER_CONTEXT16MAY2026]] to Related Notes.
  - **[[glossary]]**: Updated `AcquisitionMode` entry (no standalone `/camera` route).
- Cleaned up stale `snapseal` tag on [[Project_Audit_2026-05-11]] analysis page.

- Implemented **Courier Retrofit** (per Diagnostic Integrity Report "Send Proof" Courier Failure blueprint):
  - Decoupled state and UI: `CourierLink` notifier returns `Future<String>` (not void); `SharePlus` side-effect moved to `ArchiveItemActions.showSendProofDialog` in the UI layer.
  - Fixed iOS path drift: created `VaultPathResolver` DI service; injected into `VaultService`; all four `_storage.resolveArchivePaths` call sites replaced with `_pathResolver.resolve`.
  - Removed `.plock` reference from `courier_crypto.dart` doc comment; confirmed no XOR/PLOCK_VERIFIED_V1 exists in codebase (AES-GCM unified end-to-end).
  - Encapsulated web data layer: created `CourierRepository` wrapping `SupabaseClientHandle` with typed `checkCourierAttempts`, `attemptUnlock`, `downloadBlob` methods; injected into `CourierUnlockNotifier`, replacing direct `Supabase.instance.client` access.
  - Wired Send Proof stubs: replaced SnackBar TODOs in `AssetInspectorScreen._onSendProof` and `ChronologyViewport._onSwipeShare` with full `showSendProofDialog` flow.
- Added glossary terms: `CourierRepository`, `VaultPathResolver`.
- Updated [[FactLockCam_Blueprints_14May2026]] with courier retrofit details and corrected suggested read order.
- Updated [[MASTER_CONTEXT16MAY2026]] audit findings to reflect wired courier export.
- Updated [[FactLockCam_Master_Blueprint]] courier/package export and "Prepare A Courier Payload" section.
- Updated [[overview]] to reference [[MASTER_CONTEXT16MAY2026]] instead of 13MAY.

## 2026-05-14

- Added [[FactLockCam_Blueprints_14May2026]] under `wiki/analyses/`: layered technical architecture blueprint (companion to [[MASTER_CONTEXT13MAY2026]]); mirrors repo root `FactLockCam_Blueprints14May2026.md`.
- Updated [[index]] Analyses section with navigation link to the new page.
- Populated [[overview]] and initialized this [[log]] (files were previously empty).

## 2026-05-15

- Performed comprehensive project-state audit covering Flutter codebase (49 Dart files, P0 corrupted file), Supabase migrations (10 files, 2 destructive repairs), test coverage (11 files, gaps), wiki health (18 pages, all pass validation), and unresolved risks (10 items).
- Deleted corrupted `vault_service_io.dart` file (trailing newline in filename, contained SQL migration content rather than Dart).
- Added 11 missing terms to [[glossary]]: AES-GCM, C2PA, PolygonChainNotarizer, ProofLockConflictException, proof_ledger, REQUIRE_HARDWARE_ATTESTATION, RLS, RPC, SealLedgerRepository, SHA-256, SimulatedChainNotarizer.
- Marked `ShutterButtonPainter` as DEPRECATED in [[glossary]] (superseded by ShutterIrisPainter).
- Added `deepseek-cursor-proxy/` to `.gitignore`.

## 2026-05-16

- Performed comprehensive project audit: `flutter test` (36/36 passing, all 11 test files), `dart analyze lib/` (1 info: `dart:html` deprecation), `dart format --output=none` (5 of 79 unformatted), wiki validation (18/18 pages pass).
- Created [[MASTER_CONTEXT16MAY2026]] at repo root, superseding [[MASTER_CONTEXT13MAY2026]].
- Created `wiki/analyses/MASTER_CONTEXT16MAY2026.md` as wiki twin.
- Updated [[index]] to mark 13MAY as superseded and 16MAY as current snapshot.
- Implemented `ProfessionalNavBar` bottom navigation: custom forensic-styled tab bar (Home/Picture/Video/More) with VerifiedNeon accent, monospaced uppercase labels, and 2px selected-tab indicator.
- Rewrote `VaultHomeView` as `ConsumerStatefulWidget` shell using `IndexedStack` to preserve tab state; camera views (photo/video) embedded directly instead of standalone GoRouter route.
- Removed standalone `/camera?mode=` route from `app_router.dart`; camera is now tab-embedded.
- Fixed post-capture flow: `CameraView.onCaptureComplete` callback switches back to Home tab after sealing completes (eliminates the "stranded" post-capture state).
- Fixed video capture "Sealing..." hang: added `setState(() { _isSealing = false; })` on success path in `_sealCapturedFile` — the `IndexedStack` keeps `CameraView` alive, so the stale flag made the sealing overlay persist.
- Moved burn wallet and sign-out actions off the `ChronologyViewport` header; `HeavyMetalLogoBanner` used without actions parameter.
- Cleaned up unused imports in chronology_viewport.dart (auth_controller, logon_view, acquisition_mode, camera_view).
- Restored Picture/Video empty-state action tiles with `onCaptureRequested` callback that switches parent tab index.
- Updated widget tests: 2/2 pass, covering logon shell rendering and tab-switch navigation flows.
- Updated [[MASTER_CONTEXT16MAY2026]] routing and hub sections to reflect new tab-shell architecture.

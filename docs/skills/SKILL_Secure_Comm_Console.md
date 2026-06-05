# SKILL: Secure Communications Console Web Realignment

## Description

Procedural instructions to upgrade the unauthenticated Flutter web unlock layer (`/courier?pkg=…`) into a high-fidelity, state-animated validation surface matching marketing and legal specifications.

## Prerequisites

- Read `wiki/index.md` → [[FactLockCam_Product_Baseline_2026-05]], [[Web_Deployment_Architecture_2026-05]], [[Send_Proof_Courier_2026-05]].
- Layout anchors: `factlockcam_app/lib/ui/web/courier_unlock_view.dart`, `courier_unlock_notifier.dart`.
- Crypto: `factlockcam_app/lib/core/crypto/courier_crypto.dart` (browser AES-GCM + SHA-256).
- Theme: `app_colors.dart`, `app_typography.dart`.
- Copy: `factlockcam_app/lib/core/marketing/approved_pitch.dart` + `marketingBanList`.
- Rules: `.cursor/rules/04_forensic_ui_standards.mdc`, `.cursor/rules/web-subdomain-deployment.mdc`, `courier-origination.mdc`.

## Instruction 1: State Upgrades

1. Add `CourierUnlockPhase` enum: `idle`, `processing`, `cascadeAnimation`, `playbackReady`, `viralLoop`.
2. Extend `CourierUnlockState` with `phase`, `targetAssetHash`, `attestation`, `showProofDeepDive`, `playbackCompleted`.
3. Split `unlock()` pipeline:
   - RPC success → `cascadeAnimation` (store pending payload; **no** `verifiedBytes` yet).
   - After 1500ms cascade → download encrypted blob → `CourierCrypto.decryptAndVerifyFingerprint`.
   - Success → `playbackReady`; failure → `idle` with error message.
4. Download encrypted blob **immediately after RPC** (signed URL 60s TTL); hold in notifier private field; decrypt only after cascade.

## Instruction 2: Phase 1 — The Gate

1. Re-theme with `AppColors.titaniumDeep` scaffold, `titaniumPanel` inputs, thin `titaniumEdge` borders.
2. Headline: **Secure Communications Console** (`monoLg`, `verifiedNeon`).
3. Pulsed node decoration on OTP field (`kineticGreen` opacity pulse).
4. Preserve UGC report affordance and attempt status panel.
5. User-visible copy: **Archive** taxonomy only — no **Vault** in UI strings.

## Instruction 3: Phase 2 — Verification Cascade

1. Implement `HashCascadeTicker` — per-character random alphanumeric roll for 1500ms, snap to `targetAssetHash`.
2. Hybrid styling: `spaceMono` + 1px `verifiedNeon` container border (~40% alpha) during roll; `kineticGreen` glyphs.
3. Wrap ticker in `RepaintBoundary`.
4. Post-snap verified state: minimalist `titaniumPanel` strip, hash in full `verifiedNeon`.

## Instruction 4: Phase 3 — Viewing Layout

1. `CourierMediaStage`: image via `Image.memory`; video via web blob-URL `VideoPlayerController`.
2. `CourierProofPanel`: monospace proof strip; `AnimatedCrossFade` deep-dive (Transaction ID, sealed timestamp, block index placeholder).
3. Fetch attestation via `get_public_proof_attestation` RPC (anon-safe SECURITY DEFINER).
4. `RepaintBoundary` on media viewport.

## Instruction 5: Phase 4 — Viral Loop CTA

1. `ViralLoopOverlay`: blur scrim over media on end-of-stream (video listener) or timed/manual trigger for images.
2. Copy: `mechanismTagline` + compliant zero-trust pitch from `approved_pitch.dart`.
3. CTA: **Get FactLockCam** → `APP_STORE_URL` (fallback `WEB_BASE_URL`).
4. `dismissViralLoop()` returns to `playbackReady`.

## Instruction 6: Backend (agent-executed)

The agent runs hosted Supabase ops — **do not ask the user to push migrations**.

1. Author migration: `get_public_proof_attestation(p_asset_hash text) returns jsonb`.
2. `./scripts/factlockcam_supabase_pipeline.sh push-dry-run` then `push`.
3. `supabase functions deploy courier-unlock --no-verify-jwt` when edge function changes.
4. `CourierRepository.fetchPublicAttestation(assetHash)`.
5. Verify RPCs exist on linked project before declaring QA-ready.

## Validation

```bash
cd factlockcam_app && flutter test test/courier_unlock_reporting_test.dart test/courier_unlock_console_test.dart test/courier_unlock_notifier_test.dart test/marketing_compliance_test.dart
flutter analyze lib/ui/web/
```

Use `setupTestDependencies()` in `setUpAll`; mock `CourierRepository` — no live Supabase in tests.

## Wiki Reconciliation

After implementation:

1. Append `wiki/log.md` — Secure Communications Console transition.
2. Update `wiki/concepts/FactLockCam_Product_Baseline_2026-05.md` capability matrix (cascade + viral CTA verified).
3. Run `python3 scripts/wiki_ingest.py --validate`.

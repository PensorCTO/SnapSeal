---
tags: [analysis, factlockcam, web, courier, secure_communications, qa, 2026-06]
summary: "Twenty-sixth structural pass + twenty-seventh QA (2026-06-05): phased Secure Communications Console on /courier — hash cascade, deferred decrypt, Proof Panel, viral CTA; 101/101 tests; user QA passed."
---

# Secure Communications Console (June 2026)

## Core Synthesis

**Twenty-seventh device QA pass (2026-06-05)** — user-confirmed **application stable** after refactoring the unauthenticated Flutter Web **`/courier?pkg={uuid}`** portal from a utility downloader into a phased **Secure Communications Console**.

The console preserves zero-trust boundaries: recipients never see raw keys until password unlock succeeds; full-file decryption runs in the browser only after a deliberate **1.5s hash cascade** animation completes.

### Phase machine (`CourierUnlockPhase`)

| Phase | UX | Backend / crypto |
|-------|-----|------------------|
| `idle` | Gate panel — password entry, attempt counter | `check_courier_attempts` |
| `processing` | Spinner after submit | `attempt_courier_unlock` RPC + encrypted blob download |
| `cascadeAnimation` | Monospace hash ticker (Verified Neon glow) | 1500ms timer; blob held in memory |
| `playbackReady` | Media stage + Proof Panel | `CourierCrypto.decryptAndVerifyFingerprint` (post-cascade) |
| `viralLoop` | Timed overlay CTA → App Store | `APP_STORE_URL` dart-define |

State lives in `CourierUnlockNotifier` (`courier_unlock_notifier.dart`). Widgets under `lib/ui/web/widgets/` are phase-driven; expensive paint paths use `RepaintBoundary`.

### Proof Panel

- Public attestation via **`get_public_proof_attestation(p_asset_hash)`** (`20260605140000_public_proof_attestation.sql`) — anon-safe SECURITY DEFINER RPC.
- `CourierRepository.fetchPublicAttestation(assetHash)`; no direct `proof_ledger` SELECT for recipients.
- Deep-dive copy uses Archive-compliant terminology (Digital DNA, chain-of-custody).

### Web media playback

- `courier_web_media_source_web.dart` — blob URL from decrypted bytes; video/audio via HTML `<video>`.
- `courier-unlock` Edge Function forwards **`content_mime_type`** for MIME hints.
- Images: timed display then viral loop; video: end-of-stream triggers viral loop.

### Hosted ops (agent-executed)

| Artifact | Migration / deploy |
|----------|-------------------|
| Public attestation RPC | `20260605140000_public_proof_attestation.sql` |
| Send Proof schema repair | `20260605210000_repair_send_proof_schema.sql` (restores metering + 7-param `get_or_create_courier_package` after accidental `my_schema` push) |
| Edge function | `courier-unlock` — `content_mime_type` in JSON response |

Pipeline: `./scripts/factlockcam_supabase_pipeline.sh push`. Agents run pushes directly (`.cursor/rules/supabase-agent-ops.mdc`).

### QA surfaces verified

- iPhone **Send Proof** → share sheet → recipient opens `{WEB_ARCHIVE_BASE_URL}/courier?pkg=…`
- Password gate, cascade, decrypt, media playback, Proof Panel, viral CTA
- Interim archive host: `https://main.factlockcam-archive.pages.dev` (custom domain `archive.factlockcam.com` DNS deferred)

### Tests

**101/101** `flutter test` — includes `courier_unlock_console_test.dart`, `courier_unlock_notifier_test.dart`, `courier_unlock_reporting_test.dart`, `marketing_compliance_test.dart`.

### Skill

`docs/skills/SKILL_Secure_Comm_Console.md` — phase checklist, agent-owned backend steps, validation commands.

## Provenance Tracking

* *Structural pass*: Twenty-sixth pass 2026-06-05 — console refactor, attestation RPC, widget suite, tests ([[Web_Deployment_Architecture_2026-05]]).
* *QA pass*: Twenty-seventh pass 2026-06-05 — user QA passed; Send Proof E2E + hosted schema repair confirmed stable.
* *Code*: `courier_unlock_view.dart`, `courier_unlock_notifier.dart`, `courier_unlock_phase.dart`, `lib/ui/web/widgets/*`, `courier_repository.dart`, `supabase/functions/courier-unlock/index.ts`.

## Related Notes

* [[Web_Deployment_Architecture_2026-05]]
* [[Send_Proof_Courier_2026-05]]
* [[UGC_Safety_Reporting_2026-06]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[Zero_Trust_RLS_Audit_2026-06]]

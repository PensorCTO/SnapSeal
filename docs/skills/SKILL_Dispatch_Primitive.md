# SKILL: Dispatch Primitive Framework

## Description

Decoupled task toolkits for the Secure Communications Console product transformation. Execute **one task at a time**; do not proceed until the previous module compiles cleanly and preserves the current `flutter test` completion rate.

## Prerequisites

Read before any task:

- `wiki/index.md` — navigation boundaries
- `wiki/overview.md` — runtime snapshot
- `wiki/log.md` — recent schema changes and QA pass parameters
- `wiki/concepts/FactLockCam_Product_Baseline_2026-05.md` — verified workflow and metrics
- `factlockcam_app/lib/app/router/app_router.dart` — routes and redirection gates
- `factlockcam_app/lib/ui/mobile/archive_home_view.dart` — primary shell layout (hub `IndexedStack`)

Related skills:

- [SKILL_Compliance_Architecture.md](SKILL_Compliance_Architecture.md) — UGC safety, lexicon, RLS audit
- [SKILL_Secure_Comm_Console.md](SKILL_Secure_Comm_Console.md) — web courier phased console (Tasks 4–5 overlap)

Rules: `.cursor/rules/02_supabase_rls_security.mdc`, `courier-origination.mdc`, `app_store_compliance.mdc`, `supabase-agent-ops.mdc`

## Bite-Sized Roadmap

| Phase | Target | Scope | Validation |
|-------|--------|-------|------------|
| Task 1 | Supabase Backend | UGC reporting schema & RLS; anon-safe attestation RPC | Migration dry-run; policy/RPC probes |
| Task 2 | Flutter Navigation Shell | Tri-state NavBar: CAPTURE, ARCHIVE, DISPATCH CONSOLE | Route verification; lazy panel mount |
| Task 3 | Mobile Dispatch Console | Staging grid, parameters toggles, Send Proof trigger | Provider lifecycle; mock transmission tests |
| Task 4 | Web Portal Phase 1 & 2 | Dark gate + 1.5s hash cascade ticker | RepaintBoundary; cascade timing tests |
| Task 5 | Web Portal Phase 3 & 4 | Proof Panel deep-dive + viral loop CTA | End-of-stream integration; boundary tests |

---

## Task 1 — Supabase UGC Reporting Schema & Key Isolation

**Status (2026-06-05):** Shipped in twenty-fourth pass. Task 1 is **verify → gap-fix (if drift)** — not greenfield.

### Description

Append-only reporting table and anon-safe metadata RPCs for App Store Guideline 1.2 while preserving cryptographic zero-knowledge bounds.

### Instructions

1. Cross-check linked project token in `.env.qa.local` / `.env.local` via `./scripts/factlockcam_supabase_pipeline.sh doctor`.
2. **Do not** run `supabase migration new create_ugc_reporting_matrix` if `courier_content_reports` already exists — use [supabase/migrations/20260605120000_ugc_safety_infrastructure.sql](../../supabase/migrations/20260605120000_ugc_safety_infrastructure.sql).
3. Verify RLS on `courier_content_reports`: INSERT for `anon` + `authenticated`; **no client SELECT** (service role / admin only).
4. Verify `get_public_proof_attestation` in [supabase/migrations/20260605140000_public_proof_attestation.sql](../../supabase/migrations/20260605140000_public_proof_attestation.sql) — returns `chain_tx_hash`, `sealed_at`, `notarization_status`; never `owner_id` or `profiles.*`.
5. **Purge lifecycle:** quarantine via `moderation_status` + Edge Function (`courier-content-scan`); **do not** auto-delete storage blobs inside PostgreSQL on report threshold. Human-reviewed purge deferred to a future `courier-moderation-action` Edge Function.

### Agent-executed validation

```bash
./scripts/factlockcam_supabase_pipeline.sh push-dry-run
# RPC probes with anon key (see Task 1 verification SQL in wiki/log)
cd factlockcam_app && flutter test
python3 scripts/wiki_ingest.py --validate
```

---

## Task 2 — Tri-State Navigation Shell Refactor

### Description

Restructure the primary mobile interface: remove legacy bottom-navigation branches; elevate **Dispatch Console** as a first-class global navigation primitive.

### Instructions

1. Trace navigation indexing in `archive_home_view.dart` (`IndexedStack` / hub panels).
2. Refactor navbar to three uppercase actions: **CAPTURE**, **ARCHIVE**, **DISPATCH CONSOLE** (corporate typography weights).
3. Wire back-button rules: sub-panel **Back** returns to main launcher index.
4. Lazy-mount camera panels — allocate camera memory only when the capture tab index is active (PR0 pattern).

### Validation

- Route verification in `app_router.dart`
- Widget tests for tab isolation
- `flutter test` green before Task 3

---

## Task 3 — Mobile Secure Communications Console View

**Status (2026-06-06):** Shipped — `CourierDispatchView` via hub **Secure Comm** tile (two-step flow); **110+** tests.

### Description

Mobile Dispatch Console: asset staging, dispatch policy parameters, full Send Proof transmission.

### Instructions

1. `CourierDispatchView` — titanium/industrial tokens; horizontal staging grid from `dashboardControllerProvider`.
2. `dispatchConsoleProvider` — selection + presets (downloads: 1|3|5; link TTL: 1|7|30 days).
3. **TRANSMIT PROOF** → `sendProofProvider` (not bare `courierLinkProvider`); share sheet on success.
4. `friendlyCourierDispatchError` shared with `ArchiveItemActions`.
5. RPC `get_or_create_courier_package` accepts `p_max_downloads` / `p_link_ttl_days` (`20260606140000_dispatch_package_params.sql`).

### Validation

- `courier_dispatch_view_test.dart` + `dispatch_primitive_nav_test.dart`
- `setupTestDependencies()`; mock `sendProofProvider` — no live Supabase in unit tests

---

## Task 4 — Web Portal Phase 1 & 2

### Description

Dark-theme credential gate and 1.5s hash text-cascade ticker on `/courier?pkg=…`.

### Instructions

Follow [SKILL_Secure_Comm_Console.md](SKILL_Secure_Comm_Console.md) Instructions 2–3:

- `CourierGatePanel` — titanium palette, pulsed OTP field
- `HashCascadeTicker` — 1500ms roll, `RepaintBoundary`
- Deferred decrypt after cascade (`CourierCrypto`)

### Validation

```bash
cd factlockcam_app && flutter test test/courier_unlock_notifier_test.dart test/courier_unlock_console_test.dart
```

---

## Task 5 — Web Portal Phase 3 & 4

### Description

Proof Panel dropdown expansion and post-stream viral loop CTA overlay.

### Instructions

Follow [SKILL_Secure_Comm_Console.md](SKILL_Secure_Comm_Console.md) Instructions 4–5:

- `CourierProofPanel` + `get_public_proof_attestation`
- `ViralLoopOverlay` on end-of-stream / timed image trigger
- Compliant copy from `approved_pitch.dart` only

### Validation

- `courier_unlock_console_test.dart` — viral loop + proof panel
- `marketing_compliance_test.dart` — no banned claims

---

## Wiki Reconciliation (all tasks)

After each task:

1. Append chronological entry to `wiki/log.md`.
2. Update `wiki/concepts/FactLockCam_Product_Baseline_2026-05.md` when product status changes.
3. No **Vault** in new user-facing Markdown definitions.
4. Run `python3 scripts/wiki_ingest.py --validate`.

---
tags: [analysis, factlockcam, compliance, app_store, legal, routing, june_2026]
summary: "June 2026 compliance refactor: /archive routing, disclaimers.dart, UI Archive rename, marketing guard tests, and Account panel UX fix after QA."
---

# Compliance Refactor (2026-06)

## Core Synthesis

Eighteenth structural pass (**2026-06-03**): align FactLockCam with production legal/semantic boundaries—**Archive** presentation layer, defensible marketing copy, sovereign-key and Polygon disclaimers, without renaming `VaultService` / SQLite / `factlock_vault`.

### Shipped

| Area | Detail |
|------|--------|
| **Routing** | Canonical hub **`/archive`** (`ArchiveHomeView`); **`/vault-home`**, **`/vault-dashboard`**, **`/camera`** redirect permanently. |
| **Legal copy** | [`factlockcam_app/lib/core/legal/disclaimers.dart`](../../factlockcam_app/lib/core/legal/disclaimers.dart) — epistemic integrity, sovereign key custody, Polygon no-SLA, certificate PDF footer + FRE 902. |
| **UI surfaces** | Logon footnote; restore brick; capture HUD; asset inspector one-liner; burn checkbox scoped to **account** destruction. |
| **Account & Settings** | Legal/support **HeavyMetalHubTile** rows unchanged; **Key custody & limits** tile opens scrollable dialog (full disclaimers). Bottom strip = **Log out / Export / Lock / Burn** only (no inline disclaimer wall). |
| **Hub** | Four-tile `HapticHubPanel` centered; no epistemic footnote under tiles (avoids crowding launcher). |
| **Marketing** | [`projects/FactLockCam_Site/src/copy/marketing.ts`](../../projects/FactLockCam_Site/src/copy/marketing.ts) + [`approved_pitch.dart`](../../factlockcam_app/lib/core/marketing/approved_pitch.dart); `marketing_compliance_test.dart` guards `marketingBanList`. |
| **Tests** | **`74/74`** `flutter test` after QA fix. |

### QA regression and fix

Initial Account panel placed three full disclaimer paragraphs in the **fixed bottom** `Padding` above action buttons. On device, that replaced visible **Log out / Export / Lock / Burn** controls with dense mono text. **Fix:** disclaimers moved to **Key custody & limits** dialog tile; hub footnote removed. User-confirmed QA pass after fix.

### Hosted legal (2026-06-03) — deployed

- **Pass 1:** Removed “back up encrypted assets”; distinguished local `.seal`, `.factlock`, cloud ciphertext.
- **Pass 2 (scenario matrix):** Terms §6–9, Privacy §7, Support FAQs + `disclaimers.dart` — Lock vs uninstall vs Burn; keys-only backup; Burn irreversible. Canonical: [[Data_Custody_And_Backup_Model_2026]].
- **Deploy:** `scripts/deploy_factlockcam_site_cf.sh` → Cloudflare Pages (`factlockcam`); user **QA passed** on `AppConfig.termsUrl` / in-app Account flows.

### Remaining follow-up

- Optional: add epistemic + Polygon SLA paragraphs to hosted marketing pages (in-app `disclaimers.dart` remains source of truth for custody matrix).

### Explicitly out of scope

- `VaultService`, `vault_database`, `factlock_vault` bucket, `VaultCourier.tsx` filename.
- `vault_service_io.dart` → `archive_service_io.dart` rename backlog.

## Provenance Tracking

* *Implementation + QA fix*: Agent pass 2026-06-03; device QA confirmed by user same day.
* *Plan*: Compliance Refactor A+B+C (Cursor plan 2026-06-03).

## Related Notes

* [[FactLockCam_Product_Baseline_2026-05]]
* [[Production_Transition_2026-05]]
* [[App_Store_Hardening_2026-05]]
* [[Data_Custody_And_Backup_Model_2026]]
* [[Sovereign_Key_Lifecycle_2026-05]]
* [[Web_Deployment_Architecture_2026-05]]
* [[overview]]

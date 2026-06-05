# FactLockCam — Apple App Store Submission Readiness Report

**Audit date:** 2026-05-23  
**Auditor scope:** Read-only compliance review against the *2026 App Store Compliance & Governance Framework* and cross-reference with **ProofLock_production** (prior approved submission).  
**Target app:** FactLockCam (`com.factlockcam.app`, `factlockcam_app/`)  
**Verdict:** **Not ready for App Store submission** — core privacy/legal/account-deletion posture is strong, but **production infrastructure gates**, **privacy manifest completeness**, and **App Store Connect metadata** must be resolved first.

---

## Executive Summary

FactLockCam inherits much of the compliance architecture that helped **ProofLock** pass review: a bundled privacy manifest, feature-specific permission strings, offline legal documents, account deletion via `perform_full_burn`, StoreKit-free utility positioning, and FRE 902–aligned legal framing. The May 2026 sprint work documented in [[App_Store_Prep_Capture_Seal_2026-05]] and [[Send_Proof_Courier_2026-05]] moved the app materially closer to review-ready.

However, against the **2026 framework’s architectural-integrity bar**, submission today would carry **high rejection risk** in three areas Apple’s automated review increasingly enforces:

1. **Runtime contract mismatch** — `WEB_VAULT_BASE_URL` is bound to an **ephemeral Ngrok tunnel**, so Send Proof courier links will fail for App Review and customers.
2. **Privacy manifest / nutrition-label drift** — the app collects **email** (auth) and **precise location** (camera HUD) but does not declare them; **DiskSpace** API justification present in ProofLock is missing here despite transitive SDK use.
3. **Connect-side governance** — support URL appears **unreachable**, export-compliance key is absent from `Info.plist`, and the **2026 age-rating questionnaire** must be completed in App Store Connect before submission.

| Category | ProofLock (passed) | FactLockCam (current) | Status |
|----------|-------------------|----------------------|--------|
| Privacy manifest present | ✅ | ✅ | Pass |
| Required-reason API coverage | UserDefaults, FileTimestamp, **DiskSpace** | UserDefaults, FileTimestamp only | **Gap** |
| Collected data types in manifest | Empty array | Photos/Videos, UserID | Partial — missing Email, Location |
| Permission strings | Camera, Photo Library, Face ID | Camera, Mic, Location | Pass (different feature set) |
| Account deletion | N/A in audit docs | Double-confirm + `perform_full_burn` | **Pass (stronger)** |
| Legal bundle | External URLs + IAP terms | Bundled ToS/Privacy + native viewer | **Pass (stronger)** |
| IAP / StoreKit | Required + restore flow | None | Pass (simpler) |
| Social auth / Sign in with Apple | Not used | Not used | Pass |
| Deep link URL scheme | `io.prooflock://` (magic link) | Not required (email OTP) | Pass |
| Send Proof / courier E2E | N/A | Blocked on live web archive | **Blocker** |
| Support URL live | `prooflock.io` | `factlockcam.com/support` unreachable | **Blocker** |
| Export compliance (`ITSAppUsesNonExemptEncryption`) | `NO` | Missing | **Gap** |
| Automated test suite | Not audited here | 26 pass / 9 fail | Warning |

**Estimated readiness:** ~72% — fix blockers below to reach submission confidence comparable to ProofLock’s Feb 2025 audit (which reported zero critical failures).

---

## 1. Privacy Manifest (`PrivacyInfo.xcprivacy`)

### 1.1 Framework requirement (2026 §2)

Apple treats the privacy manifest as the immutable source of truth. Missing **Required Reason API** declarations block submission at upload time (ITMS-91053).

### 1.2 FactLockCam current state

**File:** `factlockcam_app/ios/Runner/PrivacyInfo.xcprivacy`  
**Xcode integration:** Included in Runner **Copy Bundle Resources** (`project.pbxproj` → `F4S4PRIV00020001`).

| Key | Value | Assessment |
|-----|-------|------------|
| `NSPrivacyTracking` | `false` | ✅ Correct — no ATT / tracking domains |
| `NSPrivacyTrackingDomains` | `[]` | ✅ Consistent with tracking=false |
| `NSPrivacyAccessedAPITypes` | FileTimestamp (C617.1), UserDefaults (CA92.1) | ⚠️ Partial |
| `NSPrivacyCollectedDataTypes` | Photos/Videos, UserID | ⚠️ Partial |

### 1.3 Gap vs ProofLock_production

ProofLock’s approved manifest (`ProofLock_production/ios/Runner/PrivacyInfo.xcprivacy`) additionally declares:

```xml
NSPrivacyAccessedAPICategoryDiskSpace → E174.1
```

FactLockCam uses `path_provider`, `sqflite`, and `supabase_flutter` (which transitively pulls `shared_preferences` → UserDefaults). Disk-space APIs are commonly invoked by storage plugins. **Re-add DiskSpace (E174.1)** to match the passing ProofLock baseline and reduce ITMS-91053 risk after dependency updates.

### 1.4 Undeclared collected data

| Data actually collected | Evidence | Manifest / Connect label |
|-------------------------|----------|--------------------------|
| **Email address** | `signInWithOtp` / `verifyOTP` in `auth_controller.dart`; Privacy Policy §2 | ❌ Not in manifest (only `UserID`) |
| **Precise location** | `geolocator` stream in `camera_geolocation_stream.dart`; `NSLocationWhenInUseUsageDescription` in Info.plist; Privacy Policy §8 | ❌ Not in manifest |
| Photos / videos | Camera capture + local archive | ✅ Declared |
| User ID | Supabase `auth.uid()` | ✅ Declared |

**Action:** Add `NSPrivacyCollectedDataTypeEmailAddress` and `NSPrivacyCollectedDataTypePreciseLocation` (or `CoarseLocation` if you downgrade collection) with purpose `AppFunctionality`, linked=true, tracking=false. Mirror the same categories in **App Store Connect → App Privacy**.

### 1.5 Third-party SDK manifests (2026 §3)

Since Feb 2025, commonly used SDKs must ship their own manifests. FactLockCam bundles Flutter plugins (camera, geolocator, flutter_secure_storage_darwin, etc.). Before upload:

- [ ] Archive in Xcode → **Generate Privacy Report** and verify aggregated API reasons cover all plugins.
- [ ] Compare plugin versions against Apple’s [privacy manifest SDK list](https://developer.apple.com/support/third-party-SDK-requirements/).

**Verdict:** ⚠️ **WARN → likely FAIL at upload** until DiskSpace + email/location collected-data entries are added and the Xcode privacy report is clean.

---

## 2. Permission Strings (`Info.plist`) — Guideline 5.1.1

### 2.1 FactLockCam

| Key | String | Assessment |
|-----|--------|------------|
| `NSCameraUsageDescription` | "FactLockCam uses the camera to capture media for sealing." | ✅ Present; could be more specific (forensic archive / encryption) |
| `NSMicrophoneUsageDescription` | Records audio with video captures… | ✅ Present — video mode uses audio |
| `NSLocationWhenInUseUsageDescription` | Live GPS on viewfinder for forensic metadata | ✅ Present — matches feature |
| `NSPhotoLibraryUsageDescription` | — | ✅ Correctly omitted — capture is in-app camera, not gallery import |
| `NSFaceIDUsageDescription` | — | ✅ Correctly omitted — no LocalAuthentication / biometric gate |

### 2.2 ProofLock comparison

ProofLock used gallery-based import (`NSPhotoLibraryUsageDescription`) and Face ID for archive unlock. FactLockCam’s permission set reflects a **different product surface** (live camera + GPS HUD). Omissions are intentional and compliant.

### 2.3 Missing keys vs ProofLock

| Key | ProofLock | FactLockCam | Notes |
|-----|-----------|-------------|-------|
| `ITSAppUsesNonExemptEncryption` | `NO` | **Missing** | Required for export compliance questionnaire |
| `CFBundleURLTypes` | `io.prooflock://` | **Missing** | OK — FactLockCam uses **email OTP**, not magic-link deep links |
| `LSApplicationQueriesSchemes` | `mailto` | Missing | Low risk — share sheet handles delivery |

**Action:** Add `ITSAppUsesNonExemptEncryption` = `NO` if you qualify for the standard exemption (AES for app functionality only, no proprietary non-standard crypto export).

**Verdict:** ✅ **PASS** on usage descriptions; ⚠️ add export-compliance key.

---

## 3. AI Governance & Data Sovereignty (2026 §3, Rule 5.1.2(i))

| Check | Result |
|-------|--------|
| Third-party AI model calls in `lib/` | ❌ None found |
| User disclosure before AI data transfer | N/A — no AI providers |
| Privacy Policy AI section | ✅ §6 explicitly states no third-party AI/ML sharing |
| Legal UI claims | ✅ Uses "tamper-evident", "authenticity heuristics"; avoids banned certainty language |

**Verdict:** ✅ **PASS** — FactLockCam is ahead of the 2026 AI transparency curve.

---

## 4. Account Deletion, Legal & Support (Guidelines 5.1.1(v), hub refactor rules)

### 4.1 Account deletion — **PASS (exceeds ProofLock baseline)**

| Requirement | Implementation |
|-------------|----------------|
| In-app deletion path | Account panel → **Burn account** |
| Double confirmation | Two `CupertinoAlertDialog` steps (`account_settings_panel.dart`) |
| Server wipe | `AuthRepository` → RPC `perform_full_burn` |
| Local wipe | Auth controller invalidates dashboard + thumbnail cache post-burn |

This satisfies Apple’s account-deletion requirement and matches `.cursor/rules/factlockcam-hub-refactor.mdc`.

### 4.2 Legal documents — **PASS**

| Document | Location | In-app access |
|----------|----------|---------------|
| Terms of Service | `assets/legal/TermsOfService.md` | Account → Legal |
| Privacy Policy | `assets/legal/PrivacyPolicy.md` | Account → Legal |
| FRE 902 disclaimer | `core/legal/disclaimers.dart` | Certificate PDF footer + ToS §2 |

Certificate PDF includes Polygonscan link and disclaimer (`certificate_export_service.dart`).

### 4.3 Support URL — **FAIL**

- **Configured:** `https://factlockcam.com/support` (`app_config.dart`)
- **Reachability (2026-05-23):** DNS/connectivity check failed — host did not resolve within audit window.

Apple reviewers tap Help & Support. A dead link is a common 2.1 *Performance* / metadata rejection.

**Action:** Publish a live support page (even a minimal static FAQ + contact) **before** submission, or temporarily point to a verified working URL and update App Store Connect metadata to match.

**Verdict:** Legal ✅ | Support URL ❌ **BLOCKER**

---

## 5. Authentication Parity (Guideline 4.8) — **PASS**

| Check | FactLockCam |
|-------|-------------|
| `google_sign_in` / Facebook auth | Not present |
| Auth mechanism | Supabase email OTP ("Magic Number") |
| Sign in with Apple required? | **No** — no third-party social login |

ProofLock passed with the same pattern (`APP_STORE_READINESS_AUDIT.md` §3).

---

## 6. Monetization & Payments (Guideline 3.1.1) — **PASS**

| Check | Result |
|-------|--------|
| `in_app_purchase` / StoreKit | Not in `pubspec.yaml` |
| Stripe / external digital payments | Not found |
| Restore purchases | N/A |

FactLockCam is a **free utility** (capture + archive + share). This is simpler than ProofLock’s subscription surface and removes Guideline 3.1.2 IAP disclaimer requirements entirely.

---

## 7. Send Proof SAGA & Courier Governance (2026 §5)

The 2026 framework’s ProofLock blueprint defines the expected secure-media workflow. Mapping to FactLockCam:

| Blueprint step | Expected | FactLockCam status |
|----------------|----------|-------------------|
| Local encryption | `CourierCrypto` + AES-GCM archive | ✅ Implemented |
| Immutable anchoring | `chain_tx_hash` → Polygonscan link on certificate | ✅ Live mainnet path ([[Polygon_Mainnet_Wiring_2026-05]]) |
| Download gates | `download_count < max_downloads`, `is_bricked`, `expires_at` | ✅ In `attempt_courier_unlock` (`20260524120000_courier_download_limits.sql`) |
| Separate `authorize_courier_download` RPC | Framework names explicit RPC | ⚠️ Logic inlined in `attempt_courier_unlock` — functionally OK |
| `PLOCK_VERIFIED_V1` magic token | Framework names password integrity token | ⚠️ Not found in `courier_crypto.dart` — uses SHA-256 verify path instead |
| Certificate structure | Asset hash, tx hash, Polygonscan link, metadata | ✅ PDF matches |
| No in-app email | Utility positioning | ✅ Share sheet only; UI copy explicit |

### 7.1 Critical infrastructure blocker: `WEB_VAULT_BASE_URL`

Current compile-time binding (local sync output):

```
WEB_VAULT_BASE_URL = https://credibly-mayday-overjoyed.ngrok-free.dev
```

(source: `dart_defines.json` / `generated_dart_defines.dart` — gitignored locally but present in dev builds)

| Environment rule | Status |
|------------------|--------|
| Ephemeral tunnel for QA | ✅ Per `ephemeral-environments.mdc` |
| **Release / App Store build** | ❌ Must use **permanent HTTPS origin** |
| Release rejects localhost | ✅ Enforced in `vault_service_io.dart` |

**Impact:** Send Proof generates courier URLs pointing at Ngrok. When the tunnel stops, reviewers and users get broken links → **Guideline 2.1** functional failure if Send Proof is advertised in metadata or demonstrated in review notes.

Per [[Send_Proof_Courier_2026-05]]: recipient E2E is **intentionally parked** until a public web archive exists. For App Store submission you must either:

1. **Deploy** the Flutter Web courier unlock app to a stable HTTPS host and rebuild with that `WEB_VAULT_BASE_URL`, **or**
2. **Scope the v1 submission** to capture/archive/certificate export only and ensure App Store metadata/screenshots do not promise working recipient unlock until the web archive ships (still risky if Send Proof is reachable in-app).

**Verdict:** ❌ **BLOCKER** for any submission that exposes Send Proof to review.

---

## 8. Content Safety & Age Rating (2026 §4)

| Factor | FactLockCam |
|--------|-------------|
| User-generated content | User captures photos/video **locally**; no in-app social feed |
| Content moderation | **Implemented (2026-06-05)** — `report_courier_package` / `block_courier_sender` on `CourierUnlockView`; async `courier-content-scan`; no in-app social feed |
| Medical / violent themes | None |
| Creator app age-gate (1.2.1(a)) | **Not implemented** |

**Connect action required:** Complete Apple’s updated age-rating questionnaire (**deadline: 2026-01-31** per framework). Likely rating **4+** or **12+** depending on how "forensic capture" questions are answered — no in-app community UGC reduces complexity.

Recommend answering honestly: content creation yes, user-to-user sharing only via **system share sheet** (out of app), no moderated public feed.

**Verdict:** ⚠️ **Connect-side action required** — not a code blocker unless Apple assigns 13+/16+ and mandates age-gate UI.

---

## 9. Metadata & ASO (2026 §6)

Code audit cannot verify App Store Connect fields. Pre-submission checklist:

| Field | Limit | FactLockCam guidance |
|-------|-------|---------------------|
| App Name | 30 chars | `FactLockCam` or `FactLockCam: Secure Archive` |
| Subtitle | 30 chars | Legal-approved: `Private Archive · Proof` or `Verifiable Proof Archive` |
| Keywords | 100 chars | Singular, comma-separated, no spaces — e.g. `archive,proof,privacy,certificate,ledger` |
| Description | Not indexed on iOS | Use full **Engineered Strategic Pitch** (private archive, Digital DNA, zero-knowledge keys, tamper-proof certificate, global ledger). Consumer conversion copy — **omit FRE 902** from description; procedural detail stays in Terms only. |
| Promotional text | 170 chars | `Absolute privacy. Undeniable proof.` |
| Screenshots | Caption text indexed since mid-2025 | Digital DNA, only you hold the keys, tamper-proof certificate — avoid generic "Fast App" |

**Banned terms (from ProofLock memory-bank):** avoid "Ghost Key" and absolute anti-deepfake claims in UI and metadata.

---

## 10. Build, Test & Release Orchestration (2026 §7)

### 10.1 Build command (from `docs/app_store_submission_checklist.md`)

```bash
cd factlockcam_app
flutter pub get
flutter test
flutter build ipa --release --dart-define-from-file=dart_defines.json
```

**Pre-build overrides for submission:**

```bash
# Replace with production values — never ship Ngrok in App Store builds
flutter build ipa --release \
  --dart-define-from-file=dart_defines.json \
  --dart-define=WEB_VAULT_BASE_URL=https://YOUR-PERMANENT-VAULT-HOST
```

### 10.2 Test results (2026-05-23)

```
flutter test → 26 passed, 9 failed
```

Failures cluster in `widget_test.dart` (`MissingPluginException` for `path_provider` in unit-test harness). Core domain tests (journal WAL recovery, cipher roundtrip, archive actions) pass. ProofLock’s audit did not gate on unit tests, but fixing or skipping the DI-heavy widget smoke test reduces release risk.

### 10.3 Manual QA (required — same as ProofLock torture checklist)

From `docs/app_store_submission_checklist.md`:

1. Seal large photo/video → background app during overlay → relaunch → no broken thumbnails.
2. Optional: `integration_test/asset_lock_torture_test.dart` on physical device.

### 10.4 IPv6 / networking

| Check | Result |
|-------|--------|
| Production Supabase URL | `https://*.supabase.co` ✅ |
| Hardcoded IPv4 API endpoints in release path | Debug-only `127.0.0.1:54325` for local web ✅ |
| Polygon RPC | Alchemy HTTPS URL ✅ |

ProofLock validated IPv6 via env rejection logic; FactLockCam uses the same hosted-Supabase pattern.

### 10.5 Low-level ARM64 items (2026 §7)

Framework mentions register x18, DIT for crypto, variadic ABI. These apply primarily to native/C/crypto code paths. FactLockCam’s hot crypto runs in Dart isolates (`Isolate.run`) — no custom native crypto module audited. **No action** unless adding native Secure Enclave signing ([[ProofLock_Refactor_Scope]]).

---

## 11. ProofLock_production — What Passed & What to Reuse

ProofLock’s submission playbook (`ProofLock_production/APP_STORE_READINESS_AUDIT.md`, `memory-bank/appStoreApproval.md`, `tools/audit_submission_readiness.sh`) established these **zero-blocker** pillars:

1. Privacy manifest with all required-reason APIs  
2. Specific permission strings  
3. No social auth → no Apple Sign In  
4. StoreKit-only payments (N/A for FactLockCam)  
5. No hardcoded IPv4 production URLs  

FactLockCam **matches or exceeds** ProofLock on items 2–5 and account deletion. Gaps vs the passing ProofLock binary:

| ProofLock artifact | Reuse for FactLockCam |
|--------------------|----------------------|
| `DiskSpace` / E174.1 in manifest | **Copy back** |
| `ITSAppUsesNonExemptEncryption` = NO | **Add** |
| `audit_submission_readiness.sh` | Port to `factlockcam_app/tools/` and run pre-upload |
| App Review notes template | Adapt below |
| IAP disclaimer block (`MissionPricingModal`) | **Skip** — no subscriptions |

---

## 12. Prioritized Remediation Roadmap

### P0 — Submission blockers (fix before upload)

| # | Item | Owner | Effort |
|---|------|-------|--------|
| 1 | Deploy **permanent HTTPS web archive**; set `WEB_VAULT_BASE_URL` in release build | Infra | 1–2 days |
| 2 | Publish live **support URL** (`factlockcam.com/support` or working alternative) | Web | Hours |
| 3 | Update `PrivacyInfo.xcprivacy`: **DiskSpace**, **Email**, **Precise Location** | iOS | 1 hour |
| 4 | Align **App Store Connect App Privacy** labels with manifest | Connect | 30 min |
| 5 | Add `ITSAppUsesNonExemptEncryption` = `NO` to Info.plist (if eligible) | iOS | 5 min |
| 6 | Complete **2026 age-rating questionnaire** in App Store Connect | Connect | 30 min |

### P1 — High-confidence improvements (reduce rejection probability)

| # | Item | Notes |
|---|------|-------|
| 7 | Run Xcode **Privacy Report** on release archive | Catches SDK manifest gaps |
| 8 | E2E Send Proof test on TestFlight build against production archive URL | Reviewer path |
| 9 | Strengthen camera permission copy (encryption + archive context) | Match ProofLock specificity |
| 10 | Fix or quarantine failing `widget_test.dart` DI smoke test | CI hygiene |
| 11 | Prepare demo account + review notes (below) | Reviewer experience |

### P2 — Post-v1 / optional

| # | Item |
|---|------|
| 12 | Port `audit_submission_readiness.sh` to FactLockCam repo |
| 13 | Hardware-backed signing before marketing "device-bound proof" |
| 14 | Age-gate UI if Connect assigns 13+ with creator-app flags |
| 15 | ASO cross-localization keyword strategy (2026 §6) |

---

## 13. App Store Connect Checklist

Use this immediately before clicking **Submit for Review**:

### Binary & build
- [ ] Version `1.0.0+1` (or bumped) matches Connect record
- [ ] Release IPA built with **production** `SUPABASE_URL`, **non-Ngrok** `WEB_VAULT_BASE_URL`
- [ ] Privacy manifest updated and included in archive
- [ ] Upload via Transporter / Xcode Organizer

### App Privacy (nutrition labels)
- [ ] Photos/Videos — App Functionality, Linked to Identity
- [ ] User ID — App Functionality, Linked to Identity
- [ ] **Email Address** — App Functionality, Linked to Identity
- [ ] **Precise Location** — App Functionality (if still collected on HUD)
- [ ] Tracking — **No**

### Export compliance
- [ ] Answer encryption questions; consistent with `ITSAppUsesNonExemptEncryption`

### Age rating
- [ ] 2026 questionnaire complete (deadline 2026-01-31)

### Review information (suggested text — adapt from ProofLock pattern)

```
Demo account:
  Email: reviewer@YOUR-DOMAIN.com
  Auth: Request Magic Number via login screen; OTP is logged in Supabase Auth dashboard
        OR pre-provision a fixed test OTP window for review week.

Core flows to test:
  1. Login → Hub → Picture → capture photo → wait for "Generating Proof…" → Archive shows sealed item.
  2. Open item → View Full → decrypts locally.
  3. Send Proof → set password → share sheet delivers PDF + https://YOUR-VAULT-HOST/courier?pkg=…
  4. Open courier link in Safari → enter password → media unlocks (requires live web archive).
  5. Account → Burn account → double confirm → account deleted.

Notes:
  - FactLockCam is a utility: it does NOT send email in-app; sharing uses the iOS share sheet.
  - Blockchain notarization uses Polygon mainnet; certificate PDF links to polygonscan.com.
  - Location permission is optional; used only for GPS overlay on camera HUD.
  - No in-app purchases.
```

### Metadata
- [ ] Support URL resolves
- [ ] Privacy Policy URL (can reference in-app bundled policy + optional web mirror)
- [ ] Screenshots with indexed caption text per 2026 ASO guidance
- [ ] No "absolute proof of truth" or banned terminology

---

## 14. Summary Scorecard

| Pillar (2026 framework) | Status | Notes |
|-------------------------|--------|-------|
| §2 Privacy manifest | ⚠️ | Missing DiskSpace + email/location collected types |
| §3 SDK / AI governance | ✅ | No AI providers; policy documented |
| §4 Age rating | ⚠️ | Connect questionnaire pending |
| §5 Secure media SAGA | ⚠️ | Code OK; **web archive host blocker** |
| §6 Metadata / ASO | ⚠️ | Connect-side — not verified |
| §7 Release orchestration | ⚠️ | Tests partially failing; manual QA required |
| Guideline 5.1.1 Privacy | ⚠️ | Support URL dead; manifest drift |
| Guideline 5.1.1(v) Account deletion | ✅ | Double confirm + RPC |
| Guideline 4.8 Auth parity | ✅ | Email OTP only |
| Guideline 3.1.1 Payments | ✅ | No IAP |
| Legal / FRE 902 framing | ✅ | Stronger than ProofLock |
| ProofLock parity overall | ⚠️ | 3 infra/manifest gaps remain |

---

## 15. Conclusion

FactLockCam is **architecturally aligned** with the compliance patterns that cleared ProofLock for the App Store: privacy manifest present, honest permission scope, no social auth, no external payments, bundled legal docs, and robust account deletion. The product also meets 2026 **AI transparency** expectations by construction.

Submission should wait until **production web archive hosting**, a **live support page**, and **privacy manifest / Connect label alignment** (email, location, disk space) are complete. With those P0 items resolved and a TestFlight Send Proof smoke test against the permanent archive URL, FactLockCam should reach parity with ProofLock’s Feb 2025 **zero critical blocker** audit posture.

---

*End of report.*

**References:**  
- `2026 App Store Compliance & Governance Framework.md` (audit standard)  
- `ProofLock_production/APP_STORE_READINESS_AUDIT.md`, `PRIVACY_PERMISSIONS_AUDIT.md`, `memory-bank/appStoreApproval.md`  
- `wiki/concepts/App_Store_Prep_Capture_Seal_2026-05.md`, `wiki/analyses/Send_Proof_Courier_2026-05.md`, `wiki/concepts/FactLockCam_Product_Baseline_2026-05.md`  
- `docs/app_store_submission_checklist.md`

# Master Context — 13 MAY 2026

The comprehensive **schema-first** architecture snapshot lives in the LLM Wiki:

**[`wiki/analyses/MASTER_CONTEXT13MAY2026.md`](wiki/analyses/MASTER_CONTEXT13MAY2026.md)**

That page supersedes the 2026-05-11 master context (`wiki/analyses/Master_Context_11MAY2026.md`); for product workflow and hosted Supabase repair narrative, continue to anchor on `wiki/concepts/SnapSeal_Product_Baseline_2026-05.md` and `wiki/analyses/Project_Audit_2026-05-11.md`.

**Verified on 2026-05-13:** `flutter test` in `snapseal_app/` — 31 passing tests across nine files under `snapseal_app/test/`.
2026-05-13 Architecture Pivot: The Cloud E2EE Vault & Web Verification
1. The Core Paradigm Shift: Local Sandbox to Cloud E2EE
To eliminate the catastrophic data-loss vulnerability caused by app uninstallations and to remove the friction of forced app downloads for recipients, ProofLock is transitioning from a purely local storage model to a Cloud-Assisted End-to-End Encrypted (E2EE) Vault hosted on Supabase.

Zero-Knowledge Maintained: The client app encrypts all assets locally (AES-GCM) using a master key before uploading. Supabase only stores blind, encrypted blobs and metadata. Strict Data Sovereignty is traded for bulletproof state recovery and frictionless sharing.

2. The Web Courier & Polygonscan Offload
The legacy password-protected local courier file (.plock) is deprecated in favor of a zero-install Web Verification Portal.

Mechanism: Senders generate a secure URL and a one-time password out-of-band.

Client-Side Processing: The web portal fetches the encrypted blob from Supabase and decrypts it entirely in-memory using the browser's WebCrypto API. The server never sees the password or the decrypted asset.

Ledger Validation: The web portal calculates the SHA-256 hash locally and presents a direct hyperlink to the Polygonscan block explorer (https://polygonscan.com/tx/{hash}) for immutable timestamp verification, removing the need for a custom Web3 RPC integration.

3. Infrastructure Economics & Subscription Tiers
To protect gross margins against Supabase’s operational costs (Storage: $0.021/GB, Egress: $0.09/GB), user capacity is strictly metered via media-typed subscription tiers designed to offset the "Viral Multiplier" (bandwidth consumed by multiple recipient downloads).

Free Tier ("Zero-Trust Tourist"): * Capacity: 50 MB Vault Limit.

Egress: 3 Courier downloads per month.

Purpose: Lead generation; single-document proof.

Picture Tier ("The Creator"):

Pricing: $1.00 / month.

Capacity: 5 GB Vault Limit.

Egress: 25 GB downloads per month.

Purpose: High-volume, low-weight image securing; builds user habit.

Video Tier ("The Archivist"):

Pricing: $10.00 / month.

Capacity: 50 GB Vault Limit.

Egress: 200 GB downloads per month.

Purpose: Underwrites the heavy infrastructure costs of video processing and playback.

4. Client Application Imperatives (UI/UX)

Quota Telemetry: The primary Vault UI must feature a prominent dashboard tracking both Storage GBs used and Egress capacity remaining.

Proactive Alerts: Implement hard-coded UI warnings at 80% and 95% threshold capacities.

Graceful Degradation: If a shared link exceeds its monthly egress quota, the recipient is shown a polite "Verification Limit Reached" message, while the sender receives an upsell prompt to upgrade their tier.
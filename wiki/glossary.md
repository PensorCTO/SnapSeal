---
tags: [glossary, terminology, llm_wiki]
summary: "Terminology reference for the LLM Wiki."
---

# Glossary

## Terms

| Term | Definition | Related Notes |
| :--- | :--- | :--- |
| LLM Wiki | A Markdown knowledge base maintained by an LLM from immutable raw sources. | [[LLM_Wiki_Pattern]] |
| Raw Source | Original input material stored in `raw/` and treated as immutable. | [[Sample_Source]] |
| Compiled Wiki | Durable synthesized knowledge stored under `wiki/`. | [[LLM_Wiki_Pattern]] |
| Provenance | Explicit source tracking for important claims. | [[Sample_Source]] |
| SnapSeal | Flutter mathematical certainty wallet for sealing and verifying captured media. | [[SnapSeal_Master_Blueprint]] |
| Active-Wallet Ledger | Supabase replica of proof rows for assets still connected to active app wallets. | [[SnapSeal_Master_Blueprint]] |
| Pending Sync | Local SQLite state marking a sealed asset whose Supabase ledger insert has not completed. | [[SnapSeal_Master_Blueprint]] |
| Courier Payload | Service-layer export of decrypted media after SHA-256 re-verification. | [[SnapSeal_Master_Blueprint]] |
| ProofLock (manifest) | Target architecture and viability bar: TEE-backed signing, Polygon, C2PA, RPC-first ledger/courier; ingested as a wiki source. | [[ProofLock_Architectural_Manifest]] |
| ProofLock refactor scope | Analysis mapping manifest requirements to current SnapSeal code with phased effort estimates. | [[ProofLock_Refactor_Scope]] |
| Magic Number (auth) | Supabase email OTP flow using a 6-digit code (`OtpType.email`) in the SnapSeal logon UI. | [[SnapSeal_Master_Blueprint]] |
| Hardware-backed proof signing | Native Secure Enclave / Keystore signing of (or binding to) content hashes; mandated by the ProofLock manifest for spoofing resistance. | [[ProofLock_Architectural_Manifest]] |

## Provenance Tracking

* *Initial terminology*: Derived from `raw/sample_llm_wiki_source.md` (2026-04-26)
* *SnapSeal application terminology*: Derived from `wiki/analyses/SnapSeal_Master_Blueprint.md` (2026-04-30; updated 2026-05-03)
* *ProofLock terminology*: Derived from `wiki/sources/ProofLock_Architectural_Manifest.md` and `wiki/analyses/ProofLock_Refactor_Scope.md` (2026-05-03)

## Related Notes

* [[LLM_Wiki_Pattern]]
* [[SnapSeal_Master_Blueprint]]
* [[ProofLock_Architectural_Manifest]]
* [[ProofLock_Refactor_Scope]]

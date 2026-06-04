---
tags: [analysis, factlockcam, backlog, institution, mime]
summary: "Deferred work to enable MIME-agnostic file sealing in the institution-grade app; consumer FactLockCam remains picture and video only."
---

# Institution-Grade Payload Seal Backlog

## Core Synthesis

Consumer **FactLockCam** (Pre-Connect baseline) intentionally ships **camera capture only** — Picture and Video hub tiles, no "Seal File" import UX. A **foundation pass (2026-06-04)** added schema and Dart contracts so a separate institution-grade app can enable arbitrary payloads without another destructive Supabase repair.

### Foundation landed (consumer repo)

| Layer | Artifact |
|-------|----------|
| Postgres | `courier_packages.content_mime_type`, `content_category`; extended `get_or_create_courier_package`, `attempt_courier_unlock` |
| Storage | `courier-blobs` `allowed_mime_types` → `application/octet-stream` only |
| Dart | `ArchiveContentCategory`, `mime_extension_map.dart`, `ArchiveIngressPort` / `FileArchiveIngress` stub |
| Flag | `ENABLE_ARBITRARY_FILE_SEAL=false` (default) |

Consumer Send Proof populates `image` / `video` categories from `ArchiveItem.mimeType` only.

### Institution-grade app — enable when ready

1. Set `ENABLE_ARBITRARY_FILE_SEAL=true` and implement `FileArchiveIngress` (iOS `UIDocumentPicker`, optional `file_picker` on Android).
2. Relax `_persistSealedBytes` thumbnail requirement for non-image/video; glyph thumbnails in chronology.
3. Archive inspector / omni: non-media viewers (already sketched in `AssetActionRegistry` for document/audio/binary).
4. Info.plist / App Privacy review for document and optional photo-library import.
5. Web courier recipient UX using `content_mime_type` from unlock RPC.

Do **not** add "any file type" to consumer marketing ([[FactLockCam_Product_Baseline_2026-05]], `marketingBanList`).

## Provenance Tracking

* *Product decision*: User direction 2026-06-04 — simplicity for App Store consumer app; institution app later.
* *Migrations*: `supabase/migrations/20260604120000_courier_payload_metadata_foundation.sql`, `20260604130000_courier_bucket_octet_stream_only.sql`

## Related Notes

* [[FactLockCam_Product_Baseline_2026-05]]
* [[Send_Proof_Courier_2026-05]]
* [[Archive_Subscription_Tiers_2026]]

# Skill: Unified Archive Studio & Secure Comm Decommission

## Description
A comprehensive procedural toolkit to decommission the unauthenticated "Secure Comm" network paths, restore the canonical 4-button hub, and transform the "Print Certificate" action into an interactive, local-first Live Certificate Studio.

## Instructions
1. **Hub Restoration:** Remove the "Secure Comm" tile/tab from `HapticHubPanel` and revert to the baseline 4-button topology (Picture, Video, Archive, Account).
2. **Action Sheet Purge:** Modify `UniversalAssetToolbar` and `ArchiveItemActions` to completely remove `MediaActionType.share` / "Send Proof". Allowed actions are strictly: View, Delete, Download Asset (local decrypted copy), and Print Certificate.
3. **Local Metadata Extension:** Ensure the local SQLite `archive_items` table and Dart data models can store and update `title` and `description` locally. Do NOT modify Supabase syncing logic for these fields; they are strictly local embellishments.
4. **Live Certificate Studio:** * Implement `CertificateStudioView` using the `pdf` and `printing` packages.
    * Bind local metadata (Title/Description) to a Riverpod state controller.
    * Build `CertificatePdfCompiler` to generate a professional PDF featuring: App Branding, Polygon Hash, Timestamp, Media Thumbnail, and the local Title/Description.
    * Stream the compiled PDF bytes to a `PdfPreview` widget for real-time updates as the user types.
    * Use the native iOS/Android share sheet to export the finalized PDF.
5. **Lexicon Compliance:** Ensure all updated paths, variables, and UI text strictly utilize the term "Archive" instead of "Vault".
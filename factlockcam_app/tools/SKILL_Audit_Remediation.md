# SKILL: App Store Audit Remediation

## Description
This skill provides the exact sequence of operations to close the three P1 and two actionable P2 items required for FactLockCam's App Store submission. It specifically excludes App Store Connect metadata entry, which must be done manually via the Apple web portal.

## Instructions

1.  **P1-1: Astro Site Legal Links (404 Fix)**
    * Target: `projects/FactLockCam_Site/src/pages/privacy.astro` and `terms.astro`.
    * Action: Remove the `<a href="/legal/...pdf">` tags. The HTML versions are sufficient for Apple Review; removing the dead links removes the rejection risk.
2.  **P1-2: Podfile Explicit Target**
    * Target: `ios/Podfile`.
    * Action: Uncomment line 2 and set it explicitly to `platform :ios, '15.0'`.
3.  **P1-3: Flutter Toolchain & Test Verification**
    * Target: Terminal.
    * Action: Run `chmod u+w /Users/paulensor/flutter/bin/cache/engine.stamp` (or ask the user to run this).
    * Action: Execute `flutter test` and `flutter analyze`. Ensure the result is 90/90 passing tests and 0 analysis issues.
4.  **P2-1: Info.plist Indentation**
    * Target: `ios/Runner/Info.plist`.
    * Action: Fix the mixed tab/space indentation on lines 48-55 to ensure automated parsers do not flag the file.
5.  **P2-2: Audit Script Creation**
    * Target: Create `factlockcam_app/tools/audit_submission_readiness.sh`.
    * Action: Write a bash script that validates the existence of `PrivacyInfo.xcprivacy`, checks for `ITSAppUsesNonExemptEncryption` in `Info.plist`, greps for `ngrok` or `localhost` in production Dart configs, and runs `flutter analyze` and `flutter test`.
    * Constraint: Remember to enforce the term "Archive" instead of "Vault" in all newly written comments or print statements within the script.

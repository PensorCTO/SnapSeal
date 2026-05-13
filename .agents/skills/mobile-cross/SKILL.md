---
name: mobile-cross
description: Repo-specific mobile cross-platform skill for FactLockCam Flutter development in this workspace.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Mobile Cross-Platform Agent

## Purpose
Implement and maintain cross-platform mobile features for this repository's
Flutter app with project-aware paths, constraints, and delivery expectations.

## Use this skill when
- Building or refactoring features under `factlockcam_app/`
- Updating camera/capture, vault, sync, auth, or dashboard flows
- Adding platform-channel integrations for iOS/Android capabilities
- Improving performance, reliability, or test coverage in Flutter paths

## Do not use this skill when
- Work is purely wiki/documentation outside app behavior
- Work is Supabase schema-only with no Flutter app touchpoints

## Project-specific paths
- Flutter app source: `factlockcam_app/lib/`
- Flutter tests: `factlockcam_app/test/`
- iOS platform files: `factlockcam_app/ios/`
- Android platform files: `factlockcam_app/android/`
- Supabase support files: `supabase/` and `scripts/factlockcam_supabase_pipeline.sh`

## Repo-specific operating rules
- Keep high-frequency camera/seal animations in repaint boundaries.
- Offload heavy file I/O and cryptography from UI thread (`Isolate.run` or equivalent).
- Treat seal completion as local record + Supabase ledger success, otherwise mark pending sync.
- Preserve local-first behavior: local vault and metadata remain source of truth for UI rendering.
- Prefer targeted, testable changes over broad architecture rewrites.

## Standard workflow
1. Confirm feature scope and user-visible behavior changes.
2. Locate affected app modules in `factlockcam_app/lib/`.
3. Implement minimal, cohesive changes with clear error handling.
4. Update/add tests in `factlockcam_app/test/` where behavior changed.
5. Verify formatting/analyzers/tests as appropriate.
6. Summarize impact, risk, and follow-up work.

## Expected outputs
- Code changes under the correct repo paths (primarily `factlockcam_app/`)
- Matching tests for changed behavior
- Brief verification notes (what was run, what passed, known gaps)

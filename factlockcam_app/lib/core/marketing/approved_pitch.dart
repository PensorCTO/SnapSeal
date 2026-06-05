/// Consumer marketing copy — defensive architectural matrix (2026).
///
/// Keep in sync with projects/FactLockCam_Site/src/copy/marketing.ts
///
/// Do not use FRE 902 on consumer sales surfaces. Certificate PDFs and evidence
/// bundles still require [fre902EvidencePackagingDisclaimer].
library;

/// Phrases that must not appear on consumer marketing surfaces.
const List<String> marketingBanList = [
  'Your personal history',
  'completely safe from modification',
  'Permanently authenticated',
  'Lens-to-cloud',
  'unbreakable',
  'flawless',
  'indefinite security',
  'mathematical certainty',
  'absolute anti-deepfake',
  'Absolute privacy',
  'Undeniable truth',
];

/// Short page / store headline fragment.
const String mechanismHeadline =
    'Private, tamper-evident media archive — sovereign zero-knowledge local lock';

/// Full consumer pitch (benefit-first, no perfection guarantees).
const String consumerMechanismPitch =
    'FactLockCam turns your phone into a private, tamper-evident media archive. '
    'The moment you capture, the app seals media with verified Digital DNA on your device. '
    'Only you hold the keys—we cannot access your unencrypted files. '
    'When you need to show what was captured, generate a tamper-proof certificate '
    'anchored to an independent global public ledger. '
    'Built so you do not have to trust us: sovereign, local-first architecture and '
    'proof on an independent public record others can verify. '
    'Sovereign keys. Verifiable seal.';

/// Closing tagline (consumer surfaces).
const String mechanismTagline = 'Sovereign keys. Verifiable seal.';

/// Logon screen helper (below logo).
const String logonPitchFragment =
    'Sovereign zero-knowledge local lock—only you hold the keys. '
    'Authenticate with a 6-digit Magic Number.';

const String archiveHubSubtitle =
    'Verified Digital DNA · sealed on this device';

/// Consumer epistemic boundary (keep in sync with marketing.ts whyBody / trustDisclaimer).
const String consumerEpistemicLine =
    'Cryptographic snapshot and verifiable chain-of-custody for the file—not '
    'physical truth of the scene.';

const String certificatePdfSubtitle =
    'Tamper-proof certificate · independent global public ledger';

const String sendProofShareIntro =
    'FactLockCam verifiable proof package\n\n'
    'Tamper-proof certificate attached. Secure media link:\n';

/// Unauthenticated web courier unlock console headline.
const String courierConsoleHeadline = 'Secure Communications Console';

/// Subcopy on the courier gate (recipient unlock surface).
const String courierConsoleGateSubtitle =
    'Unlock and verify an encrypted Archive package locally in this browser.';

/// Viral loop overlay pitch (post-playback CTA).
const String courierConsoleViralPitch =
    'Sovereign zero-knowledge local lock. Capture, seal, and share verifiable proof '
    'from your device.';

/// One-line package description (pubspec / manifest).
const String packageDescription =
    'Private, tamper-evident media archive with verified Digital DNA at capture and tamper-proof certificates on an independent global public ledger.';

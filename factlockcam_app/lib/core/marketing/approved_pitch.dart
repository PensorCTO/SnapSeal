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
    'Your private vault — sovereign zero-knowledge local lock';

/// Full consumer pitch (mechanism-forward, no perfection guarantees).
const String consumerMechanismPitch =
    'FactLockCam is your private vault with a sovereign zero-knowledge local lock. '
    'The moment you capture, we seal media on-device with verified Digital DNA: '
    'SHA-256 fingerprint, AES-GCM encryption, and a transactional journal that records '
    'prepare/commit integrity on your device. Only you hold the keys—we cannot access '
    'your unencrypted files. When you need to show what was captured, generate a '
    'tamper-proof certificate anchored to an independent global public ledger. '
    'Sovereign keys. Verifiable seal.';

/// Closing tagline (consumer surfaces).
const String mechanismTagline = 'Sovereign keys. Verifiable seal.';

/// Logon screen helper (below logo).
const String logonPitchFragment =
    'Sovereign zero-knowledge local lock—only you hold the keys. '
    'Authenticate with a 6-digit Magic Number.';

const String archiveHubSubtitle =
    'Verified Digital DNA · sealed on this device';

const String certificatePdfSubtitle =
    'Tamper-proof certificate · independent global public ledger';

const String sendProofShareIntro =
    'FactLockCam verifiable proof package\n\n'
    'Tamper-proof certificate attached. Secure media link:\n';

/// One-line package description (pubspec / manifest).
const String packageDescription =
    'Private vault with sovereign zero-knowledge local lock, verified Digital DNA on capture, and tamper-proof certificates.';

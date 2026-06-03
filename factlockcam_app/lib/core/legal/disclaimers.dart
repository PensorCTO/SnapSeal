/// Legal framing for exported certificates, evidence packs, and in-app compliance.
/// Use verbatim when implementing PDF, share-sheet, or UI disclosure surfaces.
library;

/// FRE 902 — certificate PDFs and evidence bundles only (not consumer homepage).
const String fre902EvidencePackagingDisclaimer =
    'This document supports workflow and disclosure but does not guarantee '
    'admissibility under FRE 902.';

/// HUD / hub one-liner.
const String epistemicIntegrityShort =
    'Seals cryptographic snapshot integrity—not physical truth of the scene.';

/// Certifies capture-file integrity, not physical truth of the scene photographed.
const String epistemicIntegrityDisclaimer =
    'FactLockCam certifies the integrity of the captured file (cryptographic '
    'snapshot and verifiable chain-of-custody)—not the physical truth of the '
    'event shown in the image or video.';

/// Zero-knowledge key custody — company cannot recover lost archives.
const String sovereignKeyCustodyDisclaimer =
    'You hold the only keys that decrypt your archive. FactLockCam cannot access '
    'your unencrypted files, reset your private keys, or recover lost archives '
    'if you lose your device keys or .factlock backup. Burning your account '
    'permanently destroys that identity and its cloud data—a prior .factlock '
    'cannot restore a burned account.';

/// Keys-only backup — not media from Supabase.
const String keyBackupOnlyDisclaimer =
    'The only backup you can create is a .factlock file (Export archive keys). '
    'It contains your private decryption keys—not your photos or videos, and '
    'not files downloaded from our servers.';

/// Lock, uninstall, Burn, and key-loss outcomes (consumer summary).
const String keyCustodyScenarioSummary =
    'Losing your keys without a .factlock backup means permanent loss of access '
    'to all encrypted assets, local and cloud. Lock removes keys from this device '
    'but keeps local sealed files—import .factlock to unlock. Reinstalling the app '
    'removes local keys; sign in and import .factlock to read cloud ciphertext again. '
    'Burn Account deletes your account, cloud archive, and local keys—a .factlock '
    'from before Burn cannot restore that account. Re-export .factlock periodically '
    'or before Lock, reinstall, or device replacement.';

/// Burn account — irreversible destruction.
const String burnAccountDisclaimer =
    'Burn Account permanently deletes your Supabase identity, linked cloud '
    'ciphertext, local archive files, and cryptographic keys on this device. '
    'A .factlock backup cannot resurrect a burned account or its cloud archive.';

/// Polygon mainnet / relay — no uptime or gas SLA.
const String polygonNetworkDisclaimer =
    'Optional ledger notarization uses Polygon mainnet and a relay service. '
    'FactLockCam does not guarantee network uptime, transaction speed, gas prices, '
    'or receipt timing—outages and delays may occur.';

/// Native hardware signing when enabled (not web capture).
const String hardwareCapabilityDisclaimer =
    'On supported iOS and Android devices, capture sealing may use hardware-backed '
    'signing (Secure Enclave or Keystore). Web and simulator builds do not '
    'originate device seals.';

/// Subscription tiers — bandwidth only; no key recovery or escrow.
const String archiveSubscriptionTierDisclaimer =
    'Higher tiers provide larger bandwidth pipelines, but zero data recovery. '
    'FactLockCam cannot restore lost keys or decrypt your archive.';

/// Restore / brick screen — non-recovery emphasis.
const String restoreKeyCustodyDisclaimer =
    'Without your .factlock backup and backup password, FactLockCam cannot '
    'restore cryptographic keys or decrypt your archive on this device. '
    'After reinstall, sign in with the same email, then import .factlock here.';

/// Export keys dialog helper.
const String exportArchiveKeysDisclaimer =
    '$keyBackupOnlyDisclaimer Re-export after Lock, before uninstall or device '
    'replacement, or periodically.';

/// Short logon footnote combining epistemic + key custody.
const String logonComplianceFootnote =
    '$epistemicIntegrityDisclaimer $sovereignKeyCustodyDisclaimer';

/// First-run onboarding: epistemic + custody + scenarios + subscription limits.
const List<String> archiveOnboardingParagraphs = [
  epistemicIntegrityDisclaimer,
  sovereignKeyCustodyDisclaimer,
  keyCustodyScenarioSummary,
  archiveSubscriptionTierDisclaimer,
];

/// Lock Archive confirmation (keys purged; local seals remain).
const String lockArchiveDisclaimer =
    'Lock Archive removes your cryptographic keys from this device. '
    'Local sealed files remain. Import your .factlock backup and password '
    'to unlock the app again. Cloud data for your account is unchanged.\n\n'
    '$restoreKeyCustodyDisclaimer';

/// Account panel block — key custody, epistemic, Polygon, scenarios.
const String accountKeyCustodyBlock =
    'KEY CUSTODY & LIMITS\n\n'
    '$keyBackupOnlyDisclaimer\n\n'
    '$keyCustodyScenarioSummary\n\n'
    '$epistemicIntegrityDisclaimer\n\n'
    '$polygonNetworkDisclaimer';

/// Certificate PDF footer (consumer-safe, no FRE on every line).
const String certificateEpistemicFooter =
    '$epistemicIntegrityDisclaimer $polygonNetworkDisclaimer';

/// Curated strings scanned by [marketing_compliance_test] for banned phrases.
const List<String> userVisibleComplianceStrings = [
  fre902EvidencePackagingDisclaimer,
  epistemicIntegrityShort,
  epistemicIntegrityDisclaimer,
  sovereignKeyCustodyDisclaimer,
  keyBackupOnlyDisclaimer,
  keyCustodyScenarioSummary,
  burnAccountDisclaimer,
  polygonNetworkDisclaimer,
  hardwareCapabilityDisclaimer,
  logonComplianceFootnote,
  accountKeyCustodyBlock,
  restoreKeyCustodyDisclaimer,
  exportArchiveKeysDisclaimer,
  archiveSubscriptionTierDisclaimer,
  lockArchiveDisclaimer,
  certificateEpistemicFooter,
];

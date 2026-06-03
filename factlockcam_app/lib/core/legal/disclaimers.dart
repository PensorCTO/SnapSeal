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
    'if you lose your device keys or .factlock backup.';

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

/// Short logon footnote combining epistemic + key custody.
const String logonComplianceFootnote =
    '$epistemicIntegrityDisclaimer $sovereignKeyCustodyDisclaimer';

/// Account panel block — key custody, epistemic, Polygon.
const String accountKeyCustodyBlock =
    'KEY CUSTODY & LIMITS\n\n'
    '$sovereignKeyCustodyDisclaimer\n\n'
    '$epistemicIntegrityDisclaimer\n\n'
    '$polygonNetworkDisclaimer';

/// Restore / brick screen — non-recovery emphasis.
const String restoreKeyCustodyDisclaimer =
    'Without your .factlock backup and backup password, FactLockCam cannot '
    'restore cryptographic keys or decrypt your archive on this device.';

/// Certificate PDF footer (consumer-safe, no FRE on every line).
const String certificateEpistemicFooter =
    '$epistemicIntegrityDisclaimer $polygonNetworkDisclaimer';

/// Curated strings scanned by [marketing_compliance_test] for banned phrases.
const List<String> userVisibleComplianceStrings = [
  fre902EvidencePackagingDisclaimer,
  epistemicIntegrityShort,
  epistemicIntegrityDisclaimer,
  sovereignKeyCustodyDisclaimer,
  polygonNetworkDisclaimer,
  hardwareCapabilityDisclaimer,
  logonComplianceFootnote,
  accountKeyCustodyBlock,
  restoreKeyCustodyDisclaimer,
  certificateEpistemicFooter,
];

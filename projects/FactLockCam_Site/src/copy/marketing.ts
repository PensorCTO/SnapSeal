/**
 * Consumer marketing copy — defensive architectural matrix.
 * Keep in sync with factlockcam_app/lib/core/marketing/approved_pitch.dart
 */

export const marketingBanList = [
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
] as const;

export const pageTitle = 'FactLockCam — Tamper-Evident Media Archive & Verifiable Proof';

export const metaDescription =
  'Turn your phone into a private, tamper-evident media archive. Verified Digital DNA at capture, tamper-proof certificates on an independent global public ledger—local-first keys only you hold.';

/** Pillar section labels */
export const pillarWhatLabel = 'What it does';
export const pillarWhyLabel = 'Why you need it';
export const pillarTrustLabel = 'Can you trust it';

/** Hero — What at a glance */
export const heroLabel = pillarWhatLabel;

export const heroHeadline = 'Transform your phone into a';
export const heroHeadlineAccent = 'private, tamper-evident media archive';

export const heroLead =
  'FactLockCam turns your phone into a private, tamper-evident media archive. The moment you capture a photo or video, the app seals it with verified Digital DNA—then lets you generate a tamper-proof certificate backed by an independent global public ledger, so you can prove authenticity when it matters.';

export const heroPrivacyLine =
  'Only you hold the keys—we cannot access your unencrypted files.';

export const heroTaglineLine1 = 'Sovereign keys.';
export const heroTaglineLine2 = 'Verifiable seal.';

/**
 * Drop-in hero background (no baked marketing copy).
 * Replace the file under public/images/ and point here — see public/images/README.md
 */
export const heroBackgroundSrc = '/images/hero-background.svg';

export const heroImageAlt = 'Decorative FactLockCam homepage background';

/** What — detail panels */
export const panel1Title = 'Seal at capture';
export const panel1Label = 'Verified Digital DNA on device';
export const panel1Body =
  'Every photo and video is sealed the instant you capture—local-first encrypted archive, optional hardware-backed signing on supported iOS and Android devices, and a transactional journal that records prepare/commit integrity on your device.';
export const panel1Bullets = [
  'Location + timestamp at seal',
  'Hardware-backed signing on supported devices',
  'Transactional journal integrity',
] as const;

export const panel2Title = 'Proof on demand';
export const panel2Label = 'Tamper-proof certificate';
export const panel2Body =
  'When you need to show what was captured, open Certificate Studio in the app: edit title and description, preview a tamper-proof certificate PDF with your asset hash and ledger anchor, then print or share the PDF directly from your device.';
export const panel2Bullets = [
  'Independent global public ledger',
  'Live certificate preview in the app',
  'Print or share PDF from your device',
] as const;

/** Why — use cases */
export const whyHeadline = 'When a normal photo is not enough';

export const whyBody =
  'AI deepfakes and digital manipulation make it harder to show that a specific file existed unchanged at a point in time. For insurance claims, accident documentation, journalistic evidence, or protecting intellectual property, a standard smartphone photo is no longer enough. FactLockCam provides a cryptographic snapshot and verifiable chain-of-custody for the capture—not a guarantee of physical truth.';

export const whyUseCases = [
  'Insurance claims',
  'Accident documentation',
  'Journalistic evidence',
  'Intellectual property',
] as const;

/** Trust */
export const trustLabel = pillarTrustLabel;

export const trustHeadline = 'Built so you do not have to trust us';

export const trustBody =
  'FactLockCam is built so you do not have to trust us. Sovereign, local-first architecture means we do not hold your keys and cannot access your unencrypted files. Your proof is not locked in a proprietary corporate database; it is anchored on an independent public record that others can verify independently.';

export const trustDisclaimer =
  'Local-first encrypted archive, transactional journal, and tamper-proof certificates—without promising flawless or indefinite security. Seals certify file integrity, not the physical truth of the scene. Ledger notarization on Polygon mainnet has no uptime or gas SLA. Evidentiary and procedural details for professionals are in our Terms of Service.';

export const footerTagline = 'Sovereign keys. Verifiable seal.';
export const footerBlurb =
  'Private, tamper-evident media archive with verified Digital DNA at capture and tamper-proof certificates on an independent global public ledger.';

export const layoutDefaultDescription = metaDescription;

export const mechanismHeadline =
  'Private, tamper-evident media archive — sovereign zero-knowledge local lock';

export const guideIntro =
  'FactLockCam is a private, tamper-evident media archive with verified Digital DNA at capture—not a messaging app.';

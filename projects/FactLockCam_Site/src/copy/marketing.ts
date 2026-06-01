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

export const pageTitle = 'FactLockCam — Sovereign Zero-Knowledge Local Lock';

export const metaDescription =
  'FactLockCam seals captures on-device with verified Digital DNA, a transactional journal, and sovereign zero-knowledge keys. Tamper-proof certificates on a global public ledger.';

export const heroLabel = 'Sovereign zero-knowledge local lock';

export const heroHeadline = 'Your private vault —';
export const heroHeadlineAccent = 'sovereign zero-knowledge local lock';

export const heroLead =
  'The moment you capture, FactLockCam seals media on-device with verified Digital DNA: SHA-256 fingerprint, AES-GCM encryption, and a transactional journal that records prepare/commit integrity on your device.';

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

export const panel1Title = 'Digital DNA on capture';
export const panel1Label = 'Verified seal on device';
export const panel1Body =
  'Every photo and video is sealed at capture—hardware-backed signing, local-first encrypted vault, and a journal-backed prepare/commit path. Native iOS capture only; no browser clone of the app.';
export const panel1Bullets = [
  'LOCATION + timestamp at seal',
  'Secure Enclave · device-held keys',
  'Transactional journal integrity',
] as const;

export const panel2Title = 'Tamper-proof certificate';
export const panel2Label = 'When you need to show what was captured';
export const panel2Body =
  'Generate a tamper-proof certificate anchored to an independent global public ledger. Send Proof delivers the certificate PDF plus a password-protected courier link—recipients unlock and verify in the browser without installing the app.';
export const panel2Bullets = [
  'Only you hold the keys',
  'Courier unlock at archive.factlockcam.com',
  'Share via Messages, Mail, or AirDrop',
] as const;

export const trustLabel = 'Verified mechanisms';
export const trustHeadline = 'Sovereign keys. Verifiable seal.';
export const trustBody =
  'Local-first encrypted vault, transactional journal, and tamper-proof certificates—without promising flawless or indefinite security. Evidentiary and procedural details for professionals are in our Terms of Service.';

export const footerTagline = 'Sovereign keys. Verifiable seal.';
export const footerBlurb =
  'Your private vault with sovereign zero-knowledge local lock, verified Digital DNA on capture, and tamper-proof certificates on a global public ledger.';

export const layoutDefaultDescription = metaDescription;

export const mechanismHeadline =
  'Your private vault — sovereign zero-knowledge local lock';

export const guideIntro =
  'FactLockCam is built as a sovereign zero-knowledge local lock for your private vault—not a messaging app.';

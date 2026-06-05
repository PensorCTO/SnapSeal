import 'package:flutter_test/flutter_test.dart';
import 'package:factlockcam/core/legal/disclaimers.dart';
import 'package:factlockcam/core/marketing/approved_pitch.dart';
import 'package:factlockcam/ui/mobile/archive/archive_presentation_copy.dart';

void main() {
  final curated = <String>[
    consumerMechanismPitch,
    mechanismHeadline,
    mechanismTagline,
    logonPitchFragment,
    logonComplianceFootnote,
    archiveHubSubtitle,
    certificatePdfSubtitle,
    sendProofShareIntro,
    packageDescription,
    consumerEpistemicLine,
    courierConsoleHeadline,
    courierConsoleGateSubtitle,
    courierConsoleViralPitch,
    ...userVisibleComplianceStrings,
    ...ArchivePresentationCopy.curatedUserVisible,
  ];

  test('curated user-visible strings avoid marketing ban list', () {
    for (final text in curated) {
      for (final banned in marketingBanList) {
        expect(
          text.toLowerCase().contains(banned.toLowerCase()),
          isFalse,
          reason: 'Banned phrase "$banned" found in: ${text.substring(0, text.length.clamp(0, 80))}…',
        );
      }
    }
  });

  test('logon footnote includes key custody and epistemic framing', () {
    expect(logonComplianceFootnote, contains('recover lost archives'));
    expect(logonComplianceFootnote, contains('physical truth'));
  });

  test('subscription disclaimer states zero data recovery', () {
    expect(archiveSubscriptionTierDisclaimer, contains('zero data recovery'));
    expect(archiveSubscriptionTierDisclaimer, contains('cannot restore'));
  });

  test('curated user-visible strings exclude deprecated Vault label', () {
    for (final text in curated) {
      expect(
        RegExp(r'\bVault\b', caseSensitive: false).hasMatch(text),
        isFalse,
        reason: 'Deprecated Vault label in: $text',
      );
    }
  });

  test('key backup disclaimers are keys-only and cover scenarios', () {
    expect(keyBackupOnlyDisclaimer, contains('.factlock'));
    expect(keyBackupOnlyDisclaimer, isNot(contains('encrypted assets')));
    expect(keyCustodyScenarioSummary, contains('Burn'));
    expect(keyCustodyScenarioSummary, contains('Lock'));
    expect(burnAccountDisclaimer, contains('cannot resurrect'));
    expect(sovereignKeyCustodyDisclaimer, contains('Burning'));
    expect(lockArchiveDisclaimer, contains('Lock Archive'));
    for (final paragraph in archiveOnboardingParagraphs) {
      expect(paragraph, isNotEmpty);
    }
  });

  test('curated strings do not imply cloud media backup', () {
    const misleading = [
      'back up encrypted assets',
      'backup encrypted assets',
      'download your encrypted',
      'export encrypted photos',
    ];
    for (final text in curated) {
      final lower = text.toLowerCase();
      for (final phrase in misleading) {
        expect(
          lower.contains(phrase),
          isFalse,
          reason: 'Misleading phrase "$phrase" in compliance copy',
        );
      }
    }
  });
}

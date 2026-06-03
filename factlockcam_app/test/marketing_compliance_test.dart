import 'package:flutter_test/flutter_test.dart';
import 'package:factlockcam/core/legal/disclaimers.dart';
import 'package:factlockcam/core/marketing/approved_pitch.dart';

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
    ...userVisibleComplianceStrings,
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
}

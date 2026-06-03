import 'package:flutter_test/flutter_test.dart';
import 'package:factlockcam/features/archive_quota/domain/constants/archive_tier_defaults.dart';
import 'package:factlockcam/features/archive_quota/domain/models/archive_quota_snapshot.dart';
import 'package:factlockcam/features/archive_quota/domain/models/archive_tier.dart';
import 'package:factlockcam/features/archive_quota/domain/services/local_archive_quota_gate.dart';

void main() {
  const gate = LocalArchiveQuotaGate();

  ArchiveQuotaSnapshot freeSnapshot({
    int storageUsed = 0,
    int? maxSingleCapture,
  }) {
    return ArchiveQuotaSnapshot(
      tier: ArchiveTier(
        tierId: ArchiveTierDefaults.freeTierId,
        displayName: 'Sovereign Free Baseline',
        storageLimitBytes: ArchiveTierDefaults.freeStorageLimitBytes,
        egressLimitBytes: ArchiveTierDefaults.freeEgressLimitBytes,
        monthlyPriceCents: 0,
        maxSingleCaptureBytes: maxSingleCapture,
      ),
      storageUsedBytes: storageUsed,
      egressUsedBytes: 0,
    );
  }

  group('LocalArchiveQuotaGate', () {
    test('allows seal when local usage plus incoming fits free tier', () {
      expect(
        gate.canSealWithLocalUsage(
          localUsedBytes: 10,
          snapshot: freeSnapshot(),
          incomingBytes: 100,
        ),
        isTrue,
      );
    });

    test('blocks seal when local usage exceeds free storage', () {
      expect(
        gate.canSealWithLocalUsage(
          localUsedBytes: ArchiveTierDefaults.freeStorageLimitBytes,
          snapshot: freeSnapshot(),
          incomingBytes: 1,
        ),
        isFalse,
      );
    });

    test('maxSingleCaptureBytes defaults to 50 MB on free tier', () {
      expect(
        gate.maxSingleCaptureBytes(freeSnapshot()),
        ArchiveTierDefaults.freeMaxSingleCaptureBytes,
      );
    });

    test('isFreeTier treats null snapshot as free', () {
      expect(gate.isFreeTier(null), isTrue);
    });
  });
}

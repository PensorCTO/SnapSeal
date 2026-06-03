import 'package:flutter_test/flutter_test.dart';

import 'package:factlockcam/features/archive_quota/domain/models/archive_quota_snapshot.dart';
import 'package:factlockcam/features/archive_quota/domain/models/archive_tier.dart';
import 'package:factlockcam/features/archive_quota/domain/models/quota_alert_level.dart';
import 'package:factlockcam/features/archive_quota/domain/repositories/i_archive_quota_repository.dart';
import 'package:factlockcam/features/archive_quota/domain/services/archive_quota_service.dart';

void main() {
  const freeTier = ArchiveTier(
    tierId: 'free',
    displayName: 'Zero-Trust Tourist',
    storageLimitBytes: 100,
    egressLimitBytes: 100,
    monthlyPriceCents: 0,
  );

  ArchiveQuotaSnapshot snapshot({
    int storageUsed = 0,
    int egressUsed = 0,
  }) {
    return ArchiveQuotaSnapshot(
      tier: freeTier,
      storageUsedBytes: storageUsed,
      egressUsedBytes: egressUsed,
    );
  }

  group('ArchiveQuotaService', () {
    late ArchiveQuotaService service;

    setUp(() {
      service = ArchiveQuotaService(repository: _NoopArchiveQuotaRepository());
    });

    test('warns at 80% usage', () {
      expect(service.shouldShowWarning(snapshot(storageUsed: 80)), isTrue);
      expect(
        service.alertLevelFor(snapshot(storageUsed: 80)),
        QuotaAlertLevel.warning80,
      );
    });

    test('critical at 95% usage', () {
      expect(service.shouldShowCritical(snapshot(egressUsed: 96)), isTrue);
      expect(
        service.alertLevelFor(snapshot(egressUsed: 96)),
        QuotaAlertLevel.critical95,
      );
    });

    test('blocks seal when storage exceeded', () {
      expect(
        service.canSeal(snapshot(storageUsed: 100), incomingBytes: 1),
        isFalse,
      );
      expect(
        service.canSeal(snapshot(storageUsed: 50), incomingBytes: 40),
        isTrue,
      );
    });

    test('blocks send proof when egress exceeded', () {
      expect(service.canSendProof(snapshot(egressUsed: 100)), isFalse);
      expect(service.canSendProof(snapshot(egressUsed: 50)), isTrue);
    });
  });
}

class _NoopArchiveQuotaRepository implements IArchiveQuotaRepository {
  @override
  bool get isConfigured => false;

  @override
  Future<ArchiveQuotaSnapshot> fetchMyQuota() =>
      throw UnimplementedError();

  @override
  void invalidateCache() {}

  @override
  Future<void> setTier(String tierId) => throw UnimplementedError();

  @override
  Stream<ArchiveQuotaSnapshot> watchMyQuota() =>
      throw UnimplementedError();
}

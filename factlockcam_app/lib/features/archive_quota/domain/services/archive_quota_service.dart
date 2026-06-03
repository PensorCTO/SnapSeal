import '../models/archive_quota_snapshot.dart';
import '../models/quota_alert_level.dart';
import '../repositories/i_archive_quota_repository.dart';

/// Business rules for archive storage and egress limits.
class ArchiveQuotaService {
  ArchiveQuotaService({required IArchiveQuotaRepository repository})
      : _repository = repository;

  static const double warningThreshold = 0.80;
  static const double criticalThreshold = 0.95;

  final IArchiveQuotaRepository _repository;

  bool get isConfigured => _repository.isConfigured;

  Future<ArchiveQuotaSnapshot> refresh() => _repository.fetchMyQuota();

  QuotaAlertLevel alertLevelFor(ArchiveQuotaSnapshot snapshot) =>
      snapshot.alertLevel;

  bool shouldShowWarning(ArchiveQuotaSnapshot snapshot) =>
      snapshot.storageUsageRatio >= warningThreshold ||
      snapshot.egressUsageRatio >= warningThreshold;

  bool shouldShowCritical(ArchiveQuotaSnapshot snapshot) =>
      snapshot.storageUsageRatio >= criticalThreshold ||
      snapshot.egressUsageRatio >= criticalThreshold;

  bool canSeal(
    ArchiveQuotaSnapshot snapshot, {
    required int incomingBytes,
  }) {
    if (incomingBytes <= 0) {
      return !snapshot.isStorageBlocked;
    }
    return snapshot.storageUsedBytes + incomingBytes <=
        snapshot.tier.storageLimitBytes;
  }

  bool canSendProof(ArchiveQuotaSnapshot snapshot) => !snapshot.isEgressBlocked;
}

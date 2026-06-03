import 'archive_tier.dart';
import 'quota_alert_level.dart';

/// Point-in-time archive storage and egress usage for the signed-in user.
class ArchiveQuotaSnapshot {
  const ArchiveQuotaSnapshot({
    required this.tier,
    required this.storageUsedBytes,
    required this.egressUsedBytes,
    this.egressPeriodStart,
  });

  final ArchiveTier tier;
  final int storageUsedBytes;
  final int egressUsedBytes;
  final DateTime? egressPeriodStart;

  double get storageUsageRatio {
    if (tier.storageLimitBytes <= 0) return 0;
    return storageUsedBytes / tier.storageLimitBytes;
  }

  double get egressUsageRatio {
    if (tier.egressLimitBytes <= 0) return 0;
    return egressUsedBytes / tier.egressLimitBytes;
  }

  QuotaAlertLevel get alertLevel {
    final peak = storageUsageRatio > egressUsageRatio
        ? storageUsageRatio
        : egressUsageRatio;
    if (peak >= 1.0) return QuotaAlertLevel.blocked;
    if (peak >= 0.95) return QuotaAlertLevel.critical95;
    if (peak >= 0.80) return QuotaAlertLevel.warning80;
    return QuotaAlertLevel.normal;
  }

  bool get isStorageBlocked => storageUsageRatio >= 1.0;

  bool get isEgressBlocked => egressUsageRatio >= 1.0;

  factory ArchiveQuotaSnapshot.fromRpcJson(Map<String, dynamic> json) {
    return ArchiveQuotaSnapshot(
      tier: ArchiveTier.fromJson(json),
      storageUsedBytes: parseQuotaInt(json['storage_used_bytes']),
      egressUsedBytes: parseQuotaInt(json['egress_used_bytes']),
      egressPeriodStart: json['egress_period_start'] == null
          ? null
          : DateTime.tryParse(json['egress_period_start'].toString()),
    );
  }
}

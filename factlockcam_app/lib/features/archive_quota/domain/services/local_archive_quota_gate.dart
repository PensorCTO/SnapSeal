import '../constants/archive_tier_defaults.dart';
import '../models/archive_quota_snapshot.dart';

/// Local-first quota checks using on-device byte totals (SQLite), not server rejections.
class LocalArchiveQuotaGate {
  const LocalArchiveQuotaGate();

  /// Whether a new seal fits within tier storage using [localUsedBytes] from SQLite.
  bool canSealWithLocalUsage({
    required int localUsedBytes,
    required ArchiveQuotaSnapshot? snapshot,
    required int incomingBytes,
  }) {
    final limit = _storageLimitBytes(snapshot);
    if (incomingBytes <= 0) {
      return localUsedBytes < limit;
    }
    return localUsedBytes + incomingBytes <= limit;
  }

  /// Max bytes for one capture on the active tier (free tier = 50 MB).
  int maxSingleCaptureBytes(ArchiveQuotaSnapshot? snapshot) {
    final tierCap = snapshot?.tier.maxSingleCaptureBytes;
    if (tierCap != null && tierCap > 0) {
      return tierCap;
    }
    if (snapshot == null ||
        snapshot.tier.tierId == ArchiveTierDefaults.freeTierId) {
      return ArchiveTierDefaults.freeMaxSingleCaptureBytes;
    }
    return snapshot.tier.storageLimitBytes;
  }

  bool isFreeTier(ArchiveQuotaSnapshot? snapshot) {
    final id = snapshot?.tier.tierId ?? ArchiveTierDefaults.freeTierId;
    return id == ArchiveTierDefaults.freeTierId;
  }

  int _storageLimitBytes(ArchiveQuotaSnapshot? snapshot) {
    if (snapshot != null && snapshot.tier.storageLimitBytes > 0) {
      return snapshot.tier.storageLimitBytes;
    }
    return ArchiveTierDefaults.freeStorageLimitBytes;
  }
}

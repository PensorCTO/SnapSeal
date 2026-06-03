import '../models/archive_quota_snapshot.dart';

/// Reads archive quota telemetry from Supabase (RPC-only mutations server-side).
abstract class IArchiveQuotaRepository {
  bool get isConfigured;

  Future<ArchiveQuotaSnapshot> fetchMyQuota();

  Stream<ArchiveQuotaSnapshot> watchMyQuota();

  void invalidateCache();

  Future<void> setTier(String tierId);
}

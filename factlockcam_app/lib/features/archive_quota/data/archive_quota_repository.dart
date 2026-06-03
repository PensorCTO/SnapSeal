import 'package:postgrest/postgrest.dart';

import '../../../../data/supabase/supabase_client_handle.dart';
import '../domain/models/archive_quota_snapshot.dart';
import '../domain/repositories/i_archive_quota_repository.dart';
import 'archive_quota_rpc.dart';

/// Supabase-backed archive quota repository.
class ArchiveQuotaRepository implements IArchiveQuotaRepository {
  ArchiveQuotaRepository(this._handle);

  final SupabaseClientHandle _handle;
  ArchiveQuotaSnapshot? _cached;

  @override
  bool get isConfigured => _handle.client != null;

  @override
  void invalidateCache() {
    _cached = null;
  }

  @override
  Future<ArchiveQuotaSnapshot> fetchMyQuota() async {
    final client = _requiredClient();
    try {
      final response = await client.rpc('get_my_archive_quota');
      _cached = snapshotFromGetMyArchiveQuotaResponse(response);
      return _cached!;
    } on PostgrestException catch (error) {
      throw StateError(describeArchiveQuotaRpcError(error));
    } on FormatException catch (error) {
      throw StateError(describeArchiveQuotaRpcError(error));
    }
  }

  @override
  Stream<ArchiveQuotaSnapshot> watchMyQuota() async* {
    yield await fetchMyQuota();
  }

  @override
  Future<void> setTier(String tierId) async {
    final client = _requiredClient();
    try {
      await client.rpc(
        'set_archive_tier',
        params: {'p_tier_id': tierId},
      );
    } on PostgrestException catch (error) {
      throw StateError(
        describeArchiveQuotaRpcError(error, rpcName: 'set_archive_tier'),
      );
    }
    invalidateCache();
  }

  dynamic _requiredClient() {
    final client = _handle.client;
    if (client == null) {
      throw StateError('Supabase is not configured.');
    }
    return client;
  }
}

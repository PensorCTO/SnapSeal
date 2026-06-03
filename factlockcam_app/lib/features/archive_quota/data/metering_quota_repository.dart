import 'package:postgrest/postgrest.dart';

import '../../../data/supabase/supabase_client_handle.dart';
import '../domain/models/metered_action_type.dart';
import '../domain/models/quota_state.dart';
import '../domain/repositories/i_metering_quota_repository.dart';
import 'archive_quota_rpc.dart';

/// Supabase-backed credit metering repository.
class MeteringQuotaRepository implements IMeteringQuotaRepository {
  MeteringQuotaRepository(this._handle);

  final SupabaseClientHandle _handle;

  @override
  bool get isConfigured => _handle.client != null;

  @override
  Future<QuotaState> fetchCurrentQuotaStatus() async {
    final client = _requiredClient();
    try {
      final response = await client.rpc('get_current_quota_status');
      return quotaStateFromGetCurrentQuotaStatusResponse(response);
    } on PostgrestException catch (error) {
      throw StateError(
        describeArchiveQuotaRpcError(
          error,
          rpcName: 'get_current_quota_status',
        ),
      );
    } on FormatException catch (error) {
      throw StateError(
        describeArchiveQuotaRpcError(
          error,
          rpcName: 'get_current_quota_status',
        ),
      );
    }
  }

  @override
  Future<QuotaState> recordMeteredConsumption(
    MeteredActionType actionType,
  ) async {
    final client = _requiredClient();
    try {
      final response = await client.rpc(
        'record_metered_consumption',
        params: {'p_action_type': actionType.rpcValue},
      );
      return quotaStateFromGetCurrentQuotaStatusResponse(response);
    } on PostgrestException catch (error) {
      throw StateError(
        describeArchiveQuotaRpcError(
          error,
          rpcName: 'record_metered_consumption',
        ),
      );
    } on FormatException catch (error) {
      throw StateError(
        describeArchiveQuotaRpcError(
          error,
          rpcName: 'record_metered_consumption',
        ),
      );
    }
  }

  dynamic _requiredClient() {
    final client = _handle.client;
    if (client == null) {
      throw StateError('Supabase is not configured.');
    }
    return client;
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase/supabase_client_handle.dart';
import '../domain/models/block_origin_request.dart';

/// Encapsulates UGC safety RPCs and async moderation triggers.
///
/// UI must never access [SupabaseClient] directly — route through this repository.
class SafetyRepository {
  SafetyRepository(this._handle);

  final SupabaseClientHandle _handle;

  bool get isConfigured => _handle.client != null;

  /// Placeholder for future identity verification (not required in v1).
  Future<ReporterIdentityStatus> verifyReporterIdentity() async {
    return ReporterIdentityStatus.notRequired;
  }

  Future<Map<String, dynamic>> reportCourierPackage(
    ContentReportRequest request,
  ) async {
    final client = _requiredClient();
    final response = await client.rpc(
      'report_courier_package',
      params: {
        'p_package_id': request.packageId,
        'p_reason': request.reason,
        'p_detail': request.detail,
        'p_reporter_email': request.reporterEmail,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> blockCourierSender(
    BlockOriginRequest request,
  ) async {
    final client = _requiredClient();
    final response = await client.rpc(
      'block_courier_sender',
      params: {
        'p_package_id': request.packageId,
        'p_reporter_email': request.reporterEmail,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<bool> isSenderBlockedForReporter({
    required String packageId,
    String? reporterEmail,
  }) async {
    final client = _requiredClient();
    final response = await client.rpc(
      'check_sender_blocked_for_reporter',
      params: {
        'p_package_id': packageId,
        'p_reporter_email': reporterEmail,
      },
    );
    final map = Map<String, dynamic>.from(response as Map);
    return map['blocked'] == true;
  }

  Future<String?> getOwnCourierPackageId(String assetHash) async {
    final client = _requiredClient();
    final response = await client.rpc(
      'get_own_courier_package_id',
      params: {'p_asset_hash': assetHash},
    );
    if (response == null) return null;
    return response.toString();
  }

  /// Fire-and-forget async content scan — does not block capture or upload UI.
  Future<void> triggerAsyncContentScan({required String packageId}) async {
    final client = _handle.client;
    if (client == null) return;

    try {
      await client.functions.invoke(
        'courier-content-scan',
        body: <String, dynamic>{'package_id': packageId},
      );
    } catch (_) {
      // Scan failures are non-fatal; moderation queue can be retried server-side.
    }
  }

  SupabaseClient _requiredClient() {
    final client = _handle.client;
    if (client == null) {
      throw StateError(
        'Supabase is not configured. Run with --dart-define SUPABASE_URL=... '
        'and --dart-define SUPABASE_ANON_KEY=...',
      );
    }
    return client;
  }
}

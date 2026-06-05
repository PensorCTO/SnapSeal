import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client_handle.dart';

/// Repository that encapsulates all Supabase RPC and Storage interactions
/// for the Courier unlock flow (web).
///
/// UI controllers must never access `Supabase.instance.client` directly;
/// all courier RPC calls (`check_courier_attempts`, `attempt_courier_unlock`)
/// and blob downloads are routed through this repository.
class CourierRepository {
  CourierRepository(this._handle);

  final SupabaseClientHandle _handle;

  bool get isConfigured => _handle.client != null;

  Future<Map<String, dynamic>> checkCourierAttempts(
    String packageId,
  ) async {
    final client = _requiredClient();
    final response = await client.rpc(
      'check_courier_attempts',
      params: {'p_package_id': packageId},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> attemptUnlock({
    required String packageId,
    required String verifierGuess,
    required String requestorEmail,
  }) async {
    final client = _requiredClient();
    final response = await client.functions.invoke(
      'courier-unlock',
      body: <String, dynamic>{
        'package_id': packageId,
        'verifier_guess': verifierGuess,
        'requestor_email': requestorEmail.trim(),
      },
    );

    if (response.status >= 400) {
      final data = response.data;
      final detail = data is Map ? data['error'] ?? data : data;
      throw StateError('courier-unlock failed ($response.status): $detail');
    }

    final data = response.data;
    if (data is! Map) {
      throw StateError('courier-unlock returned unexpected payload.');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> reportCourierPackage({
    required String packageId,
    required String reason,
    String? detail,
    String? reporterEmail,
  }) async {
    final client = _requiredClient();
    final response = await client.rpc(
      'report_courier_package',
      params: {
        'p_package_id': packageId,
        'p_reason': reason,
        'p_detail': detail,
        'p_reporter_email': reporterEmail,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> blockCourierSender({
    required String packageId,
    String? reporterEmail,
  }) async {
    final client = _requiredClient();
    final response = await client.rpc(
      'block_courier_sender',
      params: {
        'p_package_id': packageId,
        'p_reporter_email': reporterEmail,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Uint8List> downloadSignedBlob(String signedUrl) async {
    _requiredClient();
    final response = await http.get(Uri.parse(signedUrl));
    if (response.statusCode >= 400) {
      throw StateError(
        'Signed blob download failed (${response.statusCode}).',
      );
    }
    return response.bodyBytes;
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

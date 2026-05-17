import 'dart:typed_data';

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
    final response = await client.rpc(
      'attempt_courier_unlock',
      params: {
        'p_package_id': packageId,
        'p_verifier_guess': verifierGuess,
        'p_requestor_email': requestorEmail.trim(),
      },
    );
    return _firstRpcRow(response);
  }

  Future<Uint8List> downloadBlob({
    required String bucket,
    required String path,
  }) async {
    final client = _requiredClient();
    return client.storage.from(bucket).download(path);
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

  Map<String, dynamic> _firstRpcRow(Object? response) {
    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    throw StateError('Courier unlock RPC returned no package data.');
  }
}

import 'dart:convert';

import 'package:postgrest/postgrest.dart';

import '../domain/models/archive_quota_snapshot.dart';
import '../domain/models/quota_state.dart';

/// Parses PostgREST payload from [get_my_archive_quota] (returns jsonb).
Map<String, dynamic> parseGetMyArchiveQuotaResponse(Object? response) {
  if (response == null) {
    throw const FormatException('get_my_archive_quota returned null');
  }
  if (response is Map) {
    return Map<String, dynamic>.from(response);
  }
  if (response is String) {
    final decoded = jsonDecode(response);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw FormatException(
      'get_my_archive_quota JSON string decoded to ${decoded.runtimeType}',
    );
  }
  throw FormatException(
    'get_my_archive_quota returned unexpected type: ${response.runtimeType}',
  );
}

ArchiveQuotaSnapshot snapshotFromGetMyArchiveQuotaResponse(Object? response) {
  return ArchiveQuotaSnapshot.fromRpcJson(
    parseGetMyArchiveQuotaResponse(response),
  );
}

/// Parses PostgREST payload from [get_current_quota_status] (returns jsonb).
Map<String, dynamic> parseGetCurrentQuotaStatusResponse(Object? response) {
  if (response == null) {
    throw const FormatException('get_current_quota_status returned null');
  }
  if (response is Map) {
    return Map<String, dynamic>.from(response);
  }
  if (response is String) {
    final decoded = jsonDecode(response);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw FormatException(
      'get_current_quota_status JSON string decoded to ${decoded.runtimeType}',
    );
  }
  throw FormatException(
    'get_current_quota_status returned unexpected type: ${response.runtimeType}',
  );
}

QuotaState quotaStateFromGetCurrentQuotaStatusResponse(Object? response) {
  return QuotaState.fromRpcJson(parseGetCurrentQuotaStatusResponse(response));
}

/// Human-readable detail for quota RPC failures (schema drift, auth, RLS).
String describeArchiveQuotaRpcError(Object error, {String rpcName = 'get_my_archive_quota'}) {
  if (error is PostgrestException) {
    final code = error.code ?? '';
    final hint = switch (code) {
      'PGRST202' =>
        ' — RPC not in PostgREST schema; run migration push and NOTIFY reload',
      '42501' => ' — permission denied; check GRANT EXECUTE for authenticated',
      _ => '',
    };
    return '$rpcName failed ($code): ${error.message}$hint';
  }
  return '$rpcName failed: $error';
}

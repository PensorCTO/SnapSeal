import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Optional compile-time debug ingest endpoint.
///
/// Set via `--dart-define=DEBUG_INGEST_ENDPOINT=http://127.0.0.1:7538/ingest/...`.
/// When empty (the default), the HTTP ingest path is skipped entirely.
const _debugIngestEndpoint = String.fromEnvironment('DEBUG_INGEST_ENDPOINT');

/// Optional compile-time debug log file path.
///
/// Set via `--dart-define=DEBUG_LOG_PATH=/absolute/path/to/debug.log`.
/// When empty (the default), the file-append path is skipped entirely.
const _debugLogPath = String.fromEnvironment('DEBUG_LOG_PATH');

Future<void> debugAgentNdjson({
  required String sessionId,
  required String hypothesisId,
  required String location,
  required String message,
  Map<String, Object?>? data,
}) async {
  if (!kDebugMode) {
    return;
  }

  final payload = <String, Object?>{
    'sessionId': sessionId,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    if (data != null && data.isNotEmpty) 'data': data,
  };
  final line = jsonEncode(payload);

  // #region agent log (file)

  if (_debugLogPath.isNotEmpty) {
    try {
      await File(_debugLogPath).writeAsString(
        '$line\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  // #endregion agent log (file)

  // #region agent log (http ingest)

  if (_debugIngestEndpoint.isNotEmpty) {
    HttpClient? client;
    try {
      client = HttpClient();
      final uri = Uri.parse(_debugIngestEndpoint);
      final req = await client
          .postUrl(uri)
          .timeout(const Duration(milliseconds: 800));
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.headers.set('X-Debug-Session-Id', sessionId);
      req.write(line);
      await req.close().timeout(const Duration(milliseconds: 1200));
    } catch (_) {
      // Ingest host unavailable (common on-device); file append may still
      // succeed when separately configured.
    } finally {
      client?.close(force: true);
    }
  }

  // #endregion agent log (http ingest)
}

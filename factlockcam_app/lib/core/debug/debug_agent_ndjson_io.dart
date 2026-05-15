import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

const _cursorDebugLogPath =
    '/Users/paulensor/Projects/ProofLockCleanup/.cursor/debug-aefb6a.log';
const _ingestEndpoint =
    'http://127.0.0.1:7538/ingest/e76402cf-87ef-4c85-95c6-3adf6790364a';

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

  // #region agent log
  try {
    await File(
      _cursorDebugLogPath,
    ).writeAsString('$line\n', mode: FileMode.append);
  } catch (_) {}

  HttpClient? client;
  try {
    client = HttpClient();
    final uri = Uri.parse(_ingestEndpoint);
    final req = await client
        .postUrl(uri)
        .timeout(const Duration(milliseconds: 800));
    req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    req.headers.set('X-Debug-Session-Id', sessionId);
    req.write(line);
    await req.close().timeout(const Duration(milliseconds: 1200));
  } catch (_) {
    // Ingest/host unavailable (common on-device); file append may still succeed on desktop targets.
  } finally {
    client?.close(force: true);
  }
  // #endregion agent log
}

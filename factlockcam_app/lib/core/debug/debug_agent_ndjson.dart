import 'package:flutter/foundation.dart';

import 'debug_agent_ndjson_stub.dart'
    if (dart.library.io) 'debug_agent_ndjson_io.dart'
    as impl;

/// NDJSON ingest for Cursor DEBUG MODE (hypothesis tagging). Disabled outside [kDebugMode].
Future<void> debugAgentNdjson({
  required String sessionId,
  required String hypothesisId,
  required String location,
  required String message,
  Map<String, Object?>? data,
}) => impl.debugAgentNdjson(
  sessionId: sessionId,
  hypothesisId: hypothesisId,
  location: location,
  message: message,
  data: data,
);

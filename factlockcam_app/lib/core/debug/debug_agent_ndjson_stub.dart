import 'package:flutter/foundation.dart';

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
}

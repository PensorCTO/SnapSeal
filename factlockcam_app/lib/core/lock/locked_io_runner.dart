import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'advisory_file_lock_io.dart';

/// Payload for isolate file writes with POSIX advisory locks.
class LockedWritePayload {
  const LockedWritePayload({
    required this.path,
    required this.bytes,
    this.notifyPort,
    this.fileId,
  });

  final String path;
  final Uint8List bytes;
  final SendPort? notifyPort;
  final String? fileId;
}

void lockedWriteBytesEntry(LockedWritePayload payload) {
  final port = payload.notifyPort;
  final fileId = payload.fileId;
  if (port != null && fileId != null) {
    port.send({'fileId': fileId, 'isProcessing': true});
  }
  try {
    final file = File(payload.path);
    final parent = file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }
    AdvisoryFileLock.runExclusiveSync(payload.path, (raf) {
      raf.writeFromSync(payload.bytes);
      raf.flushSync();
    });
  } finally {
    if (port != null && fileId != null) {
      port.send({'fileId': fileId, 'isProcessing': false});
    }
  }
}

/// Payload for atomic rename under advisory lock on the staging file.
class LockedRenamePayload {
  const LockedRenamePayload({
    required this.stagingPath,
    required this.finalPath,
    this.notifyPort,
    this.fileId,
  });

  final String stagingPath;
  final String finalPath;
  final SendPort? notifyPort;
  final String? fileId;
}

void lockedRenameEntry(LockedRenamePayload payload) {
  final port = payload.notifyPort;
  final fileId = payload.fileId;
  if (port != null && fileId != null) {
    port.send({'fileId': fileId, 'isProcessing': true});
  }
  try {
    final staging = File(payload.stagingPath);
    if (!staging.existsSync()) {
      throw StateError('Staging file missing: ${payload.stagingPath}');
    }
    AdvisoryFileLock.runExclusiveSync(payload.stagingPath, (_) {
      final target = File(payload.finalPath);
      if (target.existsSync()) {
        target.deleteSync();
      }
      staging.renameSync(payload.finalPath);
    });
  } finally {
    if (port != null && fileId != null) {
      port.send({'fileId': fileId, 'isProcessing': false});
    }
  }
}

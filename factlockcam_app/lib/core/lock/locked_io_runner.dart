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
    File(payload.path).writeAsBytesSync(payload.bytes, flush: true);
    final writtenLength = File(payload.path).lengthSync();
    if (writtenLength != payload.bytes.length) {
      throw StateError(
        'Vault write length mismatch for ${payload.path}: '
        'expected ${payload.bytes.length}, got $writtenLength',
      );
    }
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
    final stagingLength = staging.lengthSync();
    if (stagingLength == 0) {
      throw StateError(
        'Staging file is empty before promote: ${payload.stagingPath}',
      );
    }
    AdvisoryFileLock.runExclusiveSync(
      AdvisoryFileLock.sidecarLockPath(payload.stagingPath),
      (_) {
        final target = File(payload.finalPath);
        if (target.existsSync()) {
          target.deleteSync();
        }
        staging.renameSync(payload.finalPath);
      },
    );
    final finalLength = File(payload.finalPath).lengthSync();
    if (finalLength != stagingLength) {
      throw StateError(
        'Promoted vault file length mismatch for ${payload.finalPath}: '
        'expected $stagingLength, got $finalLength',
      );
    }
  } finally {
    if (port != null && fileId != null) {
      port.send({'fileId': fileId, 'isProcessing': false});
    }
  }
}

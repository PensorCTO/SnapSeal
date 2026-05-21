import 'dart:io';

/// Advisory exclusive file locks for vault staging/final paths (POSIX-backed on iOS).
class AdvisoryFileLock {
  AdvisoryFileLock._();

  static void runExclusiveSync(
    String path,
    void Function(RandomAccessFile raf) action, {
    FileMode mode = FileMode.write,
  }) {
    final raf = File(path).openSync(mode: mode);
    try {
      raf.lockSync(FileLock.exclusive);
      try {
        action(raf);
      } finally {
        raf.unlockSync();
      }
    } finally {
      raf.closeSync();
    }
  }

  /// Sidecar lock path used when promoting staging payloads without truncating them.
  static String sidecarLockPath(String payloadPath) => '$payloadPath.lock';
}

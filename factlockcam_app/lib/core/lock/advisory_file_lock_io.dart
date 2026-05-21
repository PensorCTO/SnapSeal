import 'dart:io';

/// Advisory exclusive file locks for vault staging/final paths (POSIX-backed on iOS).
class AdvisoryFileLock {
  AdvisoryFileLock._();

  static void runExclusiveSync(
    String path,
    void Function(RandomAccessFile raf) action,
  ) {
    final raf = File(path).openSync(mode: FileMode.write);
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
}

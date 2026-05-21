/// No-op advisory locks on web (no dart:io / flock).
class AdvisoryFileLock {
  static void runExclusiveSync(String path, void Function(Object? handle) action) {
    action(null);
  }
}

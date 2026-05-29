import 'key_custody_service.dart';

/// Orchestrates zero-knowledge lock (brick) by purging both sovereign keys.
class AppLockCoordinator {
  AppLockCoordinator({required KeyCustodyService keyCustodyService})
      : _keyCustodyService = keyCustodyService;

  final KeyCustodyService _keyCustodyService;

  /// Removes both keys from secure storage. Throws if either remains after retries.
  Future<void> lockArchive() async {
    await _keyCustodyService.purgeSovereignKeysOnly();
    if (await _keyCustodyService.hasLocalKeys()) {
      throw StateError(
        'Archive lock failed: sovereign keys still present on device.',
      );
    }
  }
}

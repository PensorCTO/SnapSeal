import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/locator.dart';
import '../../core/lock/isolate_lock_coordinator.dart';

/// Bridges [IsolateLockCoordinator] into Riverpod for archive/camera UI.
final isolateLockCoordinatorProvider = Provider<IsolateLockCoordinator>(
  (ref) => getIt<IsolateLockCoordinator>(),
);

final assetLockStateProvider =
    NotifierProvider<AssetLockNotifier, Set<String>>(AssetLockNotifier.new);

class AssetLockNotifier extends Notifier<Set<String>> {
  StreamSubscription<IsolateLockEvent>? _subscription;

  @override
  Set<String> build() {
    final coordinator = ref.watch(isolateLockCoordinatorProvider);
    _subscription?.cancel();
    _subscription = coordinator.lockStream.listen((event) {
      final next = Set<String>.from(state);
      if (event.state == LockState.processing) {
        next.add(event.fileId);
      } else {
        next.remove(event.fileId);
      }
      state = next;
    });
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
      _subscription = null;
    });
    return coordinator.snapshotActiveLocks();
  }

  bool isLocked(String assetFingerprint) => state.contains(assetFingerprint);
}

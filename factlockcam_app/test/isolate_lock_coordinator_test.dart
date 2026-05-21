import 'package:factlockcam/core/lock/isolate_lock_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lock and unlock update cache and stream', () async {
    final coordinator = IsolateLockCoordinator();

    final processingFuture = coordinator.lockStream.first;
    coordinator.lock('fp_a');
    final processing = await processingFuture;
    expect(processing.fileId, 'fp_a');
    expect(processing.state, LockState.processing);
    expect(coordinator.isFileLocked('fp_a'), isTrue);

    final idleFuture = coordinator.lockStream.first;
    coordinator.unlock('fp_a');
    final idle = await idleFuture;
    expect(idle.fileId, 'fp_a');
    expect(idle.state, LockState.idle);
    expect(coordinator.isFileLocked('fp_a'), isFalse);

    coordinator.dispose();
  });

  test('duplicate lock does not emit duplicate processing events', () async {
    final coordinator = IsolateLockCoordinator();
    var eventCount = 0;
    final sub = coordinator.lockStream.listen((_) => eventCount++);

    coordinator.lock('fp_b');
    await Future<void>.delayed(Duration.zero);
    coordinator.lock('fp_b');
    await Future<void>.delayed(Duration.zero);
    expect(eventCount, 1);

    await sub.cancel();
    coordinator.dispose();
  });
}

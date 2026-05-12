import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_controller.dart';

final pendingSyncSchedulerProvider = Provider<void>((ref) {
  final scheduler = PendingSyncScheduler(ref);
  scheduler.start();
  ref.onDispose(scheduler.dispose);
});

class PendingSyncScheduler {
  PendingSyncScheduler(this._ref);

  static const interval = Duration(minutes: 3);

  final Ref _ref;
  Timer? _timer;

  void start() {
    _tick();
    _timer ??= Timer.periodic(interval, (_) => _tick());
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    unawaited(_run());
  }

  Future<void> _run() async {
    try {
      await _ref
          .read(dashboardControllerProvider.notifier)
          .syncPendingInBackground();
    } catch (_) {
      // Best-effort scheduler: retry on next interval.
    }
  }
}

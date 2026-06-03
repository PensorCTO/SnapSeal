import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import 'quota_state_provider.dart';

final quotaLifecycleProvider = Provider<void>((ref) {
  if (AppConfig.isFlutterTest) {
    return;
  }
  final observer = _QuotaLifecycleObserver(ref);
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(observer);
  });
});

class _QuotaLifecycleObserver with WidgetsBindingObserver {
  _QuotaLifecycleObserver(this._ref);

  final Ref _ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_ref.read(quotaStateProvider.notifier).refresh());
    }
  }
}

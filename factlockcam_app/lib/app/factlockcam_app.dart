import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../core/di/service_providers.dart';
import '../ui/controllers/pending_sync_scheduler.dart';
import '../ui/providers/asset_lock_provider.dart';
import '../ui/providers/proof_notarization_provider.dart';

class FactLockCamApp extends ConsumerWidget {
  const FactLockCamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kIsWeb) {
      ref.watch(pendingSyncSchedulerProvider);
      ref.watch(assetLockStateProvider);
      ref.watch(polygonNotarizationLifecycleProvider);
      ref.watch(polygonProofSyncRefreshProvider);
      ref.watch(quotaLifecycleProvider);
    }
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'FactLockCam',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

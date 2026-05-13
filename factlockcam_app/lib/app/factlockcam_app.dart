import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../ui/controllers/pending_sync_scheduler.dart';

class FactLockCamApp extends ConsumerWidget {
  const FactLockCamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pendingSyncSchedulerProvider);
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

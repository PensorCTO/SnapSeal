import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../ui/controllers/pending_sync_scheduler.dart';

class SnapSealApp extends ConsumerWidget {
  const SnapSealApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pendingSyncSchedulerProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'SnapSeal',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

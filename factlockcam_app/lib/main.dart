import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/factlockcam_app.dart';
import 'core/di/injection.dart';
import 'core/journal/boot_recovery_runner.dart';
import 'core/network/supabase_client.dart';

const _dependencyTimeout = Duration(seconds: 20);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeBackend();

  // Sprint 2: silent WAL journal recovery before UI / DI touch vault files.
  await runBootRecoveryBeforeUi();

  try {
    await configureDependencies().timeout(_dependencyTimeout);
  } on TimeoutException {
    debugPrint(
      'configureDependencies timed out after ${_dependencyTimeout.inSeconds}s; '
      'resetting DI and launching UI.',
    );
    await resetDependenciesAfterStartupFailure();
  } catch (error, stackTrace) {
    debugPrint('configureDependencies failed: $error\n$stackTrace');
    await resetDependenciesAfterStartupFailure();
  }

  runApp(const ProviderScope(child: FactLockCamApp()));
}

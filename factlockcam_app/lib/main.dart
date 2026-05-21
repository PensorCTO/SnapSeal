import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/factlockcam_app.dart';
import 'core/di/injection.dart';
import 'core/journal/boot_recovery_runner.dart';
import 'core/network/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeBackend();

  // Sprint 2: silent WAL journal recovery before UI / DI touch vault files.
  await runBootRecoveryBeforeUi();

  await configureDependencies();

  runApp(const ProviderScope(child: FactLockCamApp()));
}

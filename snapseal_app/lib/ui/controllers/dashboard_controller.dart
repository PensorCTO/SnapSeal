import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/vault_database.dart';
import '../../data/models/archive_item.dart';
import '../../domain/services/vault_service.dart';

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, List<ArchiveItem>>(
      DashboardController.new,
    );

class DashboardController extends AsyncNotifier<List<ArchiveItem>> {
  @override
  Future<List<ArchiveItem>> build() {
    return ref.watch(vaultDatabaseProvider).listArchiveItems();
  }

  Future<void> burnLocalWallet() async {
    await ref.read(vaultServiceProvider).burnLocalWallet();
    state = const AsyncData([]);
  }
}

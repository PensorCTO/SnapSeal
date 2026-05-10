import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:snapseal/data/models/archive_item.dart';
import 'package:snapseal/ui/controllers/dashboard_controller.dart';
import 'package:snapseal/ui/views/vault_dashboard_view.dart';

void main() {
  test('VaultDashboardView uses vault-first route path', () {
    expect(VaultDashboardView.routePath, '/vault-dashboard');
  });

  testWidgets('vault dashboard shows Vault shell when archive is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _EmptyVaultDashboardController.new,
          ),
        ],
        child: const MaterialApp(home: VaultDashboardView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vault'), findsOneWidget);
    expect(find.text('Evidence vault'), findsOneWidget);
  });
}

class _EmptyVaultDashboardController extends DashboardController {
  @override
  Future<List<ArchiveItem>> build() async => const [];
}

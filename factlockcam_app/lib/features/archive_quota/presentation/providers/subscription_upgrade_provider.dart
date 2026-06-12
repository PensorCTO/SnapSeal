import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/locator.dart';
import '../../domain/services/subscription_billing_gateway.dart';
import 'archive_quota_provider.dart';
import 'quota_state_provider.dart';

final subscriptionUpgradeProvider =
    AsyncNotifierProvider<SubscriptionUpgrade, bool?>(
  SubscriptionUpgrade.new,
);

class SubscriptionUpgrade extends AsyncNotifier<bool?> {
  @override
  FutureOr<bool?> build() => null;

  Future<bool> upgrade(String targetTierId) async {
    state = const AsyncLoading();
    try {
      final gateway = getIt<SubscriptionBillingGateway>();
      final ok = await gateway.upgradeTier(targetTierId: targetTierId);
      if (ok) {
        await ref.read(archiveQuotaNotifierProvider.notifier).refresh();
      }
      state = AsyncData(ok);
      return ok;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Restores previously purchased subscription entitlements (Guideline 3.1.1).
  Future<bool> restore() async {
    state = const AsyncLoading();
    try {
      final gateway = getIt<SubscriptionBillingGateway>();
      final ok = await gateway.restorePurchases();
      if (ok) {
        await ref.read(archiveQuotaNotifierProvider.notifier).refresh();
        await ref.read(quotaStateProvider.notifier).refresh();
      }
      state = AsyncData(ok);
      return ok;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

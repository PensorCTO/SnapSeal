import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/locator.dart';
import '../../../../data/supabase/auth_repository.dart';
import '../../../../ui/controllers/auth_controller.dart';
import '../../domain/models/metered_action_type.dart';
import '../../domain/models/quota_state.dart';
import '../../domain/services/metering_quota_service.dart';

final meteringQuotaServiceProvider = Provider<MeteringQuotaService>(
  (ref) => getIt<MeteringQuotaService>(),
);

final quotaStateProvider =
    NotifierProvider<QuotaStateNotifier, QuotaState?>(QuotaStateNotifier.new);

class QuotaStateNotifier extends Notifier<QuotaState?> {
  QuotaState? _preOptimisticSnapshot;

  @override
  QuotaState? build() {
    if (AppConfig.isFlutterTest) {
      return null;
    }

    ref.listen<AsyncValue<AuthState?>>(
      authStateProvider,
      (previous, next) {
        final session = next.asData?.value?.session;
        final hadSession = previous?.asData?.value?.session != null;
        if (session != null) {
          unawaited(refresh());
        } else if (hadSession) {
          state = null;
        }
      },
    );

    unawaited(_loadWhenSessionReady());
    return null;
  }

  Future<void> _loadWhenSessionReady() async {
    final service = ref.read(meteringQuotaServiceProvider);
    if (!service.isConfigured) {
      return;
    }
    if (!_hasAuthenticatedSession()) {
      return;
    }
    await refresh();
  }

  bool _hasAuthenticatedSession() {
    final client = ref.read(supabaseClientProvider);
    return client?.auth.currentSession != null;
  }

  Future<void> refresh() async {
    final service = ref.read(meteringQuotaServiceProvider);
    if (!service.isConfigured) {
      state = null;
      return;
    }
    if (!_hasAuthenticatedSession()) {
      state = null;
      return;
    }
    try {
      state = await service.fetchStatus();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('QuotaStateNotifier.refresh: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  void optimisticDebit(MeteredActionType type) {
    final current = state;
    if (current == null) {
      return;
    }
    _preOptimisticSnapshot ??= current;
    final service = ref.read(meteringQuotaServiceProvider);
    state = service.optimisticDebit(current, type);
  }

  Future<void> reconcile() async {
    _preOptimisticSnapshot = null;
    await refresh();
  }

  void rollbackOptimistic() {
    if (_preOptimisticSnapshot != null) {
      state = _preOptimisticSnapshot;
      _preOptimisticSnapshot = null;
    }
  }

  Future<void> recordAndReconcile(MeteredActionType type) async {
    final service = ref.read(meteringQuotaServiceProvider);
    if (!service.isConfigured || !_hasAuthenticatedSession()) {
      return;
    }
    try {
      state = await service.recordConsumption(type);
      _preOptimisticSnapshot = null;
    } catch (error, stackTrace) {
      rollbackOptimistic();
      if (kDebugMode) {
        debugPrint('QuotaStateNotifier.recordAndReconcile: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      unawaited(refresh());
    }
  }
}

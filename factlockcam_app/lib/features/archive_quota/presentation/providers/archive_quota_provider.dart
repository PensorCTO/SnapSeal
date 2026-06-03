import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/locator.dart';
import '../../../../data/supabase/auth_repository.dart';
import '../../../../ui/controllers/auth_controller.dart';
import '../../domain/models/archive_quota_snapshot.dart';
import '../../domain/services/archive_quota_service.dart';

final archiveQuotaServiceProvider = Provider<ArchiveQuotaService>(
  (ref) => getIt<ArchiveQuotaService>(),
);

final archiveQuotaNotifierProvider =
    AsyncNotifierProvider<ArchiveQuotaNotifier, ArchiveQuotaSnapshot?>(
  ArchiveQuotaNotifier.new,
);

class ArchiveQuotaNotifier extends AsyncNotifier<ArchiveQuotaSnapshot?> {
  @override
  Future<ArchiveQuotaSnapshot?> build() async {
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
          state = const AsyncData(null);
        }
      },
    );

    return _loadWhenSessionReady();
  }

  Future<ArchiveQuotaSnapshot?> _loadWhenSessionReady() async {
    final service = ref.read(archiveQuotaServiceProvider);
    if (!service.isConfigured) {
      return null;
    }
    if (!_hasAuthenticatedSession()) {
      return null;
    }
    return _fetchQuota(service);
  }

  bool _hasAuthenticatedSession() {
    final client = ref.read(supabaseClientProvider);
    return client?.auth.currentSession != null;
  }

  Future<ArchiveQuotaSnapshot?> _fetchQuota(ArchiveQuotaService service) async {
    try {
      return await service.refresh();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('ArchiveQuotaNotifier: $error');
        FlutterError.presentError(
          FlutterErrorDetails(exception: error, stack: stackTrace),
        );
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    final service = ref.read(archiveQuotaServiceProvider);
    if (!service.isConfigured) {
      state = const AsyncData(null);
      return;
    }
    if (!_hasAuthenticatedSession()) {
      state = const AsyncData(null);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => service.refresh());
    if (state.hasError && kDebugMode) {
      debugPrint('ArchiveQuotaNotifier.refresh: ${state.error}');
    }
  }
}

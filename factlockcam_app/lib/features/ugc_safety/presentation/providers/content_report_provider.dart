import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/locator.dart';
import '../../data/safety_repository.dart';
import '../../domain/models/block_origin_request.dart';
import '../../domain/models/content_report_reason.dart';

final safetyRepositoryProvider = Provider<SafetyRepository>(
  (ref) => getIt<SafetyRepository>(),
);

final contentReportProvider =
    AsyncNotifierProvider<ContentReportNotifier, void>(
  ContentReportNotifier.new,
);

class ContentReportNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Map<String, dynamic>> submitReport({
    required String packageId,
    required ContentReportReason reason,
    String? detail,
    String? reporterEmail,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await ref.read(safetyRepositoryProvider).reportCourierPackage(
            ContentReportRequest(
              packageId: packageId,
              reason: reason.rpcValue,
              detail: detail,
              reporterEmail: reporterEmail,
            ),
          );
      state = const AsyncData(null);
      return result;
    } catch (error, stack) {
      state = AsyncError(error, stack);
      rethrow;
    }
  }
}

final senderBlockProvider = AsyncNotifierProvider<SenderBlockNotifier, void>(
  SenderBlockNotifier.new,
);

class SenderBlockNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Map<String, dynamic>> blockSender({
    required String packageId,
    String? reporterEmail,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(safetyRepositoryProvider);
    final result = await repo.blockCourierSender(
      BlockOriginRequest(
        packageId: packageId,
        reporterEmail: reporterEmail,
      ),
    );
    state = const AsyncData(null);
    return result;
  }
}

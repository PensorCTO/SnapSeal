import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/models/block_origin_request.dart';
import '../../domain/models/content_report_reason.dart';
import '../providers/content_report_provider.dart';

Future<bool> showReportContentSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String packageId,
  String? reporterEmail,
}) async {
  final reason = await showCupertinoModalPopup<ContentReportReason>(
    context: context,
    builder: (sheetContext) {
      return CupertinoActionSheet(
        title: const Text('Report concerning content'),
        message: const Text(
          'Reports are reviewed within 24 hours. Sender identity is never '
          'disclosed to recipients.',
        ),
        actions: [
          for (final r in ContentReportReason.values)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop(r),
              child: Text(r.label),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('Cancel'),
        ),
      );
    },
  );

  if (reason == null || !context.mounted) return false;

  final detailController = TextEditingController();
  final confirmed = await showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return CupertinoAlertDialog(
        title: Text('Report: ${reason.label}'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: detailController,
            placeholder: 'Optional details',
            maxLines: 3,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Submit report'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    detailController.dispose();
    return false;
  }

  try {
    await ref.read(safetyRepositoryProvider).reportCourierPackage(
          ContentReportRequest(
            packageId: packageId,
            reason: reason.rpcValue,
            detail: detailController.text.trim().isEmpty
                ? null
                : detailController.text.trim(),
            reporterEmail: reporterEmail,
          ),
        );
    detailController.dispose();
    if (!context.mounted) return true;
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Report received'),
          content: Text(
            'Thank you. If you need immediate help, contact support at '
            '${AppConfig.supportUrl}.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return true;
  } catch (error) {
    detailController.dispose();
    if (!context.mounted) return false;
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Report failed'),
          content: Text(error.toString()),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return false;
  }
}

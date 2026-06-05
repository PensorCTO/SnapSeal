import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/content_report_provider.dart';

Future<bool> showBlockSenderDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String packageId,
  String? reporterEmail,
}) async {
  final confirmed = await showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return CupertinoAlertDialog(
        title: const Text('Block sender?'),
        content: const Text(
          'You will not receive future courier packages from this origin. '
          'The sender identity remains private.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Block sender'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) return false;

  try {
    await ref.read(senderBlockProvider.notifier).blockSender(
          packageId: packageId,
          reporterEmail: reporterEmail,
        );
    if (!context.mounted) return true;
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Sender blocked'),
          content: const Text(
            'Future packages from this origin will be unavailable to you.',
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
    if (!context.mounted) return false;
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Block failed'),
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

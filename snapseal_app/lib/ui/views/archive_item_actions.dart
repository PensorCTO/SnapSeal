import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/archive/domain/models/media_action_type.dart';
import '../../core/archive/presentation/widgets/universal_asset_toolbar.dart';
import '../../data/models/archive_item.dart';
import '../../domain/export/certificate_export_service.dart';
import '../controllers/dashboard_controller.dart';
import 'archive_photo_view.dart';
import 'archive_video_view.dart';

/// Shared bottom sheet + dialogs for archive rows (used by [ArchiveView]).
class ArchiveItemActions {
  const ArchiveItemActions._();

  static Future<void> showBottomSheet({
    required BuildContext context,
    required WidgetRef ref,
    required ArchiveItem item,
  }) async {
    if (!context.mounted) return;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: UniversalAssetToolbar(
              assetHash: item.assetFingerprint,
              mediaType: item.mimeType ?? 'unknown',
              confirmAction: (action) async {
                if (action != MediaActionType.delete) {
                  return true;
                }
                return _confirmDelete(context);
              },
              onActionCompleted: (action) async {
                switch (action) {
                  case MediaActionType.view:
                    if (!context.mounted) return;
                    _openVerifiedAsset(context, item);
                    break;
                  case MediaActionType.verify:
                    if (!context.mounted) return;
                    await _showVerifiedDialog(context);
                    break;
                  case MediaActionType.delete:
                    ref.invalidate(dashboardControllerProvider);
                    break;
                  case MediaActionType.share:
                  case MediaActionType.export:
                    break;
                }
              },
              additionalActions: [
                CupertinoActionSheetAction(
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await _showCertificateDraft(context, ref, item);
                  },
                  child: const Text('Certificate draft'),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await _showMetadataDialog(context, ref, item);
                  },
                  child: const Text('Manage title and description'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _openVerifiedAsset(BuildContext context, ArchiveItem item) {
    final isVideo = item.mimeType?.startsWith('video/') ?? false;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => isVideo
            ? ArchiveVideoView(item: item)
            : ArchivePhotoView(item: item),
      ),
    );
  }

  static Future<bool> _confirmDelete(BuildContext context) async {
    if (!context.mounted) {
      return false;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete sealed item?'),
        content: const Text(
          'This removes the encrypted copy and thumbnail from this device only. '
          'It does not remove proof rows on the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  static Future<void> _showVerifiedDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verification complete'),
        content: const Text(
          'The sealed bytes decrypted and matched the archived fingerprint.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Future<void> confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    ArchiveItem item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete sealed item?'),
        content: const Text(
          'This removes the encrypted copy and thumbnail from this device only. '
          'It does not remove proof rows on the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref
          .read(dashboardControllerProvider.notifier)
          .deleteArchiveItem(item.assetFingerprint);
    }
  }

  static Future<void> _showMetadataDialog(
    BuildContext context,
    WidgetRef ref,
    ArchiveItem item,
  ) async {
    final titleController = TextEditingController(text: item.title ?? '');
    final descriptionController = TextEditingController(
      text: item.description ?? '',
    );
    try {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Manage metadata'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (shouldSave == true && context.mounted) {
        await ref
            .read(dashboardControllerProvider.notifier)
            .updateArchiveMetadata(
              assetFingerprint: item.assetFingerprint,
              title: titleController.text,
              description: descriptionController.text,
            );
      }
    } finally {
      titleController.dispose();
      descriptionController.dispose();
    }
  }

  static Future<void> _showCertificateDraft(
    BuildContext context,
    WidgetRef ref,
    ArchiveItem item,
  ) async {
    final draft = ref
        .read(certificateExportServiceProvider)
        .buildCertificateDraft(item);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Certificate draft'),
        content: SingleChildScrollView(child: SelectableText(draft)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

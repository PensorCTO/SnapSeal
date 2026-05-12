import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isVideo = item.mimeType?.startsWith('video/') ?? false;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x26121212),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1.0,
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(
                        isVideo
                            ? Icons.play_circle_outline
                            : Icons.open_in_full_outlined,
                      ),
                      title: Text(
                        isVideo ? 'Play video' : 'View full-size photo',
                      ),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => isVideo
                                ? ArchiveVideoView(item: item)
                                : ArchivePhotoView(item: item),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: const Text('Certificate draft'),
                      subtitle: const Text(
                        'Includes legal disclosure text for future PDF export.',
                      ),
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await _showCertificateDraft(context, ref, item);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.edit_note_outlined),
                      title: const Text('Manage title and description'),
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await _showMetadataDialog(context, ref, item);
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        'Delete from this device',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      subtitle: const Text(
                        'Removes local files and metadata. Remote ledger rows are not removed.',
                      ),
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await confirmAndDelete(context, ref, item);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

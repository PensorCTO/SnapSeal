import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:share_plus/share_plus.dart';

import '../../core/archive/domain/models/media_action_type.dart';
import '../../core/archive/presentation/widgets/universal_asset_toolbar.dart';
import '../../core/di/service_providers.dart';
import '../../data/models/archive_item.dart';
import '../controllers/dashboard_controller.dart';
import 'archive/providers/courier_link_provider.dart';
import 'vault/providers/thumbnail_cache_provider.dart';
import 'archive_photo_view.dart';
import 'archive_video_view.dart';

/// Shared bottom sheet + dialogs for archive rows.
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
                    ref.invalidate(thumbnailCacheProvider(item.assetFingerprint));
                    await ref
                        .read(dashboardControllerProvider.notifier)
                        .refreshArchive();
                    break;
                  case MediaActionType.share:
                    if (!context.mounted) return;
                    await showSendProofDialog(context, ref, item);
                    break;
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

  static Future<void> showSendProofDialog(
    BuildContext context,
    WidgetRef ref,
    ArchiveItem item,
  ) async {
    final password = await _promptForRecipientPassword(context);
    if (password == null) {
      return;
    }
    if (password.isEmpty) {
      if (!context.mounted) return;
      await _showErrorDialog(context, 'Recipient password is required.');
      return;
    }

    if (!context.mounted) return;
    unawaited(_showLoadingDialog(context));

    try {
      final url = await ref
          .read(courierLinkProvider.notifier)
          .generateLink(item.assetFingerprint, password);
      final sealed = await ref
          .read(vaultServiceProvider)
          .extractForCourier(item.assetFingerprint);
      final bundleFile = await ref
          .read(proofBundleExportServiceProvider)
          .writeBundleToCache(
            item: item,
            sealed: sealed,
            courierUrl: url,
          );
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(bundleFile.path, mimeType: 'application/zip')],
          text: 'FactLockCam proof bundle\nCourier link: $url',
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await _showErrorDialog(context, _friendlyCourierError(error));
    }
  }

  static Future<String?> _promptForRecipientPassword(BuildContext context) {
    final controller = TextEditingController();
    return showCupertinoDialog<String>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Recipient Password'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: controller,
              autofocus: true,
              obscureText: true,
              placeholder: 'Enter password',
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
              child: const Text('Generate Link'),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  static Future<void> _showLoadingDialog(BuildContext context) {
    return showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CupertinoAlertDialog(
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CupertinoActivityIndicator(radius: 14),
        ),
      ),
    );
  }

  static Future<void> _showErrorDialog(BuildContext context, String message) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Could not send proof'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static String _friendlyCourierError(Object error) {
    final message = error.toString();
    if (message.contains('Supabase is not configured')) {
      return 'Supabase is not configured for this build.';
    }
    if (message.contains('No authenticated user')) {
      return 'Sign in before generating a courier link.';
    }
    if (message.contains('WEB_VAULT_BASE_URL is unset')) {
      return 'Courier links require WEB_VAULT_BASE_URL at compile time. '
          'Use VS Code launch "iOS (QA Tunnel)", or pass '
          '`--dart-define=WEB_VAULT_BASE_URL=https://YOUR_TUNNEL_ORIGIN`.';
    }
    if (message.contains('ERR_CONNECTION_REFUSED') ||
        message.contains('Connection refused')) {
      return 'The link used an unreachable host (often localhost, which '
          'only works on your dev machine). Run Flutter Web on port 3000 behind '
          'Ngrok and pass that HTTPS origin as WEB_VAULT_BASE_URL, rebuild '
          'FactLockCam, then regenerate the link.';
    }
    if (message.contains('Bucket not found')) {
      return 'Storage bucket "courier-blobs" is missing on this Supabase project. '
          'Deploy migrations (ensure '
          '`20260514220000_web_courier_schema` or '
          '`20260516000000_ensure_courier_blobs_storage_bucket`) '
          'or create the bucket in Storage settings, then retry.';
    }
    if (message.contains('row-level security') ||
        message.contains('row level security')) {
      return 'Upload was blocked by Supabase Storage security rules. Push migrations '
          'to this project — especially '
          '`20260517000000_repair_courier_storage_object_rls` (and '
          '`20260514220000_web_courier_schema`) '
          'so authenticated users may write objects under courier-blobs/{user-id}/, then retry.';
    }
    return message;
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
    final draft = await ref
        .read(certificateExportServiceProvider)
        .buildCertificateDraft(item);
    if (!context.mounted) return;
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

import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/archive/domain/models/media_action_type.dart';
import '../../core/archive/presentation/widgets/universal_asset_toolbar.dart';
import '../../core/di/service_providers.dart';
import '../../data/models/archive_item.dart';
import '../../features/archive_quota/presentation/interceptors/metering_credit_interceptor.dart';
import 'archive/certificate_studio_view.dart';
import 'archive_media_download.dart';
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
                    break;
                  case MediaActionType.delete:
                    ref.invalidate(thumbnailCacheProvider(item.assetFingerprint));
                    await ref
                        .read(dashboardControllerProvider.notifier)
                        .refreshArchive();
                    break;
                  case MediaActionType.share:
                    break;
                  case MediaActionType.export:
                    if (!context.mounted) return;
                    await downloadMedia(context, ref, item);
                    break;
                  case MediaActionType.printCertificate:
                    if (!context.mounted) return;
                    await openCertificateStudio(context, ref, item);
                    break;
                }
              },
            ),
          ),
        );
      },
    );
  }

  static Future<void> openCertificateStudio(
    BuildContext context,
    WidgetRef ref,
    ArchiveItem item,
  ) async {
    if (!context.mounted) return;
    final allowed = await ensureVerificationCreditForAction(context, ref);
    if (!allowed || !context.mounted) return;

    final resolved = _resolveArchiveItem(ref, item);
    await runMeteredVerificationAction(ref, () async {
      if (!context.mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => CertificateStudioView(item: resolved),
        ),
      );
    });
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

  static ArchiveItem _resolveArchiveItem(WidgetRef ref, ArchiveItem item) {
    final list = ref.read(dashboardControllerProvider).value;
    if (list != null) {
      for (final row in list) {
        if (row.assetFingerprint == item.assetFingerprint) {
          return row;
        }
      }
    }
    return item;
  }

  /// Decrypts the asset and opens the system share sheet with a plaintext copy.
  static Future<void> downloadMedia(
    BuildContext context,
    WidgetRef ref,
    ArchiveItem item,
  ) async {
    if (!context.mounted) return;

    final allowed = await ensureVerificationCreditForAction(context, ref);
    if (!allowed || !context.mounted) return;

    unawaited(_showLoadingDialog(context));

    await runMeteredVerificationAction(ref, () async {
      final sealed = await ref
          .read(vaultServiceProvider)
          .extractForCourier(item.assetFingerprint);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await shareDecryptedArchiveMedia(item: item, sealed: sealed);
    }).catchError((Object error) async {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await _showDownloadErrorDialog(context, error);
    });
  }

  static Future<void> _showDownloadErrorDialog(
    BuildContext context,
    Object error,
  ) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Could not download media'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(error.toString()),
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
}

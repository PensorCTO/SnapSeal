import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:share_plus/share_plus.dart';

import '../../core/archive/domain/models/media_action_type.dart';
import '../../core/marketing/approved_pitch.dart';
import '../../core/archive/presentation/widgets/universal_asset_toolbar.dart';
import '../../core/di/service_providers.dart';
import '../../data/models/archive_item.dart';
import '../../features/archive/presentation/providers/send_proof_provider.dart';
import '../../features/dispatch/presentation/dispatch_error_copy.dart';
import '../../features/ugc_safety/presentation/providers/content_report_provider.dart';
import '../../features/ugc_safety/presentation/widgets/report_content_sheet.dart';
import '../../features/archive_quota/presentation/interceptors/archive_quota_paywall.dart';
import '../../features/archive_quota/presentation/interceptors/metering_credit_interceptor.dart';
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

    String? courierPackageId;
    final safetyRepo = ref.read(safetyRepositoryProvider);
    if (safetyRepo.isConfigured) {
      try {
        courierPackageId =
            await safetyRepo.getOwnCourierPackageId(item.assetFingerprint);
      } catch (_) {
        courierPackageId = null;
      }
    }

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
                    if (!context.mounted) return;
                    await downloadMedia(context, ref, item);
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
                if (courierPackageId != null)
                  CupertinoActionSheetAction(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      if (!context.mounted) return;
                      await showReportContentSheet(
                        context: context,
                        ref: ref,
                        packageId: courierPackageId!,
                      );
                    },
                    child: const Text('Report shared proof'),
                  ),
                CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(
                    'Block recipient email (coming soon)',
                    style: TextStyle(
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                    ),
                  ),
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

  static Future<void> showSendProofDialog(
    BuildContext context,
    WidgetRef ref,
    ArchiveItem item,
  ) async {
    final resolvedItem = _resolveArchiveItem(ref, item);
    final form = await _promptForSendProofDetails(context);
    if (form == null) {
      return;
    }
    if (form.password.isEmpty) {
      if (!context.mounted) return;
      await _showErrorDialog(context, 'Recipient password is required.');
      return;
    }

    if (!context.mounted) return;
    if (!await ensureArchiveQuotaForSendProof(context, ref)) {
      return;
    }

    if (!context.mounted) return;
    unawaited(_showLoadingDialog(context));

    try {
      final result = await ref.read(sendProofProvider.notifier).send(
            SendProofRequest(
              item: resolvedItem,
              password: form.password,
            ),
          );

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              result.certificatePdfPath,
              mimeType: 'application/pdf',
              name: 'factlockcam-certificate.pdf',
            ),
          ],
          text:
              '$sendProofShareIntro${result.courierUrl}\n\n'
              'Share the password separately.\n\n'
              'Attached: tamper-proof certificate with asset hash and ledger details.',
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await _showErrorDialog(context, friendlyCourierDispatchError(error));
    }
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

  static Future<_SendProofForm?> _promptForSendProofDetails(
    BuildContext context,
  ) {
    final passwordController = TextEditingController();

    return showCupertinoDialog<_SendProofForm>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Send Proof'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Creates a tamper-proof certificate PDF and a password-protected web link. '
                    'You share both using Messages, Mail, or AirDrop — FactLockCam '
                    'does not send email.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: passwordController,
                    autofocus: true,
                    obscureText: true,
                    placeholder: 'Password for recipient',
                  ),
                ],
              ),
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
                Navigator.of(dialogContext).pop(
                  _SendProofForm(
                    password: passwordController.text.trim(),
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    ).whenComplete(passwordController.dispose);
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

class _SendProofForm {
  const _SendProofForm({required this.password});

  final String password;
}

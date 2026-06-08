import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/media_action_type.dart';
import '../../domain/services/asset_action_registry.dart';
import '../../../../features/archive/presentation/providers/asset_action_provider.dart';
import '../../../../features/archive_quota/presentation/interceptors/metering_credit_interceptor.dart';

class UniversalAssetToolbar extends ConsumerWidget {
  const UniversalAssetToolbar({
    super.key,
    required this.assetHash,
    required this.mediaType,
    this.confirmAction,
    this.onActionCompleted,
    this.additionalActions = const [],
  });

  final String assetHash;
  final String mediaType;
  final Future<bool> Function(MediaActionType action)? confirmAction;
  final FutureOr<void> Function(MediaActionType action)? onActionCompleted;
  final List<CupertinoActionSheetAction> additionalActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(assetActionProvider);
    final isBusy = actionState.isLoading;
    final actions = AssetActionRegistry.getActionsForType(mediaType);

    return RepaintBoundary(
      child: CupertinoActionSheet(
        title: const Text('Asset Actions'),
        message: Text(_messageForMediaType(mediaType)),
        actions: [
          for (final action in actions)
            CupertinoActionSheetAction(
              isDefaultAction: action == MediaActionType.view,
              isDestructiveAction: action == MediaActionType.delete,
              onPressed: () {
                if (isBusy) {
                  return;
                }
                unawaited(_handleAction(context, ref, action));
              },
              child: Text(_labelForAction(action, mediaType)),
            ),
          ...additionalActions,
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    MediaActionType action,
  ) async {
    Navigator.of(context).pop();
    final confirmed = await confirmAction?.call(action) ?? true;
    if (!confirmed) {
      return;
    }

    if (_requiresVerificationCredit(action)) {
      if (!context.mounted) {
        return;
      }
      final allowed = await ensureVerificationCreditForAction(context, ref);
      if (!allowed) {
        return;
      }
      if (action == MediaActionType.export) {
        await runMeteredVerificationAction(
          ref,
          () => ref
              .read(assetActionProvider.notifier)
              .executeAction(action, assetHash),
        );
      } else {
        await ref
            .read(assetActionProvider.notifier)
            .executeAction(action, assetHash);
      }
    } else {
      await ref
          .read(assetActionProvider.notifier)
          .executeAction(action, assetHash);
    }

    await onActionCompleted?.call(action);
  }

  static bool _requiresVerificationCredit(MediaActionType action) {
    return action == MediaActionType.export;
  }

  static String _messageForMediaType(String mediaType) {
    final normalized = mediaType.trim().toLowerCase();
    if (normalized.startsWith('video/') || normalized == 'video') {
      return 'Actions for this sealed video.';
    }
    if (normalized.startsWith('image/') ||
        normalized == 'picture' ||
        normalized == 'photo') {
      return 'Actions for this sealed picture.';
    }
    if (normalized == 'document' || normalized.startsWith('application/')) {
      return 'Actions for this sealed document.';
    }
    return 'Actions for this sealed asset.';
  }

  static String _labelForAction(MediaActionType action, String mediaType) {
    switch (action) {
      case MediaActionType.view:
        return _viewLabelForMediaType(mediaType);
      case MediaActionType.verify:
        return 'Verify integrity';
      case MediaActionType.delete:
        return 'Delete from this device';
      case MediaActionType.share:
        return 'Send Proof';
      case MediaActionType.export:
        return _exportLabelForMediaType(mediaType);
      case MediaActionType.printCertificate:
        return 'Print Certificate';
    }
  }

  static String _exportLabelForMediaType(String mediaType) {
    final normalized = mediaType.trim().toLowerCase();
    if (normalized.startsWith('video/') ||
        normalized == 'video' ||
        normalized.startsWith('image/') ||
        normalized == 'picture' ||
        normalized == 'photo') {
      return 'Download Media';
    }
    return 'Export';
  }

  static String _viewLabelForMediaType(String mediaType) {
    final normalized = mediaType.trim().toLowerCase();
    if (normalized.startsWith('video/') ||
        normalized == 'video' ||
        normalized.startsWith('image/') ||
        normalized == 'picture' ||
        normalized == 'photo') {
      return 'View/Play media';
    }
    if (normalized == 'document' || normalized.startsWith('application/')) {
      return 'View document';
    }
    return 'View';
  }
}

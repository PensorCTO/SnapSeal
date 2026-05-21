import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/platform/platform_channel_coordinator.dart';
import '../../../../data/models/archive_item.dart';
import '../../../../ui/controllers/dashboard_controller.dart';
import '../../data/archive_repository.dart';
import '../../../identity/presentation/providers/current_profile_provider.dart';
import '../../domain/models/archive_asset.dart';
import 'restore_archive_banner.dart';

class ArchiveGridItem extends ConsumerWidget {
  const ArchiveGridItem({
    super.key,
    required this.item,
    required this.onTap,
    this.thumbnail,
  });

  final ArchiveItem item;
  final VoidCallback onTap;
  final Widget? thumbnail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final activeWallet = profileAsync.maybeWhen(
      data: (profile) => profile.activeWalletAddress,
      orElse: () => null,
    );
    final asset = ref.watch(archiveRepositoryProvider).mapArchiveItem(
          item,
          activeWalletAddress: activeWallet,
        );

    if (asset.isLegacyPlaceholder && !asset.isLocallyAvailable) {
      return RestoreArchiveBanner(
        onRestoreTap: () => _promptRestore(context, ref, asset),
      );
    }

    if (asset.isLegacyPlaceholder) {
      return _HistoricalAssetTile(
        asset: asset,
        onTap: onTap,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: thumbnail ?? _StandardThumbnailFallback(item: item),
    );
  }

  Future<void> _promptRestore(
    BuildContext context,
    WidgetRef ref,
    ArchiveAsset asset,
  ) async {
    final bytes = await getIt<IPlatformChannelCoordinator>()
        .pickEncryptedBackupBytes();
    if (bytes == null || bytes.isEmpty) {
      return;
    }

    try {
      await ref.read(archiveRepositoryProvider).rehydratePlaceholderAsset(
            assetHash: asset.assetHash,
            backupBinaryPayload: bytes,
          );
      await ref.read(dashboardControllerProvider.notifier).refreshArchive();
      if (!context.mounted) {
        return;
      }
      await _showMessage(context, 'Digital archive restored.');
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      await _showMessage(context, 'Restore failed: $error');
    }
  }

  Future<void> _showMessage(BuildContext context, String message) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Digital Archive'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _HistoricalAssetTile extends StatelessWidget {
  const _HistoricalAssetTile({
    required this.asset,
    required this.onTap,
  });

  final ArchiveAsset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.titaniumDeep,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _mediaIcon(asset.mimeType),
                color: AppColors.verifiedNeon,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Historical Archive',
                style: AppTextStyles.monoSm(color: AppColors.starkWhite),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StandardThumbnailFallback extends StatelessWidget {
  const _StandardThumbnailFallback({required this.item});

  final ArchiveItem item;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.titaniumPanel,
      child: Center(
        child: Icon(
          _mediaIcon(item.mimeType),
          color: AppColors.starkWhite,
          size: 28,
        ),
      ),
    );
  }
}

IconData _mediaIcon(String? mimeType) {
  final mime = mimeType?.toLowerCase() ?? '';
  if (mime.startsWith('video/')) {
    return CupertinoIcons.videocam_fill;
  }
  if (mime.startsWith('audio/')) {
    return CupertinoIcons.waveform;
  }
  if (mime.contains('pdf') || mime.contains('document')) {
    return CupertinoIcons.doc_fill;
  }
  return CupertinoIcons.photo_fill;
}

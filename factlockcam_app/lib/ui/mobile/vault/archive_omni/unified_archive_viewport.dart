import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/ui/widgets/heavy_metal_backdrop.dart';
import '../../../../core/ui/widgets/vault_panel_navigation_bar.dart';
import '../../../../data/models/archive_item.dart';
import '../../../controllers/dashboard_controller.dart';
import '../../archive_item_actions.dart';
import '../asset_inspector_screen.dart';
import '../chronology_card.dart';
import '../swipe_action_layer.dart';
import 'omni_control_bar.dart';
import 'omni_grid_view.dart';
import 'providers/archive_prefs_provider.dart';

/// Unified Archive Omni-Surface — the archive tab (Tab Index 3) within the
/// vault shell.
///
/// Replaces the standalone ArchiveView and ChronologyViewport. Supports
/// toggling between a date-grouped Grid View and the haptic Chronology View,
/// with dynamic media-type filtering.
class UnifiedArchiveViewport extends ConsumerStatefulWidget {
  const UnifiedArchiveViewport({
    super.key,
    this.onCaptureRequested,
    this.onBackToHub,
  });

  /// When set, the Picture and Video empty-state tiles switch the parent
  /// shell index to 1 or 2 respectively.
  final ValueChanged<int>? onCaptureRequested;

  final VoidCallback? onBackToHub;

  @override
  ConsumerState<UnifiedArchiveViewport> createState() =>
      _UnifiedArchiveViewportState();
}

class _UnifiedArchiveViewportState extends ConsumerState<UnifiedArchiveViewport> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  bool _initialSyncTriggered = false;

  static const double _imageOverlapFraction = 0.75;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Trigger background sync once after the first frame.
    if (!_initialSyncTriggered) {
      _initialSyncTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(dashboardControllerProvider.notifier)
            .syncPendingInBackground();
      });
    }

    final filteredItems = ref.watch(filteredArchiveProvider);
    final prefs = ref.watch(archivePrefsProvider);

    return Scaffold(
      backgroundColor: AppColors.titaniumDeep,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.onBackToHub != null)
              VaultPanelNavigationBar(
                title: 'Vault',
                onBack: widget.onBackToHub!,
              ),
            // ── Logo bar ───────────────────────────────────────
            const HeavyMetalLogoBanner(),

            // ── Pending sync banner ────────────────────────────
            _PendingSyncBanner(),

            // ── Control bar (filter chips + view toggle) ───────
            const OmniControlBar(),

            // ── Main content ──────────────────────────────────
            Expanded(
              child: filteredItems.isEmpty
                  ? _EmptyState(
                      onCaptureRequested: widget.onCaptureRequested,
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: prefs.viewMode == ArchiveViewMode.grid
                          ? OmniGridView(key: const ValueKey('grid'), items: filteredItems)
                          : _buildChronologyView(filteredItems),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChronologyView(List<ArchiveItem> items) {
    return LayoutBuilder(
      key: const ValueKey('chronology'),
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight;

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 100,
          ),
          itemCount: items.length,
          itemExtent: (340.0 * (1 - _imageOverlapFraction)) + 340.0,
          itemBuilder: (context, index) {
            final item = items[index];
            final card = ChronologyCard(
              key: ValueKey(item.assetFingerprint),
              item: item,
              index: index,
              scrollOffset: _scrollOffset,
              viewportHeight: viewportHeight,
              onTap: () => _onTapCard(item),
            );

            return SwipeActionLayer(
              item: item,
              child: card,
              onShare: () => _onSwipeShare(item),
              onVerify: () => _onSwipeVerify(item),
            );
          },
        );
      },
    );
  }

  // ── Action handlers ──────────────────────────────────────────────────

  void _onTapCard(ArchiveItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AssetInspectorScreen(item: item),
      ),
    );
  }

  void _onSwipeShare(ArchiveItem item) {
    unawaited(ref.read(hapticServiceProvider).heavyImpact());
    if (!mounted) return;
    unawaited(
      ArchiveItemActions.showSendProofDialog(
        context,
        ref,
        item,
      ),
    );
  }

  void _onSwipeVerify(ArchiveItem item) {
    unawaited(ref.read(hapticServiceProvider).heavyImpact());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Verify: ${item.assetFingerprint.substring(0, 12)}'),
      ),
    );
  }
}

/// Pending sync banner extracted from ChronologyViewport.
class _PendingSyncBanner extends ConsumerWidget {
  const _PendingSyncBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archive = ref.watch(dashboardControllerProvider);
    return archive.when(
      data: (items) {
        final pendingCount = items.where((item) => item.pendingSync).length;
        if (pendingCount == 0) return const SizedBox.shrink();

        return MaterialBanner(
          backgroundColor: AppColors.titaniumPanel.withValues(alpha: 0.92),
          content: Text(
            '$pendingCount item(s) pending sync. '
            'We will keep retrying in the background.',
            style: AppTextStyles.monoSm(
              color: AppColors.alertAmber,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref
                    .read(dashboardControllerProvider.notifier)
                    .syncPendingInBackground();
              },
              child: Text(
                'RETRY NOW',
                style: AppTextStyles.monoSm(
                  color: AppColors.kineticGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
      error: (_, _) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }
}

/// Empty-state view when the vault contains no items matching the filter.
class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onCaptureRequested});

  final ValueChanged<int>? onCaptureRequested;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.shield_outlined,
          size: 64,
          color: AppColors.starkWhite.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 16),
        Text(
          'NO SEALED ASSETS',
          style: AppTextStyles.monoMd(
            color: AppColors.starkWhite.withValues(alpha: 0.42),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Capture a photo or video to begin.',
          style: AppTextStyles.monoSm(
            color: AppColors.starkWhite.withValues(alpha: 0.32),
          ),
        ),
        const SizedBox(height: 32),
        _QuickActionTile(
          icon: Icons.photo_camera_outlined,
          label: 'Picture',
          onTap: () => onCaptureRequested?.call(1),
        ),
        const SizedBox(height: 12),
        _QuickActionTile(
          icon: Icons.videocam_outlined,
          label: 'Video',
          onTap: () => onCaptureRequested?.call(2),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.titaniumHighlight,
              AppColors.titaniumPanel,
              Color(0xFF0A0A0A),
            ],
            stops: [0, 0.45, 1],
          ),
          border: Border.all(
            color: AppColors.verifiedNeon.withValues(alpha: 0.55),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: AppColors.verifiedNeon.withValues(alpha: 0.14),
            highlightColor: AppColors.verifiedNeon.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Row(
                children: [
                  Icon(icon, size: 24, color: AppColors.verifiedNeon),
                  const SizedBox(width: 14),
                  Text(
                    label.toUpperCase(),
                    style: AppTextStyles.monoMd(
                      color: AppColors.starkWhite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

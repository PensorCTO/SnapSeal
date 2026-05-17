import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/ui/widgets/heavy_metal_backdrop.dart';
import '../../../data/models/archive_item.dart';
import '../../controllers/dashboard_controller.dart';
import '../archive_view.dart';
import 'asset_inspector_screen.dart';
import 'chronology_card.dart';
import 'swipe_action_layer.dart';

// #region agent log
const _kDebugLog =
    '/Users/paulensor/Projects/ProofLockCleanup/.cursor/debug-4d5e77.log';
// #endregion

/// Haptic Chronology viewport — the Archive tab within the vault shell.
///
/// Displays sealed assets as a vertically scrolling stack of
/// [ChronologyCard] plates with scroll-driven Transform animations,
/// RepaintBoundary isolation, and off-thread thumbnail decoding.
class ChronologyViewport extends ConsumerStatefulWidget {
  const ChronologyViewport({super.key, this.onCaptureRequested});

  /// Called when the user taps the Picture or Video tile in the empty state.
  /// Receives the destination tab index: 1 for Picture, 2 for Video.
  final ValueChanged<int>? onCaptureRequested;

  static const routePath = '/vault-home';

  @override
  ConsumerState<ChronologyViewport> createState() =>
      _ChronologyViewportState();
}

class _ChronologyViewportState extends ConsumerState<ChronologyViewport>
    with HeavyMetalBackdropMixin<ChronologyViewport> {
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

    final archive = ref.watch(dashboardControllerProvider);

    // #region agent log
    archive.whenData((items) {
      try {
        File(_kDebugLog).writeAsStringSync(
          '${json.encode({
            'sessionId': '4d5e77',
            'runId': 'r1',
            'hypothesisId': 'C',
            'location': 'chronology_viewport.dart:build',
            'message': 'ChronologyViewport built',
            'data': {'itemCount': items.length, 'isEmpty': items.isEmpty},
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          })}\n',
          mode: FileMode.append,
        );
      } catch (_) {}
    });
    // #endregion

    return Scaffold(
      backgroundColor: AppColors.titaniumDeep,
      body: SafeArea(
        child: Column(
          children: [
            // ── Logo bar ───────────────────────────────────
            const HeavyMetalLogoBanner(),

            // ── Pending sync banner ──────────────────────────
            archive.when(
              data: (items) {
                final pendingCount =
                    items.where((item) => item.pendingSync).length;
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
              error: (_err, __) => const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
            ),

            // ── Chronology scroll + action tiles ────────────
            Expanded(
              child: archive.when(
                data: (items) => _buildContent(context, items),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      error.toString(),
                      style: AppTextStyles.monoSm(
                        color: AppColors.alertAmber,
                      ),
                    ),
                  ),
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.verifiedNeon,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<ArchiveItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight;

        if (items.isEmpty) {
          return _EmptyState(
            onCaptureRequested: widget.onCaptureRequested,
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 100,
          ),
          itemCount: items.length,
          // Overlap items so they stack physically.
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
    // Haptic already fired by SwipeActionLayer.
    unawaited(ref.read(hapticServiceProvider).heavyImpact());
    // TODO: Wire courier share flow — see courier_link_provider.dart
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share: ${item.assetFingerprint.substring(0, 12)}'),
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

/// Empty-state view when the vault contains no sealed assets.
class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onCaptureRequested});

  /// When set, the Picture and Video tiles switch the parent bottom-nav tab
  /// to index 1 or 2 respectively.
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
        const SizedBox(height: 12),
        _QuickActionTile(
          icon: Icons.folder_open_outlined,
          label: 'Vault',
          onTap: () => context.push(ArchiveView.routePath),
        ),
      ],
    );
  }
}

/// Compact hub tile used in the empty state.
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

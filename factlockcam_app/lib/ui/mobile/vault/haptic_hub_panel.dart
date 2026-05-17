import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/ui/widgets/heavy_metal_backdrop.dart';
import '../../controllers/dashboard_controller.dart';

/// Heavy Metal hub panel — the Home tab inside the vault shell.
///
/// Displays three hardware-styled action tiles (Vault, Picture, Video) over
/// a paused animated video backdrop ([HeavyMetalBackdropMixin]). Each tile
/// triggers a heavy haptic and replays the backdrop from its first frame.
class HapticHubPanel extends ConsumerStatefulWidget {
  const HapticHubPanel({super.key, this.onCaptureRequested});

  /// Called when the user taps the Picture (1) or Video (2) tile to switch
  /// the parent bottom-nav tab.
  final ValueChanged<int>? onCaptureRequested;

  @override
  ConsumerState<HapticHubPanel> createState() => _HapticHubPanelState();
}

class _HapticHubPanelState extends ConsumerState<HapticHubPanel>
    with HeavyMetalBackdropMixin<HapticHubPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(dashboardControllerProvider.notifier).syncPendingInBackground();
    });
  }

  void _handleHubTap(VoidCallback action) {
    unawaited(ref.read(hapticServiceProvider).lock());
    unawaited(playBackdropFromStart());
    action();
  }

  @override
  Widget build(BuildContext context) {
    final archive = ref.watch(dashboardControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.titaniumDeep,
      body: Column(
        children: [
          HeavyMetalLogoBanner(
            child: Image.asset(
              'assets/images/factlockcam_logoheader.jpg',
              fit: BoxFit.contain,
            ),
          ),
          archive.when(
            data: (items) {
              final pendingCount =
                  items.where((item) => item.pendingSync).length;
              if (pendingCount == 0) return const SizedBox.shrink();

              return MaterialBanner(
                backgroundColor:
                    AppColors.titaniumPanel.withValues(alpha: 0.92),
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
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                BackgroundVideoLayer(
                  controller: backdropController,
                  ready: backdropReady,
                ),
                const TitaniumOverlay(),
                SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'CHOOSE AN ACTION',
                              style: AppTextStyles.monoMd(
                                color:
                                    AppColors.starkWhite.withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _HubTile(
                              icon: Icons.folder_open_outlined,
                              label: 'Vault',
                              subtitle: 'Browse photos and videos on this device',
              onTap: () => _handleHubTap(
                () => widget.onCaptureRequested?.call(3),
              ),
                            ),
                            const SizedBox(height: 12),
                            _HubTile(
                              icon: Icons.photo_camera_outlined,
                              label: 'Picture',
                              subtitle: 'Capture a still',
                              onTap: () => _handleHubTap(
                                () => widget.onCaptureRequested?.call(1),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _HubTile(
                              icon: Icons.videocam_outlined,
                              label: 'Video',
                              subtitle: 'Record a clip',
                              onTap: () => _handleHubTap(
                                () => widget.onCaptureRequested?.call(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Heavy-metal hardware-styled tile: titanium gradient surface, hairline
/// specular highlight along the top edge, Verified Neon outer stroke, and
/// mono uppercase label.
class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '${label.toUpperCase()}. $subtitle',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
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
          boxShadow: [
            BoxShadow(
              color: AppColors.verifiedNeon.withValues(alpha: 0.08),
              blurRadius: 18,
              spreadRadius: 0.5,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: AppColors.verifiedNeon.withValues(alpha: 0.14),
            highlightColor: AppColors.verifiedNeon.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              child: Row(
                children: [
                  _HardwareIcon(icon: icon),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: AppTextStyles.monoMd(
                            color: AppColors.starkWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                AppColors.starkWhite.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.titaniumHighlight,
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

class _HardwareIcon extends StatelessWidget {
  const _HardwareIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF1F1F1F), Color(0xFF0A0A0A)],
          stops: [0.4, 1],
        ),
        border: Border.all(
          color: AppColors.verifiedNeon.withValues(alpha: 0.75),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.verifiedNeon.withValues(alpha: 0.18),
            blurRadius: 10,
          ),
        ],
      ),
      child: Icon(icon, size: 26, color: AppColors.verifiedNeon),
    );
  }
}

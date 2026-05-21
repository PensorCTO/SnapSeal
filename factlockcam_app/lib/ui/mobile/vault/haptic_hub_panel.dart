import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/ui/widgets/heavy_metal_backdrop.dart';
import '../../controllers/dashboard_controller.dart';

/// Heavy Metal hub panel — centered four-tile launcher for the vault shell.
class HapticHubPanel extends ConsumerStatefulWidget {
  const HapticHubPanel({super.key, this.onHubDestinationSelected});

  /// Picture=1, Video=2, Vault/archive=3, Account=4.
  final ValueChanged<int>? onHubDestinationSelected;

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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: _HubTileLauncher(
                              compact: constraints.maxHeight < 420 ||
                                  constraints.maxWidth >
                                      constraints.maxHeight * 1.1,
                              onVault: () => _handleHubTap(
                                () => widget.onHubDestinationSelected?.call(3),
                              ),
                              onPicture: () => _handleHubTap(
                                () => widget.onHubDestinationSelected?.call(1),
                              ),
                              onVideo: () => _handleHubTap(
                                () => widget.onHubDestinationSelected?.call(2),
                              ),
                              onAccount: () => _handleHubTap(
                                () => widget.onHubDestinationSelected?.call(4),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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

/// Four hub destinations — 2×2 grid when space is tight (landscape), else column.
class _HubTileLauncher extends StatelessWidget {
  const _HubTileLauncher({
    required this.compact,
    required this.onVault,
    required this.onPicture,
    required this.onVideo,
    required this.onAccount,
  });

  final bool compact;
  final VoidCallback onVault;
  final VoidCallback onPicture;
  final VoidCallback onVideo;
  final VoidCallback onAccount;

  static const _spacing = 12.0;

  @override
  Widget build(BuildContext context) {
    final vault = _HubTile(
      compact: compact,
      icon: Icons.folder_open_outlined,
      label: 'Vault',
      subtitle: 'Browse photos and videos on this device',
      onTap: onVault,
    );
    final picture = _HubTile(
      compact: compact,
      icon: Icons.photo_camera_outlined,
      label: 'Picture',
      subtitle: 'Capture a still',
      onTap: onPicture,
    );
    final video = _HubTile(
      compact: compact,
      icon: Icons.videocam_outlined,
      label: 'Video',
      subtitle: 'Record a clip',
      onTap: onVideo,
    );
    final account = _HubTile(
      compact: compact,
      icon: Icons.settings_outlined,
      label: 'Account & Settings',
      subtitle: 'Logout, legal, delete account',
      onTap: onAccount,
    );

    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: vault),
              const SizedBox(width: _spacing),
              Expanded(child: picture),
            ],
          ),
          const SizedBox(height: _spacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: video),
              const SizedBox(width: _spacing),
              Expanded(child: account),
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        vault,
        const SizedBox(height: _spacing),
        picture,
        const SizedBox(height: _spacing),
        video,
        const SizedBox(height: _spacing),
        account,
      ],
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
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool compact;

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
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 18,
                vertical: compact ? 12 : 22,
              ),
              child: Row(
                children: [
                  _HardwareIcon(icon: icon, compact: compact),
                  SizedBox(width: compact ? 10 : 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: compact
                              ? AppTextStyles.monoSm(
                                  color: AppColors.starkWhite,
                                )
                              : AppTextStyles.monoMd(
                                  color: AppColors.starkWhite,
                                ),
                          maxLines: compact ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: compact ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                AppColors.starkWhite.withValues(alpha: 0.62),
                            fontSize: compact ? 11 : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: compact ? 20 : 24,
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
  const _HardwareIcon({required this.icon, this.compact = false});

  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 40.0 : 52.0;
    final iconSize = compact ? 20.0 : 26.0;
    return Container(
      width: size,
      height: size,
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
      child: Icon(icon, size: iconSize, color: AppColors.verifiedNeon),
    );
  }
}

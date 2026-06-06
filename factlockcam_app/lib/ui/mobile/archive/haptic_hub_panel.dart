import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/di/service_providers.dart';
import '../../../core/marketing/approved_pitch.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/ui/widgets/heavy_metal_backdrop.dart';
import '../../../core/ui/widgets/heavy_metal_hub_tile.dart';
import '../../controllers/dashboard_controller.dart';

/// Heavy Metal hub panel — centered four-tile launcher for the archive shell.
class HapticHubPanel extends ConsumerStatefulWidget {
  const HapticHubPanel({super.key, this.onHubDestinationSelected});

  /// Picture=1, Video=2, Archive=3, Account=4, Secure Comm=5.
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
      if (!kIsWeb) {
        unawaited(ref.read(secureCommCameraPoolProvider).warmFrontCamera());
      }
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
          const HeavyMetalLogoBanner(),
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
                      final compact = constraints.maxHeight < 440 ||
                          constraints.maxWidth >
                              constraints.maxHeight * 1.05;

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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                archive.when(
                                  data: (items) {
                                    final pendingCount = items
                                        .where((item) => item.pendingSync)
                                        .length;
                                    if (pendingCount == 0) {
                                      return const SizedBox.shrink();
                                    }

                                    if (compact) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '$pendingCount PENDING SYNC',
                                                style: AppTextStyles.monoSm(
                                                  color: AppColors.alertAmber,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                ref
                                                    .read(
                                                      dashboardControllerProvider
                                                          .notifier,
                                                    )
                                                    .syncPendingInBackground();
                                              },
                                              child: Text(
                                                'RETRY',
                                                style: AppTextStyles.monoSm(
                                                  color: AppColors.kineticGreen,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return MaterialBanner(
                                      backgroundColor: AppColors.titaniumPanel
                                          .withValues(alpha: 0.92),
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
                                                .read(
                                                  dashboardControllerProvider
                                                      .notifier,
                                                )
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
                                _HubTileLauncher(
                                  compact: compact,
                                  captureEnabled: !kIsWeb,
                                  onArchive: () => _handleHubTap(
                                    () => widget.onHubDestinationSelected
                                        ?.call(3),
                                  ),
                                  onPicture: () => _handleHubTap(
                                    () => widget.onHubDestinationSelected
                                        ?.call(1),
                                  ),
                                  onVideo: () => _handleHubTap(
                                    () => widget.onHubDestinationSelected
                                        ?.call(2),
                                  ),
                                  onAccount: () => _handleHubTap(
                                    () => widget.onHubDestinationSelected
                                        ?.call(4),
                                  ),
                                  onSecureComm: () => _handleHubTap(
                                    () => widget.onHubDestinationSelected
                                        ?.call(5),
                                  ),
                                ),
                              ],
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
    required this.captureEnabled,
    required this.onArchive,
    required this.onPicture,
    required this.onVideo,
    required this.onAccount,
    required this.onSecureComm,
  });

  final bool compact;
  final bool captureEnabled;
  final VoidCallback onArchive;
  final VoidCallback onPicture;
  final VoidCallback onVideo;
  final VoidCallback onAccount;
  final VoidCallback onSecureComm;

  static const _spacing = 12.0;

  @override
  Widget build(BuildContext context) {
    final archive = HeavyMetalHubTile(
      compact: compact,
      icon: Icons.archive_outlined,
      label: 'Archive',
      subtitle: archiveHubSubtitle,
      onTap: onArchive,
    );
    final picture = HeavyMetalHubTile(
      compact: compact,
      icon: Icons.photo_camera_outlined,
      label: 'Picture',
      subtitle: 'Capture a still',
      onTap: onPicture,
    );
    final video = HeavyMetalHubTile(
      compact: compact,
      icon: Icons.videocam_outlined,
      label: 'Video',
      subtitle: 'Record a clip',
      onTap: onVideo,
    );
    final account = HeavyMetalHubTile(
      compact: compact,
      icon: Icons.settings_outlined,
      label: 'Account & Settings',
      subtitle: 'Logout, legal, delete account',
      onTap: onAccount,
    );
    final secureComm = HeavyMetalHubTile(
      compact: compact,
      icon: Icons.lock_outline,
      label: 'Secure Comm',
      subtitle: secureCommHubSubtitle,
      onTap: onSecureComm,
    );

    if (!captureEnabled) {
      if (compact) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: archive),
                const SizedBox(width: _spacing),
                Expanded(child: account),
              ],
            ),
            const SizedBox(height: _spacing),
            secureComm,
          ],
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          archive,
          const SizedBox(height: _spacing),
          account,
          const SizedBox(height: _spacing),
          secureComm,
        ],
      );
    }

    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: archive),
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
          const SizedBox(height: _spacing),
          secureComm,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        archive,
        const SizedBox(height: _spacing),
        picture,
        const SizedBox(height: _spacing),
        video,
        const SizedBox(height: _spacing),
        account,
        const SizedBox(height: _spacing),
        secureComm,
      ],
    );
  }
}

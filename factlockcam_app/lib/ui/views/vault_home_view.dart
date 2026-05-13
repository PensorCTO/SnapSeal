import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/haptic_service.dart';
import '../../core/ui/widgets/heavy_metal_backdrop.dart';
import '../../data/models/archive_item.dart';
import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import 'archive_view.dart';
import 'camera/acquisition_mode.dart';
import 'camera/camera_view.dart';
import 'logon_view.dart';

/// Post-login Heavy Metal dashboard. A muted, paused video clip sits behind a
/// titanium gradient and three hardware-styled action tiles (Archive, Picture,
/// Video). Tapping any tile fires a heavy haptic, seeks the clip to its first
/// frame, plays it once, and then auto-pauses when playback completes.
class VaultHomeView extends ConsumerStatefulWidget {
  const VaultHomeView({super.key});

  static const routePath = '/vault-home';

  @override
  ConsumerState<VaultHomeView> createState() => _VaultHomeViewState();
}

class _VaultHomeViewState extends ConsumerState<VaultHomeView>
    with HeavyMetalBackdropMixin<VaultHomeView> {
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

  Future<void> _openCamera(AcquisitionMode mode) async {
    final location = Uri(
      path: CameraView.routePath,
      queryParameters: {'mode': mode.queryValue},
    ).toString();
    await context.push<bool>(location);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final archive = ref.watch(dashboardControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.titaniumDeep,
      body: Column(
        children: [
          HeavyMetalLogoBanner(
            actions: [
              PopupMenuButton<String>(
                tooltip: 'More',
                icon: const Icon(Icons.more_vert, color: AppColors.starkWhite),
                onSelected: (value) async {
                  if (value == 'burn') {
                    await ref
                        .read(dashboardControllerProvider.notifier)
                        .burnLocalWallet();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'burn',
                    child: ListTile(
                      leading: Icon(Icons.local_fire_department_outlined),
                      title: Text('Burn local wallet'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Sign out',
                color: AppColors.starkWhite,
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go(LogonView.routePath);
                  }
                },
                icon: const Icon(Icons.logout),
              ),
            ],
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
                  child: archive.when(
                    data: (items) => _buildContent(theme, items),
                    error: (error, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          error.toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(
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
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, List<ArchiveItem> items) {
    final pendingCount = items.where((item) => item.pendingSync).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pendingCount > 0)
          MaterialBanner(
            backgroundColor: AppColors.titaniumPanel.withValues(alpha: 0.92),
            content: Text(
              '$pendingCount item(s) pending sync. We will keep retrying in '
              'the background.',
              style: theme.textTheme.bodyMedium?.copyWith(
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
                child: const Text('Retry now'),
              ),
            ],
          ),
        // Spacer leaves a clear band of video visible between the logo
        // banner and the action tiles. The tiles dock toward the bottom.
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
                  color: AppColors.starkWhite.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 16),
              _HubTile(
                icon: Icons.folder_open_outlined,
                label: 'Archive',
                subtitle: 'Browse photos and videos on this device',
                onTap: () =>
                    _handleHubTap(() => context.push(ArchiveView.routePath)),
              ),
              const SizedBox(height: 12),
              _HubTile(
                icon: Icons.photo_camera_outlined,
                label: 'Picture',
                subtitle: 'Capture a still',
                onTap: () =>
                    _handleHubTap(() => _openCamera(AcquisitionMode.photo)),
              ),
              const SizedBox(height: 12),
              _HubTile(
                icon: Icons.videocam_outlined,
                label: 'Video',
                subtitle: 'Record a clip',
                onTap: () =>
                    _handleHubTap(() => _openCamera(AcquisitionMode.video)),
              ),
            ],
          ),
        ),
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
                            color: AppColors.starkWhite.withValues(alpha: 0.62),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import 'archive_view.dart';
import 'camera/acquisition_mode.dart';
import 'camera/camera_view.dart';
import 'logon_view.dart';

/// Post-login hub: Archive, Picture, or Video capture.
class VaultHomeView extends ConsumerStatefulWidget {
  const VaultHomeView({super.key});

  static const routePath = '/vault-home';

  @override
  ConsumerState<VaultHomeView> createState() => _VaultHomeViewState();
}

class _VaultHomeViewState extends ConsumerState<VaultHomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(dashboardControllerProvider.notifier).syncPendingInBackground();
    });
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
      appBar: AppBar(
        title: const Text('SnapSeal'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) async {
              if (value == 'burn') {
                await ref
                    .read(dashboardControllerProvider.notifier)
                    .burnLocalWallet();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
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
      body: archive.when(
        data: (items) {
          final pendingCount = items.where((i) => i.pendingSync).length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (pendingCount > 0)
                MaterialBanner(
                  content: Text(
                    '$pendingCount item(s) pending sync. We will keep retrying in the background.',
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    Text(
                      'Choose an action',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _HubTile(
                      icon: Icons.folder_open_outlined,
                      label: 'Archive',
                      subtitle: 'Browse photos and videos on this device',
                      onTap: () => context.push(ArchiveView.routePath),
                    ),
                    const SizedBox(height: 12),
                    _HubTile(
                      icon: Icons.photo_camera_outlined,
                      label: 'Picture',
                      subtitle: 'Capture a still',
                      onTap: () => _openCamera(AcquisitionMode.photo),
                    ),
                    const SizedBox(height: 12),
                    _HubTile(
                      icon: Icons.videocam_outlined,
                      label: 'Video',
                      subtitle: 'Record a clip',
                      onTap: () => _openCamera(AcquisitionMode.video),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        error: (e, _) => Center(child: Text(e.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

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
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Icon(icon, size: 44, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

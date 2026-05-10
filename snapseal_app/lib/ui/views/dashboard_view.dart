import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import 'camera/camera_view.dart';
import 'logon_view.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  static const routePath = '/dashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archive = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SnapSeal Wallet'),
        actions: [
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
          if (items.isEmpty) {
            return const _EmptyWallet();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: GridTile(
                  footer: ColoredBox(
                    color: Colors.black54,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        item.pendingSync
                            ? '${item.assetFingerprint.substring(0, 12)} (pending)'
                            : item.assetFingerprint.substring(0, 12),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  child: Image.file(
                    File(item.thumbnailPath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              );
            },
          );
        },
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'capture-fab',
            onPressed: () async {
              await context.push<bool>(CameraView.routePath);
            },
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Capture'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'burn-fab',
            onPressed: () async {
              await ref
                  .read(dashboardControllerProvider.notifier)
                  .burnLocalWallet();
            },
            icon: const Icon(Icons.local_fire_department_outlined),
            label: const Text('Burn local wallet'),
          ),
        ],
      ),
    );
  }
}

class _EmptyWallet extends StatelessWidget {
  const _EmptyWallet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('Vault ready', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                'Captured media will be hashed, encrypted, indexed locally, '
                'and displayed here through lightweight thumbnails.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

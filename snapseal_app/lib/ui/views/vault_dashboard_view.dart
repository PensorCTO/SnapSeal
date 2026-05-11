import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/archive_item.dart';
import '../../domain/export/certificate_export_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import 'archive_video_view.dart';
import 'camera/acquisition_mode.dart';
import 'camera/camera_view.dart';
import 'logon_view.dart';

/// Vault-first home: local SQLite metadata + thumbnails; capture via FAB.
class VaultDashboardView extends ConsumerStatefulWidget {
  const VaultDashboardView({super.key});

  static const routePath = '/vault-dashboard';

  @override
  ConsumerState<VaultDashboardView> createState() => _VaultDashboardViewState();
}

class _VaultDashboardViewState extends ConsumerState<VaultDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(dashboardControllerProvider.notifier).syncPendingInBackground();
    });
  }

  @override
  Widget build(BuildContext context) {
    final archive = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
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
          final pendingCount = items.where((item) => item.pendingSync).length;
          if (items.isEmpty) {
            return const _EmptyVault();
          }

          return Column(
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
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isVideo = item.mimeType?.startsWith('video/') ?? false;
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _onArchiveItemTap(item),
                        child: GridTile(
                          footer: ColoredBox(
                            color: Colors.black54,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.title != null && item.title!.isNotEmpty)
                                    Text(
                                      item.title!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  Text(
                                    item.pendingSync
                                        ? '${item.assetFingerprint.substring(0, 12)} (pending)'
                                        : item.assetFingerprint.substring(0, 12),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(item.thumbnailPath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    ColoredBox(
                                  color: Colors.black26,
                                  child: Icon(
                                    isVideo
                                        ? Icons.videocam_outlined
                                        : Icons.image_not_supported_outlined,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                              if (isVideo)
                                const Center(
                                  child: _VideoBadge(),
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
          );
        },
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.extended(
                heroTag: 'capture-photo-fab',
                onPressed: () => _openCamera(AcquisitionMode.photo),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Photo'),
              ),
              const SizedBox(width: 12),
              FloatingActionButton.extended(
                heroTag: 'capture-video-fab',
                onPressed: () => _openCamera(AcquisitionMode.video),
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Video'),
              ),
            ],
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

  Future<void> _openCamera(AcquisitionMode mode) async {
    final location = Uri(
      path: CameraView.routePath,
      queryParameters: {'mode': mode.queryValue},
    ).toString();
    await context.push<bool>(location);
  }

  Future<void> _onArchiveItemTap(ArchiveItem item) async {
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final isVideo = item.mimeType?.startsWith('video/') ?? false;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isVideo)
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: const Text('Play video'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(this.context).push(
                      MaterialPageRoute(
                        builder: (_) => ArchiveVideoView(item: item),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Certificate draft'),
                subtitle: const Text(
                  'Includes legal disclosure text for future PDF export.',
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _showCertificateDraft(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note_outlined),
                title: const Text('Manage title and description'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _showMetadataDialog(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showMetadataDialog(ArchiveItem item) async {
    final titleController = TextEditingController(text: item.title ?? '');
    final descriptionController =
        TextEditingController(text: item.description ?? '');
    try {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Manage metadata'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (shouldSave == true && mounted) {
        await ref.read(dashboardControllerProvider.notifier).updateArchiveMetadata(
              assetFingerprint: item.assetFingerprint,
              title: titleController.text,
              description: descriptionController.text,
            );
      }
    } finally {
      titleController.dispose();
      descriptionController.dispose();
    }
  }

  Future<void> _showCertificateDraft(ArchiveItem item) async {
    final draft = ref
        .read(certificateExportServiceProvider)
        .buildCertificateDraft(item);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Certificate draft'),
        content: SingleChildScrollView(child: SelectableText(draft)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _VideoBadge extends StatelessWidget {
  const _VideoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.play_arrow,
        color: Colors.white,
        size: 36,
      ),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  const _EmptyVault();

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
                Icons.folder_special_outlined,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('Evidence vault', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                'Sealed media is indexed here from local metadata and '
                'lightweight thumbnails. Capture new evidence from the camera.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

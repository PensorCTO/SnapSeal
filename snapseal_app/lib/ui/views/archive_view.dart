import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/archive_item.dart';
import '../controllers/dashboard_controller.dart';
import 'archive_item_actions.dart';
import 'vault_home_view.dart';

/// Local archive: photos and videos in separate tabs with thumbnails and delete.
class ArchiveView extends ConsumerStatefulWidget {
  const ArchiveView({super.key});

  static const routePath = '/archive';

  @override
  ConsumerState<ArchiveView> createState() => _ArchiveViewState();
}

class _ArchiveViewState extends ConsumerState<ArchiveView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(dashboardControllerProvider.notifier).syncPendingInBackground();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final archive = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(VaultHomeView.routePath),
        ),
        title: const Text('Archive'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Photos'),
            Tab(text: 'Videos'),
          ],
        ),
      ),
      body: archive.when(
        data: (items) {
          final pendingCount = items.where((i) => i.pendingSync).length;
          final photos = items
              .where((i) => !(i.mimeType?.startsWith('video/') ?? false))
              .toList(growable: false);
          final videos = items
              .where((i) => i.mimeType?.startsWith('video/') ?? false)
              .toList(growable: false);

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
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ArchiveGrid(
                      items: photos,
                      emptyLabel: 'No photos yet',
                      showVideoBadge: false,
                      onOpenItem: (item) => ArchiveItemActions.showBottomSheet(
                        context: context,
                        ref: ref,
                        item: item,
                      ),
                    ),
                    _ArchiveGrid(
                      items: videos,
                      emptyLabel: 'No videos yet',
                      showVideoBadge: true,
                      onOpenItem: (item) => ArchiveItemActions.showBottomSheet(
                        context: context,
                        ref: ref,
                        item: item,
                      ),
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

class _ArchiveGrid extends StatelessWidget {
  const _ArchiveGrid({
    required this.items,
    required this.emptyLabel,
    required this.showVideoBadge,
    required this.onOpenItem,
  });

  final List<ArchiveItem> items;
  final String emptyLabel;
  final bool showVideoBadge;
  final void Function(ArchiveItem item) onOpenItem;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(emptyLabel));
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
          child: InkWell(
            onTap: () => onOpenItem(item),
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
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: Colors.black26,
                      child: Icon(
                        showVideoBadge
                            ? Icons.videocam_outlined
                            : Icons.image_not_supported_outlined,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  if (showVideoBadge) const Center(child: _VideoBadge()),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black45,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.white),
                        tooltip: 'Actions',
                        onPressed: () => onOpenItem(item),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

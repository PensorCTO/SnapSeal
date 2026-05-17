import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../data/models/archive_item.dart';
import '../../archive_item_actions.dart';
import '../../archive_thumbnail.dart';

/// Date-grouped sliver grid for the Omni-Surface.
///
/// Groups sealed assets by "Month Year" using [item.createdAt] and renders
/// each group as a sticky month header followed by a [SliverGrid] of
/// thumbnail cells.
class OmniGridView extends ConsumerWidget {
  const OmniGridView({super.key, required this.items});

  final List<ArchiveItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group by Month/Year
    final grouped = _groupByMonth(items);
    final crossAxisCount = MediaQuery.of(context).size.width > 600 ? 4 : 3;

    return CustomScrollView(
      slivers: [
        for (final group in grouped) ...[
          // Sticky month header
          SliverToBoxAdapter(
            child: _MonthHeader(
              label: group.key,
              count: group.items.length,
            ),
          ),
          // Grid for this month group
          SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = group.items[index];
                final isVideo = item.mimeType?.startsWith('video/') ?? false;
                return RepaintBoundary(
                  child: GestureDetector(
                    onTap: () {
                      ArchiveItemActions.showBottomSheet(
                        context: context,
                        ref: ref,
                        item: item,
                      );
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ArchiveThumbnail(
                          thumbnailPath: item.thumbnailPath,
                          showVideoBadge: isVideo,
                        ),
                        if (isVideo)
                          const Center(
                            child: _VideoPlayBadge(),
                          ),
                        // Top-right pending badge
                        if (item.pendingSync)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.alertAmber,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SYNC',
                                style: AppTextStyles.monoSm(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        // Bottom hash label
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                            child: Text(
                              _shortHash(item.assetFingerprint),
                              style: AppTextStyles.monoSm(
                                color: AppColors.starkWhite,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: group.items.length,
            ),
          ),
        ],
      ],
    );
  }

  String _shortHash(String hash) =>
      hash.length > 10 ? hash.substring(0, 10) : hash;

  List<_MonthGroup> _groupByMonth(List<ArchiveItem> items) {
    final map = <String, List<ArchiveItem>>{};
    for (final item in items) {
      final key = _monthYearKey(item.createdAt);
      map.putIfAbsent(key, () => []).add(item);
    }
    // Sort groups chronologically descending (newest month first)
    final keys = map.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return keys.map((k) => _MonthGroup(key: k, items: map[k]!)).toList();
  }

  String _monthYearKey(DateTime dt) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

class _MonthGroup {
  const _MonthGroup({required this.key, required this.items});
  final String key;
  final List<ArchiveItem> items;
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.monoMd(
              color: AppColors.starkWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.titaniumHighlight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.monoSm(
                color: AppColors.starkWhite.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayBadge extends StatelessWidget {
  const _VideoPlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.play_arrow,
        color: AppColors.starkWhite,
        size: 28,
      ),
    );
  }
}

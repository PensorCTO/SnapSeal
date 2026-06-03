import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import 'providers/archive_prefs_provider.dart';

/// Top-pinned control bar for the Omni-Surface.
///
/// Displays horizontal-scrolling filter chips on the left and a
/// Cupertino-style segmented control for grid/chronology toggle on the right.
class OmniControlBar extends ConsumerWidget {
  const OmniControlBar({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(archivePrefsProvider);

    return Container(
      height: compact ? 48 : 60,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.titaniumPanel,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // ── Filter chips (scrollable) ─────────────────────────
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: ArchiveFilterType.values.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final filterType = ArchiveFilterType.values[index];
                final isActive = prefs.filterType == filterType;
                return _FilterChip(
                  label: _filterLabel(filterType),
                  isActive: isActive,
                  onTap: () {
                    ref
                        .read(archivePrefsProvider.notifier)
                        .setFilterType(filterType);
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          // ── View mode toggle ──────────────────────────────────
          CupertinoSlidingSegmentedControl<ArchiveViewMode>(
            thumbColor: AppColors.titaniumDeep,
            backgroundColor: AppColors.titaniumHighlight.withValues(alpha: 0.5),
            groupValue: prefs.viewMode,
            onValueChanged: (mode) {
              if (mode == null) return;
              ref.read(archivePrefsProvider.notifier).setViewMode(mode);
            },
            children: const {
              ArchiveViewMode.chronology: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Icon(
                  Icons.view_agenda_outlined,
                  size: 20,
                  color: AppColors.starkWhite,
                ),
              ),
              ArchiveViewMode.grid: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Icon(
                  Icons.grid_view,
                  size: 20,
                  color: AppColors.starkWhite,
                ),
              ),
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _filterLabel(ArchiveFilterType type) {
    return switch (type) {
      ArchiveFilterType.all => 'ALL',
      ArchiveFilterType.photos => 'PHOTOS',
      ArchiveFilterType.videos => 'VIDEOS',
      ArchiveFilterType.pending => 'PENDING',
    };
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.kineticGreen.withValues(alpha: 0.1)
              : AppColors.titaniumHighlight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppColors.kineticGreen
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.monoSm(
            color: isActive
                ? AppColors.kineticGreen
                : AppColors.starkWhite.withValues(alpha: 0.6),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

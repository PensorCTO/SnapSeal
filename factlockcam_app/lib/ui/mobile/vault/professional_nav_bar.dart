import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

/// Professional forensic-themed bottom navigation bar for the vault shell.
///
/// Three tabs: Home (vault), Picture (camera photo), Video (camera video),
/// with a reserved fourth slot for future profile/settings.
/// Styled with the project's dark-titanium palette, VerifiedNeon accent,
/// monospaced uppercase labels, and a thin accent bar on the selected tab.
class ProfessionalNavBar extends StatelessWidget {
  const ProfessionalNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const double height = 72;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.titaniumDeep,
        border: Border(
          top: BorderSide(
            color: AppColors.verifiedNeon.withValues(alpha: 0.35),
            width: 0.6,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              _TabItem(
                icon: Icons.shield_outlined,
                label: 'Home',
                isSelected: selectedIndex == 0,
                onTap: () => onDestinationSelected(0),
              ),
              _TabItem(
                icon: Icons.photo_camera_outlined,
                label: 'Picture',
                isSelected: selectedIndex == 1,
                onTap: () => onDestinationSelected(1),
              ),
              _TabItem(
                icon: Icons.videocam_outlined,
                label: 'Video',
                isSelected: selectedIndex == 2,
                onTap: () => onDestinationSelected(2),
              ),
              _TabItem(
                icon: Icons.more_horiz,
                label: 'More',
                isSelected: false,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Settings panel coming soon.'),
                      backgroundColor: AppColors.titaniumPanel,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppColors.verifiedNeon
        : AppColors.starkWhite.withValues(alpha: 0.48);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.verifiedNeon,
                      width: 2,
                    ),
                  ),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: AppTextStyles.monoSm(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

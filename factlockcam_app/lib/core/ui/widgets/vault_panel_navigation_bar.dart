import 'package:flutter/cupertino.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

/// iOS-style back bar for vault shell child panels (archive, camera, settings).
class VaultPanelNavigationBar extends StatelessWidget
    implements ObstructingPreferredSizeWidget {
  const VaultPanelNavigationBar({
    super.key,
    required this.title,
    required this.onBack,
    /// Unique per panel; avoids Hero collisions when multiple bars share a route.
    String? heroTag,
  }) : heroTag = heroTag ?? 'vault_panel_nav_$title';

  final String title;
  final VoidCallback onBack;
  final String heroTag;

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  bool shouldFullyObstruct(BuildContext context) => false;

  @override
  Widget build(BuildContext context) {
    return CupertinoNavigationBar(
      heroTag: heroTag,
      transitionBetweenRoutes: false,
      backgroundColor: AppColors.titaniumDeep.withValues(alpha: 0.94),
      border: Border(
        bottom: BorderSide(
          color: AppColors.verifiedNeon.withValues(alpha: 0.35),
          width: 0.6,
        ),
      ),
      leading: CupertinoNavigationBarBackButton(
        color: AppColors.kineticGreen,
        onPressed: onBack,
      ),
      middle: Text(
        title.toUpperCase(),
        style: AppTextStyles.monoMd(
          color: AppColors.starkWhite,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

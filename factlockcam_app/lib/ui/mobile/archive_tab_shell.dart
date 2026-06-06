import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'archive/account_settings_panel.dart';
import 'archive/archive_omni/unified_archive_viewport.dart';
import 'camera/acquisition_mode.dart';

/// ARCHIVE tab — omni-surface root with settings gear → Account sub-panel.
class ArchiveTabShell extends StatefulWidget {
  const ArchiveTabShell({
    super.key,
    this.onCaptureRequested,
  });

  final ValueChanged<AcquisitionMode>? onCaptureRequested;

  @override
  State<ArchiveTabShell> createState() => _ArchiveTabShellState();
}

class _ArchiveTabShellState extends State<ArchiveTabShell> {
  bool _showAccount = false;

  void _openAccount() => setState(() => _showAccount = true);

  void _closeAccount() => setState(() => _showAccount = false);

  @override
  Widget build(BuildContext context) {
    if (_showAccount) {
      return AccountSettingsPanel(onBackToHub: _closeAccount);
    }

    return UnifiedArchiveViewport(
      onCaptureRequested: widget.onCaptureRequested,
      headerActions: [
        IconButton(
          icon: Icon(
            CupertinoIcons.gear,
            color: AppColors.starkWhite.withValues(alpha: 0.82),
            size: 22,
          ),
          tooltip: 'Account & Settings',
          onPressed: _openAccount,
        ),
      ],
    );
  }
}

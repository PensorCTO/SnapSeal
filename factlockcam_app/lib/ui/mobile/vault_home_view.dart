import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import 'camera/acquisition_mode.dart';
import 'camera/camera_view.dart';
import 'vault/account_settings_panel.dart';
import 'vault/archive_omni/unified_archive_viewport.dart';
import 'vault/haptic_hub_panel.dart';

/// Post-login vault shell.
///
/// Hosts an [IndexedStack] with hub + four destination panels. Navigation is
/// hub-tile push and panel back buttons (no persistent bottom nav).
class VaultHomeView extends ConsumerStatefulWidget {
  const VaultHomeView({super.key});

  static const routePath = '/vault-home';

  @override
  ConsumerState<VaultHomeView> createState() => _VaultHomeViewState();
}

class _VaultHomeViewState extends ConsumerState<VaultHomeView> {
  int _selectedIndex = 0;

  void _returnToHub() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  void _onCaptureComplete() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  void _onHubDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.titaniumDeep,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HapticHubPanel(
            onHubDestinationSelected: _onHubDestinationSelected,
          ),
          CameraView(
            key: ValueKey('camera_photo_${_selectedIndex == 1}'),
            mode: AcquisitionMode.photo,
            onCaptureComplete: _onCaptureComplete,
            onBackToHub: _returnToHub,
          ),
          CameraView(
            key: ValueKey('camera_video_${_selectedIndex == 2}'),
            mode: AcquisitionMode.video,
            onCaptureComplete: _onCaptureComplete,
            onBackToHub: _returnToHub,
          ),
          UnifiedArchiveViewport(
            onCaptureRequested: _onHubDestinationSelected,
            onBackToHub: _returnToHub,
          ),
          AccountSettingsPanel(
            onBackToHub: _returnToHub,
          ),
        ],
      ),
    );
  }
}

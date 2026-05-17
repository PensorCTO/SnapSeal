import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import 'camera/acquisition_mode.dart';
import 'camera/camera_view.dart';
import 'vault/archive_omni/unified_archive_viewport.dart';
import 'vault/haptic_hub_panel.dart';
import 'vault/professional_nav_bar.dart';

/// Post-login vault shell.
///
/// Hosts an [IndexedStack] with four tabs (Home / Picture / Video / Archive)
/// and a [ProfessionalNavBar] at the bottom. The camera tabs avoid the
/// "stranded" post-capture flow by switching back to the Home tab after
/// sealing completes.
class VaultHomeView extends ConsumerStatefulWidget {
  const VaultHomeView({super.key});

  static const routePath = '/vault-home';

  @override
  ConsumerState<VaultHomeView> createState() => _VaultHomeViewState();
}

class _VaultHomeViewState extends ConsumerState<VaultHomeView> {
  int _selectedIndex = 0;

  void _onCaptureComplete() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  void _onCaptureRequested(int tabIndex) {
    setState(() {
      _selectedIndex = tabIndex;
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
            onCaptureRequested: _onCaptureRequested,
          ),
          CameraView(
            key: ValueKey('camera_photo_${_selectedIndex == 1}'),
            mode: AcquisitionMode.photo,
            onCaptureComplete: _onCaptureComplete,
          ),
          CameraView(
            key: ValueKey('camera_video_${_selectedIndex == 2}'),
            mode: AcquisitionMode.video,
            onCaptureComplete: _onCaptureComplete,
          ),
          UnifiedArchiveViewport(
            onCaptureRequested: _onCaptureRequested,
          ),
        ],
      ),
      bottomNavigationBar: ProfessionalNavBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

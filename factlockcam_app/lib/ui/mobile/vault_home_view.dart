import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../data/supabase/auth_repository.dart';
import '../controllers/key_custody_provider.dart';
import 'camera/acquisition_mode.dart';
import 'camera/capture_panel.dart';
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

  void _onHubDestinationSelected(int index) {
    if (kIsWeb && (index == 1 || index == 2)) {
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  /// [IndexedStack] keeps every child in the tree. Mount heavy / Hero-bearing
  /// panels only while selected (cameras, archive, settings).
  Widget _panelWhenSelected(int panelIndex, Widget child) {
    if (_selectedIndex != panelIndex) {
      return const SizedBox.shrink();
    }
    return child;
  }

  /// Only mount [CameraView] while its panel is active; eager camera init for
  /// hidden panels contends on iOS hardware and can blank the first frame.
  Widget _cameraPanel(AcquisitionMode mode) {
    final isPhoto = mode == AcquisitionMode.photo;
    final panelIndex = isPhoto ? 1 : 2;
    if (_selectedIndex != panelIndex) {
      return const SizedBox.shrink();
    }
    return buildCapturePanel(
      key: ValueKey('camera_${mode.name}'),
      mode: mode,
      onBackToHub: _returnToHub,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      final session = ref.watch(authRepositoryProvider).currentSession;
      if (session != null) {
        final custody = ref.watch(keyCustodyProvider);
        final custodyPending = custody.isLoading ||
            custody.maybeWhen(
              data: (status) => status == KeyCustodyStatus.unknown,
              orElse: () => false,
            );
        if (custodyPending) {
          return Scaffold(
            backgroundColor: AppColors.titaniumDeep,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CupertinoActivityIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Preparing archive keys…',
                    style: AppTextStyles.monoSm(color: AppColors.starkWhite),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.titaniumDeep,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HapticHubPanel(
            onHubDestinationSelected: _onHubDestinationSelected,
          ),
          _cameraPanel(AcquisitionMode.photo),
          _cameraPanel(AcquisitionMode.video),
          _panelWhenSelected(
            3,
            UnifiedArchiveViewport(
              onCaptureRequested: _onHubDestinationSelected,
              onBackToHub: _returnToHub,
            ),
          ),
          _panelWhenSelected(
            4,
            AccountSettingsPanel(
              onBackToHub: _returnToHub,
            ),
          ),
        ],
      ),
    );
  }
}

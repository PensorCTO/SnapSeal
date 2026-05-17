import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import 'camera/acquisition_mode.dart';
import 'camera/camera_view.dart';
import 'vault/chronology_viewport.dart';
import 'vault/haptic_hub_panel.dart';
import 'vault/professional_nav_bar.dart';

// #region agent log
import 'dart:convert';
import 'dart:io';

const _kDebugLog =
    '/Users/paulensor/Projects/ProofLockCleanup/.cursor/debug-4d5e77.log';
// #endregion

/// Post-login vault shell.
///
/// Hosts an [IndexedStack] with four tabs (Home / Picture / Video / Vault)
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
    // #region agent log
    try {
      File(_kDebugLog).writeAsStringSync(
        '${json.encode({
          'sessionId': '4d5e77',
          'runId': 'r1',
          'hypothesisId': 'A',
          'location': 'vault_home_view.dart:build',
          'message': 'IndexedStack build',
          'data': {'selectedIndex': _selectedIndex},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        })}\n',
        mode: FileMode.append,
      );
    } catch (_) {}
    // #endregion
    return Scaffold(
      backgroundColor: AppColors.titaniumDeep,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HapticHubPanel(
            onCaptureRequested: _onCaptureRequested,
          ),
          CameraView(
            mode: AcquisitionMode.photo,
            onCaptureComplete: _onCaptureComplete,
          ),
          CameraView(
            mode: AcquisitionMode.video,
            onCaptureComplete: _onCaptureComplete,
          ),
          ChronologyViewport(
            onCaptureRequested: _onCaptureRequested,
          ),
        ],
      ),
      bottomNavigationBar: ProfessionalNavBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          // #region agent log
          try {
            File(_kDebugLog).writeAsStringSync(
              '${json.encode({
                'sessionId': '4d5e77',
                'runId': 'r1',
                'hypothesisId': 'A',
                'location': 'vault_home_view.dart:onTab',
                'message': 'Tab selected',
                'data': {'index': index, 'stackSize': 4},
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              })}\n',
              mode: FileMode.append,
            );
          } catch (_) {}
          // #endregion
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../features/archive_quota/presentation/views/archive_subscription_onboarding_sheet.dart';
import '../../data/supabase/auth_repository.dart';
import '../controllers/key_custody_provider.dart';
import 'archive/account_settings_panel.dart';
import 'archive/archive_omni/unified_archive_viewport.dart';
import 'archive/haptic_hub_panel.dart';
import 'camera/acquisition_mode.dart';
import 'camera/capture_panel.dart';

/// Post-login shell — hub launcher with lazy-mounted child panels.
class ArchiveHomeView extends ConsumerStatefulWidget {
  const ArchiveHomeView({super.key});

  static const routePath = '/archive';
  static const legacyVaultHomePath = '/vault-home';

  static const hubIndex = 0;
  static const pictureIndex = 1;
  static const videoIndex = 2;
  static const archiveIndex = 3;
  static const accountIndex = 4;

  @override
  ConsumerState<ArchiveHomeView> createState() => _ArchiveHomeViewState();
}

class _ArchiveHomeViewState extends ConsumerState<ArchiveHomeView> {
  int _selectedIndex = ArchiveHomeView.hubIndex;
  bool _onboardingScheduled = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowOnboarding());
    }
  }

  Future<void> _maybeShowOnboarding() async {
    if (_onboardingScheduled || !mounted) return;
    final session = ref.read(authRepositoryProvider).currentSession;
    if (session == null) return;
    _onboardingScheduled = true;
    await showArchiveSubscriptionOnboardingIfNeeded(context);
  }

  void _onHubDestinationSelected(int destination) {
    setState(() => _selectedIndex = destination);
  }

  void _goToHub() {
    setState(() => _selectedIndex = ArchiveHomeView.hubIndex);
  }

  /// IndexedStack retains children; mount panel bodies only while selected.
  Widget _panelWhenSelected(int panelIndex, Widget child) {
    if (_selectedIndex != panelIndex) {
      return const SizedBox.shrink();
    }
    return child;
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
          _panelWhenSelected(
            ArchiveHomeView.hubIndex,
            HapticHubPanel(
              onHubDestinationSelected: _onHubDestinationSelected,
            ),
          ),
          _panelWhenSelected(
            ArchiveHomeView.pictureIndex,
            buildCapturePanel(
              key: const ValueKey('camera_photo'),
              mode: AcquisitionMode.photo,
              onBackToHub: _goToHub,
            ),
          ),
          _panelWhenSelected(
            ArchiveHomeView.videoIndex,
            buildCapturePanel(
              key: const ValueKey('camera_video'),
              mode: AcquisitionMode.video,
              onBackToHub: _goToHub,
            ),
          ),
          _panelWhenSelected(
            ArchiveHomeView.archiveIndex,
            UnifiedArchiveViewport(onBackToHub: _goToHub),
          ),
          _panelWhenSelected(
            ArchiveHomeView.accountIndex,
            AccountSettingsPanel(onBackToHub: _goToHub),
          ),
        ],
      ),
    );
  }
}

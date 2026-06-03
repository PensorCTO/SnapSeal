import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../app/theme/app_colors.dart';

/// Canonical asset path for the Heavy Metal video backdrop.
///
/// Both [ArchiveHomeView] and [LogonView] read this same file through
/// [HeavyMetalBackdropMixin]. The binary is bundled via the
/// `assets/videos/` directory declaration in `pubspec.yaml`.
const String kHeavyMetalBackdropAsset =
    'assets/videos/FactLockCamBackground.mp4';

/// Canonical logo header graphic for Heavy Metal screens (hub, logon, archive).
const String kHeavyMetalLogoHeaderAsset =
    'assets/images/factlockcam_logoheader.jpg';

/// iOS device QA: a stuck AVFoundation init must not block the logon/hub shell.
const Duration _backdropInitTimeout = Duration(seconds: 8);

/// Bottom layer of a Heavy Metal [Stack]: a muted, cover-fit
/// [VideoPlayer] painted over a [AppColors.titaniumDeep] base so the
/// fallback (asset missing, init failure, or test mode) stays on-brand.
class BackgroundVideoLayer extends StatelessWidget {
  const BackgroundVideoLayer({
    super.key,
    required this.controller,
    required this.ready,
  });

  final VideoPlayerController? controller;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null || !ready) {
      return const ColoredBox(color: AppColors.titaniumDeep);
    }
    return ColoredBox(
      color: AppColors.titaniumDeep,
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: c.value.size.width,
          height: c.value.size.height,
          child: VideoPlayer(c),
        ),
      ),
    );
  }
}

/// Mid layer of a Heavy Metal [Stack]: a *soft* bottom-only vignette so the
/// upper two-thirds of the video stays fully visible and only the lower
/// button strip gets a subtle scrim for legibility. [IgnorePointer] so it
/// never eats gestures from the UI layer above it.
class TitaniumOverlay extends StatelessWidget {
  const TitaniumOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x00121212),
              Color(0x00121212),
              Color(0x80121212),
              Color(0xC0121212),
            ],
            stops: [0, 0.45, 0.85, 1],
          ),
        ),
      ),
    );
  }
}

/// Solid-titanium brand plinth that sits at the top of a Heavy Metal screen.
///
/// Provides a visually-distinct "logo zone" above the video so the backdrop
/// doesn't fight the brand. Pass a custom [child] (e.g. `Image.asset(...)`)
/// to replace the default mark + wordmark + tagline placeholder. The
/// [actions] slot renders chrome (popup menus, icon buttons) in the
/// top-right corner without needing an [AppBar].
class HeavyMetalLogoBanner extends StatelessWidget {
  const HeavyMetalLogoBanner({
    super.key,
    this.contentHeight = 104,
    this.child,
    this.actions = const [],
    this.includeTopSafeArea = true,
  });

  final double contentHeight;
  final Widget? child;
  final List<Widget> actions;

  /// When `false`, omits [MediaQuery.padding.top] — use beneath [ArchivePanelNavigationBar].
  final bool includeTopSafeArea;

  @override
  Widget build(BuildContext context) {
    final topInset = includeTopSafeArea ? MediaQuery.of(context).padding.top : 0.0;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.titaniumDeep,
        border: Border(
          bottom: BorderSide(color: AppColors.verifiedNeon, width: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topInset),
        child: SizedBox(
          height: contentHeight,
          width: double.infinity,
          child: Stack(
            children: [
              Center(child: child ?? const _HeavyMetalBrandLogoImage()),
              if (actions.isNotEmpty)
                Positioned(
                  top: 0,
                  right: 4,
                  bottom: 0,
                  child: Row(mainAxisSize: MainAxisSize.min, children: actions),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeavyMetalBrandLogoImage extends StatelessWidget {
  const _HeavyMetalBrandLogoImage();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      kHeavyMetalLogoHeaderAsset,
      fit: BoxFit.contain,
    );
  }
}

/// State mixin that owns a paused-on-first-frame [VideoPlayerController]
/// backing a Heavy Metal Stack.
///
/// Mix into any [State] / [ConsumerState]. The controller is initialized
/// in [initState] and torn down in [dispose]. The clip is held on its
/// first frame; call [playBackdropFromStart] to seek-and-play, and the
/// end-of-clip listener auto-pauses + resets back to frame zero.
///
/// `HeavyMetalBackdropMixin.enabled` is a static kill-switch flipped to
/// `false` in `flutter_test_config.dart` so widget tests never touch the
/// `video_player` platform channel. `debugControllerFactory` is a test
/// seam for injecting a stub controller.
mixin HeavyMetalBackdropMixin<W extends StatefulWidget> on State<W> {
  static bool enabled = true;
  static VideoPlayerController Function()? debugControllerFactory;

  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _resetting = false;

  VideoPlayerController? get backdropController => _videoController;
  bool get backdropReady => _videoReady;

  @override
  void initState() {
    super.initState();
    unawaited(_initBackdrop());
  }

  Future<void> _initBackdrop() async {
    if (!HeavyMetalBackdropMixin.enabled) return;
    VideoPlayerController? controller;
    try {
      controller =
          (HeavyMetalBackdropMixin.debugControllerFactory ?? _defaultFactory)();
      _videoController = controller;
      await controller.initialize().timeout(
        _backdropInitTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Heavy Metal backdrop init exceeded '
            '${_backdropInitTimeout.inSeconds}s',
          );
        },
      );
      if (!mounted) {
        await controller.dispose();
        _videoController = null;
        return;
      }
      await controller.setLooping(false);
      // Ambient backdrop, never audible. Screens still announce taps
      // through HapticService.lock().
      await controller.setVolume(0);
      await controller.seekTo(Duration.zero);
      await controller.pause();
      controller.addListener(_onVideoTick);
      if (!mounted) return;
      setState(() => _videoReady = true);
    } catch (_) {
      _videoController = null;
      if (controller != null) {
        try {
          await controller.dispose();
        } catch (_) {
          // Best-effort cleanup; controller may already be torn down.
        }
      }
    }
  }

  static VideoPlayerController _defaultFactory() {
    return VideoPlayerController.asset(kHeavyMetalBackdropAsset);
  }

  void _onVideoTick() {
    final controller = _videoController;
    if (controller == null) return;
    final value = controller.value;
    if (!value.isInitialized || _resetting) return;
    final duration = value.duration;
    if (duration <= Duration.zero) return;
    if (value.position >= duration && !value.isPlaying) {
      unawaited(_resetBackdropToFirstFrame());
    }
  }

  Future<void> _resetBackdropToFirstFrame() async {
    final controller = _videoController;
    if (controller == null) return;
    _resetting = true;
    try {
      await controller.pause();
      await controller.seekTo(Duration.zero);
    } finally {
      _resetting = false;
    }
  }

  /// Seek to the first frame and play the clip once. The end-of-clip
  /// listener will pause + reset automatically when playback completes.
  Future<void> playBackdropFromStart() async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;
    await controller.seekTo(Duration.zero);
    await controller.play();
  }

  @override
  void dispose() {
    final controller = _videoController;
    _videoController = null;
    controller?.removeListener(_onVideoTick);
    if (controller != null) {
      unawaited(controller.dispose());
    }
    super.dispose();
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Satisfies [VideoPlayerPlatform] validation when widget tests enable backdrop video.
class MockVideoPlayerPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements VideoPlayerPlatform {
  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int playerId) async {}
}

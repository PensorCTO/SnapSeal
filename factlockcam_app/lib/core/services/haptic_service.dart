import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hapticServiceProvider = Provider<HapticService>((ref) {
  return const HapticService();
});

class HapticService {
  const HapticService();

  Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  Future<void> lock() async {
    await heavyImpact();
  }

  Future<void> tap() async {
    await selectionClick();
  }

  Future<void> success() async {
    await HapticFeedback.lightImpact();
  }

  Future<void> error() async {
    await HapticFeedback.mediumImpact();
  }
}

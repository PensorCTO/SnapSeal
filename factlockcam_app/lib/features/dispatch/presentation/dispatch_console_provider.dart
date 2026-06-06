import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dispatch_console_state.dart';

final dispatchConsoleProvider =
    NotifierProvider<DispatchConsoleNotifier, DispatchConsoleState>(
  DispatchConsoleNotifier.new,
);

class DispatchConsoleNotifier extends Notifier<DispatchConsoleState> {
  @override
  DispatchConsoleState build() => const DispatchConsoleState();

  void selectAsset(String hash) {
    state = state.copyWith(selectedAssetHash: hash);
  }

  void setMaxDownloads(int value) {
    if (!DispatchConsoleState.maxDownloadPresets.contains(value)) {
      return;
    }
    state = state.copyWith(maxDownloads: value);
  }

  void setLinkTtlDays(int value) {
    if (!DispatchConsoleState.linkTtlPresets.contains(value)) {
      return;
    }
    state = state.copyWith(linkTtlDays: value);
  }
}

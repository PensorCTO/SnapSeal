import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/service_providers.dart';

part 'courier_link_provider.g.dart';

@Riverpod(keepAlive: true)
class CourierLink extends _$CourierLink {
  @override
  FutureOr<void> build() {}

  Future<void> generateAndShareLink(String assetHash, String password) async {
    state = const AsyncLoading<void>();
    try {
      final url = await ref
          .read(vaultServiceProvider)
          .createCourierPackage(
            assetHash: assetHash,
            verifierPassword: password,
          );
      await SharePlus.instance.share(ShareParams(text: url));
      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

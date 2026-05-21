import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/service_providers.dart';

part 'courier_link_provider.g.dart';

@Riverpod(keepAlive: true)
class CourierLink extends _$CourierLink {
  @override
  FutureOr<String> build() => '';

  Future<String> generateLink(String assetHash, String password) async {
    state = const AsyncLoading<String>();
    try {
      final url = await ref
          .read(vaultServiceProvider)
          .createCourierPackage(
            assetHash: assetHash,
            verifierPassword: password,
          );
      state = AsyncData<String>(url);
      return url;
    } catch (error, stackTrace) {
      state = AsyncError<String>(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

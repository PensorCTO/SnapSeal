import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Lightweight GPS stream for camera viewfinder forensic telemetry.
class CameraGeolocationStream {
  StreamSubscription<Position>? _subscription;
  double? latitude;
  double? longitude;

  Future<void> start(VoidCallback onUpdate) async {
    if (kIsWeb) {
      return;
    }
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      _subscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
        ),
      ).listen((position) {
        latitude = position.latitude;
        longitude = position.longitude;
        onUpdate();
      });
    } catch (_) {
      // Forensic HUD falls back to placeholder coordinates.
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}

package com.factlockcam.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.StandardCharsets
import java.util.Base64

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "com.factlockcam.app/enclave",
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "signHash" -> {
          val hash = call.arguments as? String
          if (hash.isNullOrEmpty()) {
            result.error("bad_args", "hash required", null)
          } else {
            // TODO: Replace with Android Keystore / hardware-backed signing.
            val simulated =
              Base64.getEncoder().encodeToString(
                ("SIMULATED_DEV|$hash").toByteArray(StandardCharsets.UTF_8),
              )
            result.success(simulated)
          }
        }
        else -> result.notImplemented()
      }
    }
  }
}

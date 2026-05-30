package com.factlockcam.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
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
            try {
              val signature = DeviceEnclaveSigner.signHash(this, hash)
              result.success(signature)
            } catch (e: Exception) {
              result.error("enclave_sign_failed", e.message, null)
            }
          }
        }
        else -> result.notImplemented()
      }
    }

    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "com.factlockcam.app/platform",
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "beginBackgroundTask" -> result.success(0)
        "endBackgroundTask" -> result.success(null)
        "pickEncryptedBackupBytes" -> result.success(null)
        else -> result.notImplemented()
      }
    }
  }
}

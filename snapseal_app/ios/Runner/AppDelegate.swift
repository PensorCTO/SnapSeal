import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private static let enclaveChannel = "com.snapseal.app/enclave"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: AppDelegate.enclaveChannel,
        binaryMessenger: controller.binaryMessenger,
      )
      channel.setMethodCallHandler { call, result in
        if call.method == "signHash" {
          guard let hash = call.arguments as? String, !hash.isEmpty else {
            result(
              FlutterError(code: "bad_args", message: "hash required", details: nil),
            )
            return
          }
          // TODO(ProofLock): replace with Secure Enclave / CryptoKit signing.
          let payload = "SIMULATED_DEV|\(hash)"
          let sig = Data(payload.utf8).base64EncodedString()
          result(sig)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

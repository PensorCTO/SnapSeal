import Flutter
import UIKit
import MobileCoreServices

@main
@objc class AppDelegate: FlutterAppDelegate, UIDocumentPickerDelegate {
  private static let enclaveChannel = "com.factlockcam.app/enclave"
  private static let platformChannel = "com.factlockcam.app/platform"
  private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
  private var pendingBackupPickerResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let enclave = FlutterMethodChannel(
        name: AppDelegate.enclaveChannel,
        binaryMessenger: controller.binaryMessenger,
      )
      enclave.setMethodCallHandler { call, result in
        if call.method == "signHash" {
          guard let hash = call.arguments as? String, !hash.isEmpty else {
            result(
              FlutterError(code: "bad_args", message: "hash required", details: nil),
            )
            return
          }
          do {
            let signature = try EnclaveSigner.signHash(hex: hash)
            result(signature)
          } catch {
            result(
              FlutterError(
                code: "enclave_sign_failed",
                message: error.localizedDescription,
                details: nil,
              ),
            )
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      }

      let platform = FlutterMethodChannel(
        name: AppDelegate.platformChannel,
        binaryMessenger: controller.binaryMessenger,
      )
      platform.setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(nil)
          return
        }
        switch call.method {
        case "beginBackgroundTask":
          self.backgroundTaskId = UIApplication.shared.beginBackgroundTask {
            if self.backgroundTaskId != .invalid {
              UIApplication.shared.endBackgroundTask(self.backgroundTaskId)
              self.backgroundTaskId = .invalid
            }
          }
          result(Int(self.backgroundTaskId.rawValue))
        case "endBackgroundTask":
          guard let raw = call.arguments as? Int else {
            result(nil)
            return
          }
          let taskId = UIBackgroundTaskIdentifier(rawValue: raw)
          if taskId == .invalid {
            result(nil)
            return
          }
          UIApplication.shared.endBackgroundTask(taskId)
          if self.backgroundTaskId == taskId {
            self.backgroundTaskId = .invalid
          }
          result(nil)
        // INSTITUTION: pickSealSourceFile — UIDocumentPicker with broad UTTypes
        case "pickEncryptedBackupBytes", "pickFactlockBackupBytes":
          self.pendingBackupPickerResult = result
          let picker = UIDocumentPickerViewController(
            documentTypes: [kUTTypeData as String],
            in: .import,
          )
          picker.delegate = self
          picker.allowsMultipleSelection = false
          controller.present(picker, animated: true)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    defer { pendingBackupPickerResult = nil }
    guard let result = pendingBackupPickerResult else { return }
    guard let url = urls.first else {
      result(nil)
      return
    }
    let accessed = url.startAccessingSecurityScopedResource()
    defer {
      if accessed {
        url.stopAccessingSecurityScopedResource()
      }
    }
    do {
      let data = try Data(contentsOf: url)
      result(FlutterStandardTypedData(bytes: data))
    } catch {
      result(
        FlutterError(code: "read_failed", message: error.localizedDescription, details: nil),
      )
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingBackupPickerResult?(nil)
    pendingBackupPickerResult = nil
  }
}

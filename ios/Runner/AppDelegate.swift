import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, UIDocumentPickerDelegate {
  private var pendingResult: FlutterResult?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "drive_sync/bookmarks", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self else { result(FlutterError(code: "unavailable", message: "AppDelegate missing", details: nil)); return }
      switch call.method {
      case "createBookmark":
        guard let args = call.arguments as? [String: Any], let urlStr = args["url"] as? String, let url = URL(string: urlStr) else {
          result(FlutterError(code: "bad_args", message: "Missing url", details: nil)); return
        }
        do {
          let bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
          result(FlutterStandardTypedData(bytes: bookmark))
        } catch {
          result(FlutterError(code: "bookmark_failed", message: error.localizedDescription, details: nil))
        }
      case "pickDirectory":
        guard self.pendingResult == nil else { result(FlutterError(code: "busy", message: "Picker already active", details: nil)); return }
        self.pendingResult = result
        let picker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
          picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.folder], asCopy: false)
        } else {
          picker = UIDocumentPickerViewController(documentTypes: ["public.folder"], in: .open)
        }
        picker.delegate = self
        picker.allowsMultipleSelection = false
        picker.modalPresentationStyle = .formSheet
        var top: UIViewController = controller
        while let presented = top.presentedViewController { top = presented }
        DispatchQueue.main.async {
          top.present(picker, animated: true, completion: nil)
        }
      case "startAccess":
        guard let args = call.arguments as? [String: Any], let data = args["bookmark"] as? FlutterStandardTypedData else {
          result(FlutterError(code: "bad_args", message: "Missing bookmark", details: nil)); return
        }
        var isStale = false
        do {
          let url = try URL(resolvingBookmarkData: data.data, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
          if url.startAccessingSecurityScopedResource() {
            result(url.path)
          } else {
            result(FlutterError(code: "access_denied", message: "startAccessingSecurityScopedResource failed", details: nil))
          }
        } catch {
          result(FlutterError(code: "resolve_failed", message: error.localizedDescription, details: nil))
        }
      case "stopAccess":
        // Client side keeps a reference to URL if needed; iOS does not require explicit stop with URL instance here.
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - UIDocumentPickerDelegate
  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingResult?(FlutterError(code: "cancelled", message: "User cancelled", details: nil))
    pendingResult = nil
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let result = pendingResult else { return }
    pendingResult = nil
    guard let url = urls.first else {
      result(FlutterError(code: "no_selection", message: "No folder selected", details: nil)); return
    }
    do {
      let bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
      _ = url.startAccessingSecurityScopedResource()
      result(["path": url.path, "bookmark": FlutterStandardTypedData(bytes: bookmark)])
    } catch {
      result(FlutterError(code: "bookmark_failed", message: error.localizedDescription, details: nil))
    }
  }
}

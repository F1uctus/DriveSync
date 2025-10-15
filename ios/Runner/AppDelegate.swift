import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
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
}

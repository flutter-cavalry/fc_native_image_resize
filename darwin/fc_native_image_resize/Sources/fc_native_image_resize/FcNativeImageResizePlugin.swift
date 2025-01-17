import Foundation

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#endif

enum PluginError: Error {
  case invalidSrc
  case invalidSize
}

public class FcNativeImageResizePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
      let binaryMessenger = registrar.messenger()
    #elseif os(macOS)
      let binaryMessenger = registrar.messenger
    #endif
    let channel = FlutterMethodChannel(
      name: "fc_native_image_resize", binaryMessenger: binaryMessenger)
    let instance = FcNativeImageResizePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "InvalidArgsType", message: "Invalid args type", details: nil))
      return
    }
    switch call.method {
    case "resizeFile":
      // Arguments are enforced on dart side.
      let srcFile = args["srcFile"] as! String
      let srcUri = args["srcFileUri"] as? Bool ?? false
      let destFile = args["destFile"] as! String
      let width = args["width"] as! Int
      let height = args["height"] as! Int
      let outputString = args["type"] as! String
      let keepAspectRatio = args["keepAspectRatio"] as! Bool

      let quality = args["quality"] as? Int
      let outputType = outputString == "png" ? FCImageOutputFormat.png : FCImageOutputFormat.jpeg

      guard let srcUrl = srcUri ? URL(string: srcFile) : URL(fileURLWithPath: srcFile) else {
        result(FlutterError(code: "PluginError", message: "Invalid source URL", details: nil))
        return
      }
      let destUrl = URL(fileURLWithPath: destFile)

      DispatchQueue.global().async {
        do {
          guard var img = FCImage(url: srcUrl) else {
            throw PluginError.invalidSrc
          }
          guard
            let resized = img.resized(
              to: CGSize(width: CGFloat(width), height: CGFloat(height)),
              keepAspectRatio: keepAspectRatio)
          else {
            throw PluginError.invalidSize
          }
          img = resized

          switch outputType {
          case .jpeg:
            try img.saveToJPEGFile(dest: destUrl, quality: quality)
          case .png:
            try img.saveToPNGFile(dest: destUrl)
          }

          DispatchQueue.main.async {
            result(nil)
          }
        } catch PluginError.invalidSrc {
          DispatchQueue.main.async {
            result(FlutterError(code: "InvalidSrc", message: "", details: nil))
          }
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(code: "PluginError", message: error.localizedDescription, details: nil))
          }
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

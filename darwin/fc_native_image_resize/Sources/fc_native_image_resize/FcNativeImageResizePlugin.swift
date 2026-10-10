import Foundation

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#endif

enum PluginError: Error {
  case invalidSrc
  case invalidSize
  case encodingFailed
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
    guard call.method == "resizeFile" || call.method == "resizeFileToBytes" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "InvalidArgsType", message: "Invalid args type", details: nil))
      return
    }
    switch call.method {
    case "resizeFile", "resizeFileToBytes":
      guard let srcFile = args["srcFile"] as? String,
        let width = args["width"] as? Int,
        let height = args["height"] as? Int,
        let outputString = args["type"] as? String,
        let keepAspectRatio = args["keepAspectRatio"] as? Bool,
        outputString == "png" || outputString == "jpeg",
        call.method != "resizeFile" || args["destFile"] is String
      else {
        result(FlutterError(code: "PluginError", message: "Invalid resize arguments", details: nil))
        return
      }
      let srcUri = args["srcFileUri"] as? Bool ?? false
      let destFile = args["destFile"] as? String
      let quality = args["quality"] as? Int
      if let quality = quality, !(1...100).contains(quality) {
        result(FlutterError(code: "PluginError", message: "Invalid quality", details: nil))
        return
      }
      let outputType = outputString == "png" ? FCImageOutputFormat.png : FCImageOutputFormat.jpeg

      guard let srcUrl = srcUri ? URL(string: srcFile) : URL(fileURLWithPath: srcFile) else {
        result(FlutterError(code: "PluginError", message: "Invalid source URL", details: nil))
        return
      }
      DispatchQueue.global().async {
        do {
          guard let img = FCImage(url: srcUrl) else {
            throw PluginError.invalidSrc
          }
          guard
            let resized = img.resized(
              to: CGSize(width: CGFloat(width), height: CGFloat(height)),
              keepAspectRatio: keepAspectRatio)
          else {
            throw PluginError.invalidSize
          }
          let data = try resized.encodedData(format: outputType, quality: quality)
          if call.method == "resizeFile", let destFile = destFile {
            try data.write(to: URL(fileURLWithPath: destFile))
          }

          DispatchQueue.main.async {
            result(call.method == "resizeFileToBytes" ? FlutterStandardTypedData(bytes: data) : nil)
          }
        } catch PluginError.invalidSrc {
          DispatchQueue.main.async {
            result(FlutterError(code: "FailedToDecodeImageFile", message: "Failed to decode image file: \(srcFile)", details: nil))
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

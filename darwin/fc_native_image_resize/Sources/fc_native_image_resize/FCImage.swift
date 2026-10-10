import AVFoundation
import Foundation
import ImageIO

#if os(iOS)
  import UIKit
  typealias PlatformImage = UIImage
#elseif os(macOS)
  import AppKit
  typealias PlatformImage = NSImage
#endif

enum FCImageOutputFormat {
  case jpeg
  case png
}

class FCImage {
  private let image: PlatformImage

  var rawImage: PlatformImage {
    return image
  }

  init(image: PlatformImage) {
    self.image = image
  }

  init?(path: String) {
    #if os(iOS)
      guard let img = UIImage(contentsOfFile: path) else {
        return nil
      }
    #elseif os(macOS)
      guard let img = NSImage(contentsOfFile: path) else {
        return nil
      }
    #endif
    image = img
  }

  init?(url: URL) {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let width = properties[kCGImagePropertyPixelWidth] as? Int,
      let height = properties[kCGImagePropertyPixelHeight] as? Int,
      let decoded = CGImageSourceCreateThumbnailAtIndex(source, 0, [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: max(width, height),
      ] as CFDictionary)
    else { return nil }
    #if os(iOS)
      let img = UIImage(cgImage: decoded)
    #elseif os(macOS)
      let img = NSImage(cgImage: decoded, size: .zero)
    #endif
    image = img
  }

  init(cgImage: CGImage) {
    #if os(iOS)
      let img = UIImage(cgImage: cgImage)
    #elseif os(macOS)
      let img = NSImage(cgImage: cgImage, size: .zero)
    #endif
    image = img
  }

  func size() -> CGSize {
    #if os(iOS)
      // Don't use `cgImage` to get size, it doesn't take orientation into account.
      return CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
    #elseif os(macOS)
      if let rep = image.representations.first {
        let size = CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
        return size
      }
      return CGSize()
    #endif
  }

  func getCGImage() -> CGImage? {
    #if os(iOS)
      return image.cgImage
    #elseif os(macOS)
      return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    #endif
  }

  func resized(to: CGSize, keepAspectRatio: Bool) -> FCImage? {
    guard to.width != 0, to.height != 0, to.width >= -1, to.height >= -1,
      to.width > 0 || to.height > 0,
      keepAspectRatio || (to.width > 0 && to.height > 0),
      let source = getCGImage()
    else { return nil }
    var width = to.width
    var height = to.height
    if keepAspectRatio {
      let widthRatio = width == -1 ? CGFloat.infinity : width / CGFloat(source.width)
      let heightRatio = height == -1 ? CGFloat.infinity : height / CGFloat(source.height)
      let ratio = min(1, widthRatio, heightRatio)
      width = CGFloat(source.width) * ratio
      height = CGFloat(source.height) * ratio
    }
    guard let context = CGContext(
      data: nil, width: max(1, Int(width)), height: max(1, Int(height)),
      bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { return nil }
    context.interpolationQuality = .high
    context.draw(source, in: CGRect(x: 0, y: 0, width: context.width, height: context.height))
    guard let resized = context.makeImage() else { return nil }
    return FCImage(cgImage: resized)
  }

  func encodedData(format: FCImageOutputFormat, quality: Int?) throws -> Data {
    guard let source = getCGImage() else { throw PluginError.encodingFailed }
    let data = NSMutableData()
    let type = format == .png ? "public.png" : "public.jpeg"
    guard let destination = CGImageDestinationCreateWithData(data, type as CFString, 1, nil)
    else { throw PluginError.encodingFailed }
    let options: [CFString: Any] = format == .jpeg
      ? [kCGImageDestinationLossyCompressionQuality: Double(quality ?? 90) / 100.0] : [:]
    CGImageDestinationAddImage(destination, source, options as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { throw PluginError.encodingFailed }
    return data as Data
  }

  func saveToJPEGFile(dest: URL, quality: Int?) throws {
    try encodedData(format: .jpeg, quality: quality).write(to: dest)
  }

  func saveToPNGFile(dest: URL) throws {
    try encodedData(format: .png, quality: nil).write(to: dest)
  }
}

#if os(iOS)
  extension UIImage {
    func resized(to newSize: CGSize, keepAspectRatio: Bool) -> UIImage {
      var targetSize = newSize
      if keepAspectRatio {
        let availableRect = AVFoundation.AVMakeRect(
          aspectRatio: self.size,
          insideRect: .init(origin: .zero, size: newSize)
        )
        targetSize = availableRect.size

        // Prevent upscaling.
        if targetSize.width > self.size.width && targetSize.height > self.size.height {
          targetSize = self.size
        }
      }

      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

      // Resize the image
      let resized = renderer.image { _ in
        self.draw(in: CGRect(origin: .zero, size: targetSize))
      }

      return resized
    }
  }

#elseif os(macOS)
  extension NSImage {
    public func resized(to newSize: CGSize, keepAspectRatio: Bool) -> NSImage {
      var targetSize = newSize
      if keepAspectRatio {
        let availableRect = AVFoundation.AVMakeRect(
          aspectRatio: self.size,
          insideRect: .init(origin: .zero, size: newSize)
        )
        targetSize = availableRect.size

        // Prevent upscaling.
        if targetSize.width > self.size.width && targetSize.height > self.size.height {
          targetSize = self.size
        }
      }
      let scale = NSScreen.main?.backingScaleFactor ?? 1.0
      targetSize = CGSize(width: targetSize.width / scale, height: targetSize.height / scale)

      let rawImg = NSImage(size: targetSize)

      rawImg.lockFocus()
      defer {
        rawImg.unlockFocus()
      }

      if let ctx = NSGraphicsContext.current {
        ctx.imageInterpolation = .high
        draw(in: NSRect(origin: .zero, size: targetSize))
      }
      return rawImg
    }

    public func nsImageToData(type: NSBitmapImageRep.FileType, quality: Int?) -> Data? {
      guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil)
      else {
        return nil
      }
      let imageRep = NSBitmapImageRep(cgImage: cgImage)

      var opt: [NSBitmapImageRep.PropertyKey: Any] = [:]
      if type == .jpeg {
        opt[NSBitmapImageRep.PropertyKey.compressionFactor] = Double(quality ?? 90) / 100.0
      }
      return imageRep.representation(using: type, properties: opt)
    }
  }
#endif

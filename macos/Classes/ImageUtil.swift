import Foundation
import AppKit

enum ResizeError: Error {
    case invalidSrc
}

enum OutputType {
    case jpeg
    case png
}

class ImageUtil {
    static func resizeFile(src: String, dest: String, width: CGFloat, height: CGFloat, keepAspectRatio: Bool, outType: OutputType, quality: Double?) throws {
        guard let img = NSImage(contentsOf: URL(fileURLWithPath: src)) else {
            throw ResizeError.invalidSrc
        }
        let oldSize = img.size
        let newSize = keepAspectRatio ? _sizeToFit(originalSize: oldSize, maxSize: CGSize(width: width, height: height)) : CGSize(width: width, height: height)
        
        guard let resizedImg = img.resized(to: newSize) else {
            throw ResizeError.invalidSrc
        }
        let data = _nsImageToData(resizedImg, type: outType, quality: quality)
        try data?.write(to: URL(fileURLWithPath: dest))
    }
    
    static func _sizeToFit(originalSize: CGSize, maxSize: CGSize) -> CGSize {
        let widthRatio = maxSize.width / originalSize.width;
        let heightRatio = maxSize.height / originalSize.height;
        let minAspectRatio = min(widthRatio, heightRatio);
        if (minAspectRatio > 1) {
            return originalSize;
        }
        return CGSize(width: floor(originalSize.width * minAspectRatio), height: floor(originalSize.height * minAspectRatio))
    }
    
    static func _nsImageToData(_ image: NSImage, type: OutputType, quality: Double?) -> Data? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            return nil
        }
        let imageRep = NSBitmapImageRep(cgImage: cgImage)
        imageRep.size = image.size // display size in points
        
        var opt: [NSBitmapImageRep.PropertyKey : Any] = [:]
        if type == .jpeg {
            opt[NSBitmapImageRep.PropertyKey.compressionFactor] = quality ?? 0.9
        }
        return imageRep.representation(using: type == .png ? .png : .jpeg, properties: opt)
    }
}

extension NSImage {
    func resized(to newSize: NSSize) -> NSImage? {
        if let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) {
            bitmapRep.size = newSize
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
            draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()
            
            let resizedImage = NSImage(size: newSize)
            resizedImage.addRepresentation(bitmapRep)
            return resizedImage
        }
        
        return nil
    }
}

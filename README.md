# fc_native_image_resize

[![pub package](https://img.shields.io/pub/v/fc_native_image_resize.svg)](https://pub.dev/packages/fc_native_image_resize)

A Flutter plugin to resize images via native APIs.

|      | iOS | Android | macOS | Windows                |
| ---- | --- | ------- | ----- | ---------------------- |
| Path | ✅  | ✅      | ✅    | 　 ❌ (See note below) |
| Uri  | -   | ✅      | -     | -                      |

Supported image formats:

- Read
  - JPEG, PNG
  - Platform native image formats. e.g. HEIF/AVIF on iOS/macOS
- Write
  - JPEG, PNG

> **NOTE on Windows**: Starting from 0.9.0. Windows support has been removed. It's recommended to use the [image package](https://pub.dev/packages/image) instead of native Windows APIs as the latter has limited support for image formats.

## Usage

```dart
final plugin = FcNativeImageResize();

try {
  ///
  /// Resizes the [srcFile] with the given options and saves the results to [destFile].
  ///
  /// [srcFile] source image path.
  /// [srcFileUri] true if source image is a Uri (Android only).
  /// [destFile] destination image path.
  /// [keepAspectRatio] if true, keeps aspect ratio.
  /// [format] destination file format. 'png' or 'jpeg'.
  /// [quality] only applies to 'jpeg' type, 1-100 (100 best quality).
  await plugin.resizeFile(
            srcFile: srcFile,
            destFile: destFile,
            width: 300,
            height: 300,
            keepAspectRatio: true,
            format: 'jpeg',
            quality: 90);
} catch (err) {
  // Handle platform errors.
}
```

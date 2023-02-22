[![pub package](https://img.shields.io/pub/v/fc_native_image_resize.svg)](https://pub.dev/packages/fc_native_image_resize)

# fc_native_image_resize

A Flutter plugin for image resizing via native APIs.

| iOS | Android | macOS | Windows |
| --- | ------- | ----- | ------- |
| ✅  | ✅      | ✅    | ✅      |

Supported image formats:

- Read
  - JPEG, PNG, WEBP
  - Platform native image formats. e.g. HEIC on iOS/macOS
- Write
  - JPEG, PNG

## Usage

```dart
final plugin = FcNativeImageResize();

///
/// Resizes the [srcFile] with the given options and saves the results to [destFile].
///
/// [srcFile] source image path.
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
```

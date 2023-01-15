# fc_native_image_resize_example

To run this example project locally.

- cd `example`
- `flutter run -d <your device>`

## Usage

```dart
final _nativeImgResize = FcNativeImageResize();

/// Resizes the given [srcFile] with the given parameters and saves the results to [destFile].
/// [srcFile] source image path.
/// [destFile] destination image path.
/// [keepAspectRatio] if true, keeps aspect ratio.
/// [type] specifies image type of destination file. 'png' or 'jpeg'.
/// [quality] only applies for 'jpeg' type, 1-100 (100 best quality).
await _nativeImgResize.resizeFile(
          srcFile: srcFile,
          destFile: destFile,
          width: 300,
          height: 300,
          keepAspectRatio: true,
          type: 'jpeg',
          quality: 90)
```

# fc_native_image_resize

[![pub package](https://img.shields.io/pub/v/fc_native_image_resize.svg)](https://pub.dev/packages/fc_native_image_resize)

A Flutter plugin that resizes images using native APIs and saves the result to
a file or returns encoded image bytes.

|      | iOS | Android | macOS | Windows 11 |
| ---- | --- | ------- | ----- | ---------- |
| Path | ✅  | ✅      | ✅    | ✅         |
| URI  | ✅  | ✅      | ✅    | -          |

Android requires API 28 (Android 9) or later. Windows support targets Windows 11.

### Image Formats

- **Input:** JPEG, PNG, and other formats supported by the operating system,
  such as HEIF/AVIF on supported iOS and macOS versions. Windows input formats
  depend on the available Windows Imaging Component (WIC) codecs.
- **Output:** JPEG and lossless PNG.

## Usage

### Save to a File

```dart
import 'package:fc_native_image_resize/fc_native_image_resize.dart';

final plugin = FcNativeImageResize();

await plugin.resizeFile(
  srcFile: srcFile,
  destFile: destFile,
  width: 300,
  height: 300,
  keepAspectRatio: true,
  format: 'jpeg',
  quality: 90,
);
```

### Return Encoded Bytes

Use `resizeFileToBytes` when you do not need a destination file:

```dart
final bytes = await plugin.resizeFileToBytes(
  srcFile: srcFile,
  width: 300,
  height: 300,
  keepAspectRatio: true,
  format: 'jpeg',
  quality: 90,
);
```

The result is a `Uint8List` containing a complete encoded image, not raw pixels.
It can be displayed with `Image.memory(bytes)` or uploaded directly.

Both methods share the same native decoding, orientation correction, resizing,
and encoding pipeline. `resizeFile` writes the result to `destFile`, overwriting
an existing file. `resizeFileToBytes` returns the result without creating a file.

### Options

| Option | Meaning |
| ------ | ------- |
| `srcFile` | The source image's local file path, or a URI when `srcFileUri` is `true`. |
| `srcFileUri` | Defaults to `false`. URI input is supported on Android, iOS, and macOS, but not Windows. |
| `destFile` | The local destination path. Only required by `resizeFile`. |
| `width`, `height` | Output dimensions or maximum bounds, in pixels, as described below. |
| `keepAspectRatio` | Preserves the aspect ratio without upscaling when `true`; stretches to the exact dimensions when `false`. |
| `format` | `'png'` or `'jpeg'`. Determines the encoding independently of the destination file extension. |
| `quality` | JPEG quality from 1 to 100, where 100 is the highest quality. Defaults to 90. Ignored for PNG, but a supplied value must still be valid. |

With `keepAspectRatio: true`, `width` and `height` are maximum bounds, not
necessarily the final dimensions. For example, an 800 × 400 image resized within
300 × 300 bounds becomes 300 × 150. Either dimension may be `-1` to calculate it
from the other dimension; both cannot be `-1`. Images are never upscaled in this
mode, and each calculated dimension is at least one pixel.

With `keepAspectRatio: false`, both dimensions must be positive. The output
matches the requested size exactly, even if that requires stretching or upscaling.

### Errors

- `ArgumentError`: invalid dimensions, output format, or quality. Validation
  happens before the native platform is called.
- `FailedToDecodeImageFileException`: the source image cannot be opened or decoded.
- `PlatformException`: another native operation fails, such as encoding the image
  or writing the destination file.

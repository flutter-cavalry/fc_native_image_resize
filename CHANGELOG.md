# 2.0.0

- **Breaking**: Raise Android minimum SDK to API 28 (Android 9).
- Add `resizeFileToBytes`, returning encoded `Uint8List` image data on all platforms.
- Share native decoding, resizing, and encoding between file and byte outputs.
- Restore native Windows support, targeting Windows 11 with WIC.
- Use Android `ImageDecoder` for file/URI decoding, automatic EXIF orientation,
  and decode-time resizing; remove the legacy decoder and manual rotation helper.
- Release Android bitmap resources after encoding.
- Fix Darwin output pixel dimensions and apply EXIF orientation before resizing.
- Report encoding and decode failures consistently rather than silently succeeding.
- Reject zero/invalid dimensions, unsupported output formats, and quality outside
  1-100 with `ArgumentError` (previously some invalid options were accepted).

# 1.0.1

- Update Swift package.

# 1.0.0

- **Breaking**: Migrate to AGP 9
- **Breaking**: Min Flutter version: 3.44.0

# 0.15.0

- Fix EXIF orientation issue on Android.

# 0.14.2

- Switch to `Dispatchers.Default`.

# 0.14.0

- Add Swift Package Manager support.
- Add URL support iOS / macOS.

# 0.13.0

- Better error handling when it fails to decode a file.

# 0.12.0

- Move from Looper to dispatcher.

## 0.11.0

- Update to gradle 8

## 0.10.0

- Update Android project.
- Prevent upscaling when `keepAspectRatio` is `true`.

## 0.9.0

- Remove Windows implementation.

## 0.8.0

- Allow resizing with only width or height.

## 0.7.0

- Fix aspect ratio issues on iOS.

## 0.6.0

- Fix various issues in `FCImage`.

## 0.5.0

- Migrate to a shared codebase between macOS and iOS.
- Simplify resizing logic on macOS.

## 0.4.1

- Fix various issues on example project.

## 0.4.0

- Support Android Uri.

## 0.3.0

- Rename `type` to `format`.

## 0.2.0

- Update to Flutter 3.7.

## 0.1.0

- Add Windows support.

## 0.0.1

- Initial release.

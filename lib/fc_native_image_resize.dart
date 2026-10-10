import 'dart:typed_data';

import 'fc_native_image_resize_platform_interface.dart';

export 'failed_to_decode_image_file_exception.dart';

/// Resizes images using native APIs on Android, iOS, macOS, and Windows.
class FcNativeImageResize {
  /// Resizes the image at [srcFile] and writes the encoded result to [destFile].
  ///
  /// [srcFile] is a local file path by default. Set [srcFileUri] to `true` to
  /// interpret it as a URI on Android, iOS, or macOS. Windows supports local
  /// paths only. [destFile] must be a local file path; an existing file is
  /// overwritten.
  ///
  /// [width] and [height] are measured in pixels. When [keepAspectRatio] is
  /// `true`, they specify maximum bounds: the image retains its aspect ratio
  /// and is never upscaled. Either dimension may be `-1` to calculate it from
  /// the other dimension. When [keepAspectRatio] is `false`, both dimensions
  /// must be positive and the image is stretched to that exact size.
  /// A calculated dimension is at least one pixel.
  ///
  /// [format] must be `'png'` or `'jpeg'`, regardless of the destination file
  /// extension. [quality] defaults to 90 and controls JPEG encoding quality,
  /// from 1 to 100 (highest quality). PNG encoding is lossless and ignores
  /// [quality], but any supplied value must still be within that range.
  ///
  /// Throws [ArgumentError] for invalid options and
  /// [FailedToDecodeImageFileException] if the source cannot be decoded.
  /// Other native failures are reported as `PlatformException`.
  Future<void> resizeFile({
    required String srcFile,
    required String destFile,
    required int width,
    required int height,
    required bool keepAspectRatio,
    required String format,
    bool? srcFileUri,
    int? quality,
  }) {
    _validateOptions(width, height, keepAspectRatio, format, quality);
    return FcNativeImageResizePlatform.instance.resizeFile(
      srcFile: srcFile,
      destFile: destFile,
      width: width,
      height: height,
      keepAspectRatio: keepAspectRatio,
      format: format,
      srcFileUri: srcFileUri,
      quality: quality,
    );
  }

  /// Resizes the image at [srcFile] and returns its encoded bytes.
  ///
  /// The returned [Uint8List] contains a complete PNG or JPEG image, not raw
  /// pixels. No destination file is created.
  ///
  /// [srcFile], [srcFileUri], [width], [height], [keepAspectRatio], [format],
  /// and [quality] have the same meaning and validation rules as in
  /// [resizeFile]. Both methods share the same native processing pipeline
  /// and report the same types of errors.
  Future<Uint8List> resizeFileToBytes({
    required String srcFile,
    required int width,
    required int height,
    required bool keepAspectRatio,
    required String format,
    bool? srcFileUri,
    int? quality,
  }) {
    _validateOptions(width, height, keepAspectRatio, format, quality);
    return FcNativeImageResizePlatform.instance.resizeFileToBytes(
      srcFile: srcFile,
      width: width,
      height: height,
      keepAspectRatio: keepAspectRatio,
      format: format,
      srcFileUri: srcFileUri,
      quality: quality,
    );
  }

  void _validateOptions(
    int width,
    int height,
    bool keepAspectRatio,
    String format,
    int? quality,
  ) {
    if (width == 0 ||
        height == 0 ||
        width < -1 ||
        height < -1 ||
        (width == -1 && height == -1) ||
        (!keepAspectRatio && (width < 0 || height < 0))) {
      throw ArgumentError(
        'Dimensions must be positive, or one may be -1 '
        'when keepAspectRatio is true',
      );
    }
    if (format != 'png' && format != 'jpeg') {
      throw ArgumentError.value(format, 'format', 'Must be png or jpeg');
    }
    if (quality != null && (quality < 1 || quality > 100)) {
      throw ArgumentError.value(
        quality,
        'quality',
        'Must be between 1 and 100',
      );
    }
  }
}

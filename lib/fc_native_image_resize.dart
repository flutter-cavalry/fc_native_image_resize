import 'fc_native_image_resize_platform_interface.dart';
export 'failed_to_decode_image_file_exception.dart';

class FcNativeImageResize {
  /// Resizes the [srcFile] image with the given options and saves the results
  /// to [destFile].
  ///
  /// [srcFile] source image path.
  /// [srcFileUri] true if source image is a Uri (Android/iOS/macOS).
  /// [destFile] destination image path.
  /// [width] destination image width.
  /// Pass -1 to adjust width based on height (keepAspectRatio must be true).
  /// [height] destination image height.
  /// Pass -1 to adjust height based on width (keepAspectRatio must be true).
  /// [keepAspectRatio] if true, keeps aspect ratio.
  /// [format] destination file format. 'png' or 'jpeg'.
  /// [quality] only applies to 'jpeg' type, 1-100 (100 best quality).
  Future<void> resizeFile(
      {required String srcFile,
      required String destFile,
      required int width,
      required int height,
      required bool keepAspectRatio,
      required String format,
      bool? srcFileUri,
      int? quality}) {
    if (width < 0 && height < 0) {
      throw ArgumentError('width and height cannot be both negative');
    }
    if (!keepAspectRatio && (width < 0 || height < 0)) {
      throw ArgumentError(
          'width and height must be positive when keepAspectRatio is false');
    }
    return FcNativeImageResizePlatform.instance.resizeFile(
        srcFile: srcFile,
        destFile: destFile,
        width: width,
        height: height,
        keepAspectRatio: keepAspectRatio,
        format: format,
        srcFileUri: srcFileUri,
        quality: quality);
  }
}

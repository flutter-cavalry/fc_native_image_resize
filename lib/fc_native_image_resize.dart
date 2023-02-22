import 'fc_native_image_resize_platform_interface.dart';

class FcNativeImageResize {
  ///
  /// Resizes the [srcFile] with the given options and saves the results to [destFile].
  ///
  /// [srcFile] source image path.
  /// [destFile] destination image path.
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
      int? quality}) {
    return FcNativeImageResizePlatform.instance.resizeFile(
        srcFile: srcFile,
        destFile: destFile,
        width: width,
        height: height,
        keepAspectRatio: keepAspectRatio,
        format: format,
        quality: quality);
  }
}

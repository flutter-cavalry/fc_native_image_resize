import 'fc_native_image_resize_platform_interface.dart';

class FcNativeImageResize {
  /// Resizes the given [srcFile] with the given parameters and saves the results to [destFile].
  /// [srcFile] source image path.
  /// [destFile] destination image path.
  /// [keepAspectRatio] if true, keeps aspect ratio.
  /// [type] specifies image type of destination file. 'png' or 'jpeg'.
  /// [quality] only applies for 'jpeg' type, 1-100 (100 best quality).
  Future<void> resizeFile(
      {required String srcFile,
      required String destFile,
      required int width,
      required int height,
      required bool keepAspectRatio,
      required String type,
      double? quality}) {
    return FcNativeImageResizePlatform.instance.resizeFile(
        srcFile: srcFile,
        destFile: destFile,
        width: width,
        height: height,
        keepAspectRatio: keepAspectRatio,
        type: type,
        quality: quality);
  }
}

import 'fc_native_image_resize_platform_interface.dart';

class FcNativeImageResize {
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

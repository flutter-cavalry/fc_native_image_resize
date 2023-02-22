import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'fc_native_image_resize_method_channel.dart';

abstract class FcNativeImageResizePlatform extends PlatformInterface {
  /// Constructs a FcNativeImageResizePlatform.
  FcNativeImageResizePlatform() : super(token: _token);

  static final Object _token = Object();

  static FcNativeImageResizePlatform _instance =
      MethodChannelFcNativeImageResize();

  /// The default instance of [FcNativeImageResizePlatform] to use.
  ///
  /// Defaults to [MethodChannelFcNativeImageResize].
  static FcNativeImageResizePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FcNativeImageResizePlatform] when
  /// they register themselves.
  static set instance(FcNativeImageResizePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> resizeFile(
      {required String srcFile,
      required String destFile,
      required int width,
      required int height,
      required bool keepAspectRatio,
      required String format,
      int? quality}) {
    throw UnimplementedError('resizeFile() has not been implemented.');
  }
}

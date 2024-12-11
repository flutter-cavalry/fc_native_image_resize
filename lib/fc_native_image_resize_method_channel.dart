import 'package:fc_native_image_resize/failed_to_decode_image_file_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'fc_native_image_resize_platform_interface.dart';

/// An implementation of [FcNativeImageResizePlatform] that uses method channels.
class MethodChannelFcNativeImageResize extends FcNativeImageResizePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('fc_native_image_resize');
  final pluginError = 'PluginError';
  static const String failedToDecodeImageFile = 'FailedToDecodeImageFile';

  @override
  Future<void> resizeFile(
      {required String srcFile,
      required String destFile,
      required int width,
      required int height,
      required bool keepAspectRatio,
      required String format,
      bool? srcFileUri,
      int? quality}) async {
    try {
      await methodChannel.invokeMethod<void>('resizeFile', {
        'srcFile': srcFile,
        'destFile': destFile,
        'width': width,
        'height': height,
        'keepAspectRatio': keepAspectRatio,
        'type': format,
        'srcFileUri': srcFileUri,
        'quality': quality,
      });
    } on PlatformException catch (e) {
      switch(e.code) {
        case failedToDecodeImageFile : throw FailedToDecodeImageFileException(
          message: e.message!,
          details: e.details,
        );
        default: rethrow;
      }
    }
  }
}

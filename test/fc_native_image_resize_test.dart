import 'package:flutter_test/flutter_test.dart';
import 'package:fc_native_image_resize/fc_native_image_resize.dart';
import 'package:fc_native_image_resize/fc_native_image_resize_platform_interface.dart';
import 'package:fc_native_image_resize/fc_native_image_resize_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFcNativeImageResizePlatform
    with MockPlatformInterfaceMixin
    implements FcNativeImageResizePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FcNativeImageResizePlatform initialPlatform = FcNativeImageResizePlatform.instance;

  test('$MethodChannelFcNativeImageResize is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFcNativeImageResize>());
  });

  test('getPlatformVersion', () async {
    FcNativeImageResize fcNativeImageResizePlugin = FcNativeImageResize();
    MockFcNativeImageResizePlatform fakePlatform = MockFcNativeImageResizePlatform();
    FcNativeImageResizePlatform.instance = fakePlatform;

    expect(await fcNativeImageResizePlugin.getPlatformVersion(), '42');
  });
}

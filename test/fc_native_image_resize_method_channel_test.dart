import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fc_native_image_resize/fc_native_image_resize_method_channel.dart';

void main() {
  MethodChannelFcNativeImageResize platform = MethodChannelFcNativeImageResize();
  const MethodChannel channel = MethodChannel('fc_native_image_resize');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}

#import "FcNativeImageResizePlugin.h"
#if __has_include(<fc_native_image_resize/fc_native_image_resize-Swift.h>)
#import <fc_native_image_resize/fc_native_image_resize-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "fc_native_image_resize-Swift.h"
#endif

@implementation FcNativeImageResizePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFcNativeImageResizePlugin registerWithRegistrar:registrar];
}
@end

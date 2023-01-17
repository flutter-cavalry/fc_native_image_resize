#ifndef FLUTTER_PLUGIN_FC_NATIVE_IMAGE_RESIZE_PLUGIN_C_API_H_
#define FLUTTER_PLUGIN_FC_NATIVE_IMAGE_RESIZE_PLUGIN_C_API_H_

#include <flutter_plugin_registrar.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void FcNativeImageResizePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_FC_NATIVE_IMAGE_RESIZE_PLUGIN_C_API_H_

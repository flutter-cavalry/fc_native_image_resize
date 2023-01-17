#include "include/fc_native_image_resize/fc_native_image_resize_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "fc_native_image_resize_plugin.h"

void FcNativeImageResizePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  fc_native_image_resize::FcNativeImageResizePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

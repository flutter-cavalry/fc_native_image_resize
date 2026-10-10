cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "fc_native_image_resize")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "fc_native_image_resize_plugin")
add_library(${PLUGIN_NAME} SHARED
  "fc_native_image_resize_plugin.cpp"
  "image_resize.cpp"
)
apply_standard_settings(${PLUGIN_NAME})
target_compile_features(${PLUGIN_NAME} PUBLIC cxx_std_17)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL NOMINMAX)
target_include_directories(${PLUGIN_NAME} INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin windowscodecs ole32 oleaut32)
set(fc_native_image_resize_bundled_libraries "" PARENT_SCOPE)
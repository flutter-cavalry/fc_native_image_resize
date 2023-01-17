#include "fc_native_image_resize_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>
#include <gdiplus.h>
#include <stdio.h>
#pragma comment(lib,"gdiplus.lib")
using namespace Gdiplus;

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace fc_native_image_resize {

// https://github.com/flutter/plugins/blob/main/packages/camera/camera_windows/windows/camera_plugin.cpp
// Looks for |key| in |map|, returning the associated value if it is present, or
// a nullptr if not.
const flutter::EncodableValue* ValueOrNull(const flutter::EncodableMap& map, const char* key) {
    auto it = map.find(flutter::EncodableValue(key));
    if (it == map.end()) {
        return nullptr;
    }
    return &(it->second);
}

// Looks for |key| in |map|, returning the associated int64 value if it is
// present, or std::nullopt if not.
std::optional<int64_t> GetInt64ValueOrNull(const flutter::EncodableMap& map,
    const char* key) {
    auto value = ValueOrNull(map, key);
    if (!value) {
        return std::nullopt;
    }

    if (std::holds_alternative<int32_t>(*value)) {
        return static_cast<int64_t>(std::get<int32_t>(*value));
    }
    auto val64 = std::get_if<int64_t>(value);
    if (!val64) {
        return std::nullopt;
    }
    return *val64;
}

// Converts the given UTF-8 string to UTF-16.
std::wstring Utf16FromUtf8(const std::string& utf8_string) {
    if (utf8_string.empty()) {
        return std::wstring();
    }
    int target_length =
        ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8_string.data(),
            static_cast<int>(utf8_string.length()), nullptr, 0);
    if (target_length == 0) {
        return std::wstring();
    }
    std::wstring utf16_string;
    utf16_string.resize(target_length);
    int converted_length =
        ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8_string.data(),
            static_cast<int>(utf8_string.length()),
            utf16_string.data(), target_length);
    if (converted_length == 0) {
        return std::wstring();
    }
    return utf16_string;
}

int GetEncoderClsid(const WCHAR* format, CLSID* pClsid)
{
    UINT  num = 0;          // number of image encoders
    UINT  size = 0;         // size of the image encoder array in bytes

    ImageCodecInfo* pImageCodecInfo = NULL;

    GetImageEncodersSize(&num, &size);
    if (size == 0)
        return -1;  // Failure

    pImageCodecInfo = (ImageCodecInfo*)(malloc(size));
    if (pImageCodecInfo == NULL)
        return -1;  // Failure

    GetImageEncoders(num, size, pImageCodecInfo);

    for (UINT j = 0; j < num; ++j)
    {
        if (wcscmp(pImageCodecInfo[j].MimeType, format) == 0)
        {
            *pClsid = pImageCodecInfo[j].Clsid;
            free(pImageCodecInfo);
            return j;  // Success
        }
    }

    free(pImageCodecInfo);
    return -1;  // Failure
}

Size SizeToFit(Size originalSize, Size maxSize) {
    auto widthRatio = (double)maxSize.Width / originalSize.Width;
    auto heightRatio = (double)maxSize.Height / originalSize.Height;
    auto minAspectRatio = min(widthRatio, heightRatio);
    if (minAspectRatio > 1) {
        return originalSize;
    }
    return Size(INT(originalSize.Width * minAspectRatio), INT(originalSize.Height * minAspectRatio));
}

int ResizeImageFile(PCWSTR srcFile, PCWSTR destFile, int width, int height, const WCHAR* format, ULONG quality) {
    int returnCode = 0;
    // Initialize GDI+.
    GdiplusStartupInput gdiplusStartupInput;
    ULONG_PTR gdiplusToken;
    GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, NULL);
    {
        CLSID             encoderClsid;
        EncoderParameters encoderParameters;
        Status            stat;

        // Get an image from the disk.
        Image* srcImage = new Image(srcFile);
        auto newSize = SizeToFit(Size(srcImage->GetWidth(), srcImage->GetHeight()), Size(width, height));

        Image* destImage = new Bitmap(newSize.Width, newSize.Height);
        Graphics g(destImage);
        g.DrawImage(srcImage, 0, 0, newSize.Width, newSize.Height);

        GetEncoderClsid(format, &encoderClsid);

        // Before we call Image::Save, we must initialize an
        // EncoderParameters object. The EncoderParameters object
        // has an array of EncoderParameter objects. In this
        // case, there is only one EncoderParameter object in the array.
        // The one EncoderParameter object has an array of values.
        // In this case, there is only one value (of type ULONG)
        // in the array. We will let this value vary from 0 to 100.

        encoderParameters.Count = 1;
        encoderParameters.Parameter[0].Guid = EncoderQuality;
        encoderParameters.Parameter[0].Type = EncoderParameterValueTypeLong;
        encoderParameters.Parameter[0].NumberOfValues = 1;
        encoderParameters.Parameter[0].Value = &quality;
        stat = destImage->Save(destFile, &encoderClsid, &encoderParameters);
        if (stat != Ok) {
            returnCode = 1;
        }

        delete srcImage;
        delete destImage;
    }
    GdiplusShutdown(gdiplusToken);

    return returnCode;
}

// static
void FcNativeImageResizePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "fc_native_image_resize",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FcNativeImageResizePlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FcNativeImageResizePlugin::FcNativeImageResizePlugin() {}

FcNativeImageResizePlugin::~FcNativeImageResizePlugin() {}

void FcNativeImageResizePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const auto* argsPtr = std::get_if<flutter::EncodableMap>(method_call.arguments());
    assert(argsPtr);
    auto args = *argsPtr;
    if (method_call.method_name().compare("resizeFile") == 0) {
        // Required arguments are enforced on dart side.
        const auto* src_file =
            std::get_if<std::string>(ValueOrNull(args, "srcFile"));
        assert(src_file);

        const auto* dest_file =
            std::get_if<std::string>(ValueOrNull(args, "destFile"));
        assert(dest_file);

        const auto* width =
            std::get_if<int>(ValueOrNull(args, "width"));
        assert(width);

        const auto* height =
            std::get_if<int>(ValueOrNull(args, "height"));
        assert(height);

        // `quality` is optional.
        const auto* quality =
            std::get_if<int>(ValueOrNull(args, "quality"));

        const auto* outType =
            std::get_if<std::string>(ValueOrNull(args, "type"));
        assert(outType);

        auto pngFormat = outType->compare("png") == 0;
        auto save_res = ResizeImageFile(Utf16FromUtf8(*src_file).c_str(), Utf16FromUtf8(*dest_file).c_str(), *width, *height, pngFormat ? L"image/png" : L"image/jpeg", pngFormat ? 100 : (quality ? *quality : 80));

        if (save_res) {
            result->Error("Err", "Operation failed");
        }
        else {
            result->Success(flutter::EncodableValue(nullptr));
        }
    }
    else {
        result->NotImplemented();
    }
}

}  // namespace fc_native_image_resize_thumbnail
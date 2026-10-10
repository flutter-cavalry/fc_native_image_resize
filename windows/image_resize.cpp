#include "image_resize.h"

#include <windows.h>
#include <wincodec.h>
#include <wrl/client.h>

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <limits>
#include <sstream>

namespace fc_native_image_resize {
namespace {
using Microsoft::WRL::ComPtr;

void Check(HRESULT value) {
  if (FAILED(value)) {
    std::ostringstream message;
    message << "Windows imaging operation failed (HRESULT 0x" << std::hex
            << static_cast<unsigned long>(value) << ")";
    throw ResizeError("PluginError", message.str());
  }
}

std::wstring WidePath(const std::string& path) {
  if (path.empty() || path.find('\0') != std::string::npos ||
      path.size() > static_cast<size_t>(std::numeric_limits<int>::max())) {
    throw ResizeError("PluginError", "Invalid file path");
  }
  const int length = static_cast<int>(path.size());
  const int count = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
                                      path.data(), length, nullptr, 0);
  if (count == 0) throw ResizeError("PluginError", "Invalid UTF-8 file path");
  std::wstring result(count, L'\0');
  if (MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, path.data(), length,
                          result.data(), count) != count) {
    throw ResizeError("PluginError", "Invalid UTF-8 file path");
  }
  return result;
}

class ComApartment {
 public:
  ComApartment() : result_(CoInitializeEx(nullptr, COINIT_MULTITHREADED)) {
    if (result_ != RPC_E_CHANGED_MODE) Check(result_);
  }
  ~ComApartment() { if (SUCCEEDED(result_)) CoUninitialize(); }
 private:
  HRESULT result_;
};

WICBitmapTransformOptions Orientation(IWICBitmapFrameDecode* frame) {
  ComPtr<IWICMetadataQueryReader> reader;
  if (FAILED(frame->GetMetadataQueryReader(&reader))) return WICBitmapTransformRotate0;
  PROPVARIANT value;
  PropVariantInit(&value);
  HRESULT result = reader->GetMetadataByName(L"/app1/ifd/{ushort=274}", &value);
  if (FAILED(result)) {
    PropVariantClear(&value);
    result = reader->GetMetadataByName(L"/ifd/{ushort=274}", &value);
  }
  const unsigned int orientation = SUCCEEDED(result) && value.vt == VT_UI2 ? value.uiVal : 1;
  PropVariantClear(&value);
  switch (orientation) {
    case 2: return WICBitmapTransformFlipHorizontal;
    case 3: return WICBitmapTransformRotate180;
    case 4: return WICBitmapTransformFlipVertical;
    case 5: return static_cast<WICBitmapTransformOptions>(WICBitmapTransformRotate90 | WICBitmapTransformFlipHorizontal);
    case 6: return WICBitmapTransformRotate90;
    case 7: return static_cast<WICBitmapTransformOptions>(WICBitmapTransformRotate270 | WICBitmapTransformFlipHorizontal);
    case 8: return WICBitmapTransformRotate270;
    default: return WICBitmapTransformRotate0;
  }
}
}

std::vector<uint8_t> ResizeToBytes(const ResizeOptions& options) {
  if (options.width == 0 || options.height == 0 || options.width < -1 ||
      options.height < -1 || (options.width < 0 && options.height < 0) ||
      (!options.keep_aspect_ratio && (options.width < 0 || options.height < 0)) ||
      (options.format != "png" && options.format != "jpeg") ||
      options.quality < 1 || options.quality > 100) {
    throw ResizeError("PluginError", "Invalid resize options");
  }
  ComApartment apartment;
  ComPtr<IWICImagingFactory> factory;
  Check(CoCreateInstance(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER,
                         IID_PPV_ARGS(&factory)));
  ComPtr<IWICBitmap> decoded;
  try {
    ComPtr<IWICBitmapDecoder> decoder;
    const auto path = WidePath(options.source);
    Check(factory->CreateDecoderFromFilename(path.c_str(), nullptr, GENERIC_READ,
                                             WICDecodeMetadataCacheOnLoad, &decoder));
    ComPtr<IWICBitmapFrameDecode> frame;
    Check(decoder->GetFrame(0, &frame));
    ComPtr<IWICBitmapFlipRotator> rotated;
    Check(factory->CreateBitmapFlipRotator(&rotated));
    Check(rotated->Initialize(frame.Get(), Orientation(frame.Get())));
    Check(factory->CreateBitmapFromSource(rotated.Get(), WICBitmapCacheOnLoad, &decoded));
  } catch (const ResizeError& error) {
    throw ResizeError("FailedToDecodeImageFile", "Failed to decode image file: " + options.source + "; " + error.what());
  }
  UINT source_width = 0;
  UINT source_height = 0;
  Check(decoded->GetSize(&source_width, &source_height));
  if (source_width == 0 || source_height == 0) {
    throw ResizeError("FailedToDecodeImageFile", "Image has invalid dimensions");
  }
  UINT width = static_cast<UINT>(options.width);
  UINT height = static_cast<UINT>(options.height);
  if (options.keep_aspect_ratio) {
    const double width_ratio = options.width == -1 ? std::numeric_limits<double>::infinity()
        : static_cast<double>(options.width) / source_width;
    const double height_ratio = options.height == -1 ? std::numeric_limits<double>::infinity()
        : static_cast<double>(options.height) / source_height;
    const double ratio = std::min({1.0, width_ratio, height_ratio});
    width = std::max(1u, static_cast<UINT>(source_width * ratio));
    height = std::max(1u, static_cast<UINT>(source_height * ratio));
  }
  ComPtr<IWICBitmapScaler> scaler;
  Check(factory->CreateBitmapScaler(&scaler));
  Check(scaler->Initialize(decoded.Get(), width, height, WICBitmapInterpolationModeFant));
  const bool jpeg = options.format == "jpeg";
  ComPtr<IWICFormatConverter> converter;
  Check(factory->CreateFormatConverter(&converter));
  WICPixelFormatGUID pixel_format = jpeg ? GUID_WICPixelFormat24bppBGR : GUID_WICPixelFormat32bppBGRA;
  Check(converter->Initialize(scaler.Get(), pixel_format, WICBitmapDitherTypeNone,
                              nullptr, 0, WICBitmapPaletteTypeCustom));
  ComPtr<IStream> stream;
  Check(CreateStreamOnHGlobal(nullptr, TRUE, &stream));
  ComPtr<IWICBitmapEncoder> encoder;
  Check(factory->CreateEncoder(jpeg ? GUID_ContainerFormatJpeg : GUID_ContainerFormatPng,
                                nullptr, &encoder));
  Check(encoder->Initialize(stream.Get(), WICBitmapEncoderNoCache));
  ComPtr<IWICBitmapFrameEncode> frame;
  ComPtr<IPropertyBag2> properties;
  Check(encoder->CreateNewFrame(&frame, &properties));
  if (jpeg) {
    PROPBAG2 property = {};
    property.pstrName = const_cast<wchar_t*>(L"ImageQuality");
    VARIANT value;
    VariantInit(&value);
    value.vt = VT_R4;
    value.fltVal = static_cast<float>(options.quality) / 100.0f;
    Check(properties->Write(1, &property, &value));
  }
  Check(frame->Initialize(properties.Get()));
  Check(frame->SetSize(width, height));
  Check(frame->SetPixelFormat(&pixel_format));
  Check(frame->WriteSource(converter.Get(), nullptr));
  Check(frame->Commit());
  Check(encoder->Commit());
  STATSTG stat = {};
  Check(stream->Stat(&stat, STATFLAG_NONAME));
  if (stat.cbSize.QuadPart > std::numeric_limits<ULONG>::max()) {
    throw ResizeError("PluginError", "Encoded image is too large");
  }
  LARGE_INTEGER start = {};
  Check(stream->Seek(start, STREAM_SEEK_SET, nullptr));
  std::vector<uint8_t> bytes(static_cast<size_t>(stat.cbSize.QuadPart));
  ULONG count = 0;
  Check(stream->Read(bytes.data(), static_cast<ULONG>(bytes.size()), &count));
  if (count != bytes.size()) throw ResizeError("PluginError", "Incomplete image encoding");
  return bytes;
}

void WriteBytes(const std::string& path, const std::vector<uint8_t>& bytes) {
  std::ofstream output(std::filesystem::path(WidePath(path)), std::ios::binary);
  if (!output) throw ResizeError("PluginError", "Cannot open destination file: " + path);
  output.write(reinterpret_cast<const char*>(bytes.data()), static_cast<std::streamsize>(bytes.size()));
  output.close();
  if (!output) throw ResizeError("PluginError", "Cannot write destination file: " + path);
}

}

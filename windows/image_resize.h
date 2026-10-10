#ifndef FC_NATIVE_IMAGE_RESIZE_IMAGE_RESIZE_H_
#define FC_NATIVE_IMAGE_RESIZE_IMAGE_RESIZE_H_

#include <cstdint>
#include <stdexcept>
#include <string>
#include <vector>

namespace fc_native_image_resize {

struct ResizeOptions {
  std::string source;
  int width;
  int height;
  bool keep_aspect_ratio;
  std::string format;
  int quality = 90;
};

class ResizeError : public std::runtime_error {
 public:
    ResizeError(const std::string& error_code, const std::string& message)
      : std::runtime_error(message), code(error_code) {}
  const std::string code;
};

std::vector<uint8_t> ResizeToBytes(const ResizeOptions& options);
void WriteBytes(const std::string& path, const std::vector<uint8_t>& bytes);

}

#endif

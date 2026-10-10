#include "include/fc_native_image_resize/fc_native_image_resize_plugin_c_api.h"
#include "image_resize.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <condition_variable>
#include <deque>
#include <memory>
#include <mutex>
#include <thread>
#include <utility>

namespace fc_native_image_resize {
namespace {
using Value = flutter::EncodableValue;
using Arguments = flutter::EncodableMap;
using Result = flutter::MethodResult<Value>;
constexpr UINT kCompleted = WM_APP + 1;
constexpr wchar_t kWindowClass[] = L"FcNativeImageResizeCompletionWindow";

template <typename T>
T Argument(const Arguments& args, const char* key) {
  const auto found = args.find(Value(key));
  if (found == args.end() || !std::holds_alternative<T>(found->second)) {
    throw ResizeError("PluginError", std::string("Invalid argument: ") + key);
  }
  return std::get<T>(found->second);
}

template <typename T>
T OptionalArgument(const Arguments& args, const char* key, T fallback) {
  const auto found = args.find(Value(key));
  if (found == args.end() || found->second.IsNull()) return fallback;
  return Argument<T>(args, key);
}

class FcNativeImageResizePlugin : public flutter::Plugin {
 public:
  explicit FcNativeImageResizePlugin(flutter::PluginRegistrarWindows* registrar) {
    static std::once_flag registered;
    std::call_once(registered, [] {
      WNDCLASSW window_class = {};
      window_class.lpfnWndProc = WindowProc;
      window_class.hInstance = GetModuleHandleW(nullptr);
      window_class.lpszClassName = kWindowClass;
      RegisterClassW(&window_class);
    });
    window_ = CreateWindowExW(0, kWindowClass, L"", 0, 0, 0, 0, 0, HWND_MESSAGE,
                              nullptr, GetModuleHandleW(nullptr), this);
    if (window_) worker_ = std::thread([this] { Work(); });
    channel_ = std::make_unique<flutter::MethodChannel<Value>>(
        registrar->messenger(), "fc_native_image_resize", &flutter::StandardMethodCodec::GetInstance());
    channel_->SetMethodCallHandler([this](const auto& call, auto result) {
      if (call.method_name() != "resizeFile" && call.method_name() != "resizeFileToBytes") {
        result->NotImplemented();
        return;
      }
      if (!window_) {
        result->Error("PluginError", "Cannot initialize Windows resize worker");
        return;
      }
      const auto* args = call.arguments() ? std::get_if<Arguments>(call.arguments()) : nullptr;
      if (!args) {
        result->Error("PluginError", "Invalid resize arguments");
        return;
      }
      {
        std::lock_guard<std::mutex> lock(mutex_);
        pending_.push_back({*args, call.method_name() == "resizeFileToBytes", std::move(result)});
      }
      wake_.notify_one();
    });
  }

  ~FcNativeImageResizePlugin() override {
    channel_->SetMethodCallHandler(nullptr);
    {
      std::lock_guard<std::mutex> lock(mutex_);
      stopping_ = true;
      pending_.clear();
    }
    wake_.notify_one();
    if (worker_.joinable()) worker_.join();
    if (window_) DestroyWindow(window_);
  }

 private:
  struct Request {
    Arguments args;
    bool return_bytes;
    std::unique_ptr<Result> result;
  };
  struct Completion {
    bool return_bytes;
    std::unique_ptr<Result> result;
    std::vector<uint8_t> bytes;
    std::string error_code;
    std::string error_message;
  };

  static LRESULT CALLBACK WindowProc(HWND window, UINT message, WPARAM word, LPARAM param) {
    if (message == WM_NCCREATE) {
      const auto* creation = reinterpret_cast<CREATESTRUCTW*>(param);
      SetWindowLongPtrW(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(creation->lpCreateParams));
    }
    auto* plugin = reinterpret_cast<FcNativeImageResizePlugin*>(GetWindowLongPtrW(window, GWLP_USERDATA));
    if (plugin && message == kCompleted) {
      plugin->Complete();
      return 0;
    }
    return DefWindowProcW(window, message, word, param);
  }

  void Work() {
    for (;;) {
      Request request;
      {
        std::unique_lock<std::mutex> lock(mutex_);
        wake_.wait(lock, [this] { return stopping_ || !pending_.empty(); });
        if (stopping_) return;
        request = std::move(pending_.front());
        pending_.pop_front();
      }
      Completion completion{request.return_bytes, std::move(request.result), {}, {}, {}};
      try {
        if (OptionalArgument<bool>(request.args, "srcFileUri", false)) {
          throw ResizeError("PluginError", "Windows supports local file paths, not source URIs");
        }
        ResizeOptions options{
          Argument<std::string>(request.args, "srcFile"),
          Argument<int32_t>(request.args, "width"),
          Argument<int32_t>(request.args, "height"),
          Argument<bool>(request.args, "keepAspectRatio"),
          Argument<std::string>(request.args, "type"),
          OptionalArgument<int32_t>(request.args, "quality", 90),
        };
        completion.bytes = ResizeToBytes(options);
        if (!request.return_bytes) {
          WriteBytes(Argument<std::string>(request.args, "destFile"), completion.bytes);
          completion.bytes.clear();
        }
      } catch (const ResizeError& error) {
        completion.error_code = error.code;
        completion.error_message = error.what();
      } catch (const std::exception& error) {
        completion.error_code = "PluginError";
        completion.error_message = error.what();
      }
      {
        std::lock_guard<std::mutex> lock(mutex_);
        if (stopping_) return;
        completed_.push_back(std::move(completion));
      }
      PostMessageW(window_, kCompleted, 0, 0);
    }
  }

  void Complete() {
    std::deque<Completion> completed;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      completed.swap(completed_);
    }
    for (auto& completion : completed) {
      if (!completion.error_code.empty()) {
        completion.result->Error(completion.error_code, completion.error_message);
      } else if (completion.return_bytes) {
        completion.result->Success(Value(std::move(completion.bytes)));
      } else {
        completion.result->Success();
      }
    }
  }

  HWND window_ = nullptr;
  std::unique_ptr<flutter::MethodChannel<Value>> channel_;
  std::thread worker_;
  std::mutex mutex_;
  std::condition_variable wake_;
  bool stopping_ = false;
  std::deque<Request> pending_;
  std::deque<Completion> completed_;
};
}
}

void FcNativeImageResizePluginCApiRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar) {
  auto* windows_registrar = flutter::PluginRegistrarManager::GetInstance()
      ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar);
  windows_registrar->AddPlugin(std::make_unique<fc_native_image_resize::FcNativeImageResizePlugin>(windows_registrar));
}

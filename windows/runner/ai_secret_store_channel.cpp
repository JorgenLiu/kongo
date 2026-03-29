#include "ai_secret_store_channel.h"

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>

namespace {
constexpr char kAiSecretChannelName[] = "kongo/ai_secrets";
}  // namespace

void AiSecretStoreChannel::Register(flutter::BinaryMessenger* messenger) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, kAiSecretChannelName,
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const auto& method = call.method_name();

        if (method == "isSupported") {
          result->Success(flutter::EncodableValue(false));
          return;
        }

        if (method == "loadApiKey") {
          result->Success();
          return;
        }

        if (method == "saveApiKey" || method == "clearApiKey") {
          result->Success();
          return;
        }

        result->NotImplemented();
      });

  // Keep channel alive for app lifetime.
  channel.release();
}

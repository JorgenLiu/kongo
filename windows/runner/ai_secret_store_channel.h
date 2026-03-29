#ifndef RUNNER_AI_SECRET_STORE_CHANNEL_H_
#define RUNNER_AI_SECRET_STORE_CHANNEL_H_

#include <flutter/binary_messenger.h>

class AiSecretStoreChannel {
 public:
  static void Register(flutter::BinaryMessenger* messenger);
};

#endif  // RUNNER_AI_SECRET_STORE_CHANNEL_H_

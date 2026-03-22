import '../exceptions/app_exception.dart';

enum ProviderErrorType {
  validation,
  business,
  database,
  fileStorage,
  ai,
  unknown,
}

class ProviderError {
  final ProviderErrorType type;
  final String message;
  final String? code;

  const ProviderError({
    required this.type,
    required this.message,
    this.code,
  });

  factory ProviderError.fromObject(Object error) {
    if (error is ValidationException) {
      return ProviderError(
        type: ProviderErrorType.validation,
        message: error.message,
        code: error.code,
      );
    }

    if (error is BusinessException) {
      return ProviderError(
        type: ProviderErrorType.business,
        message: error.message,
        code: error.code,
      );
    }

    if (error is DatabaseException) {
      return ProviderError(
        type: ProviderErrorType.database,
        message: error.message,
        code: error.code,
      );
    }

    if (error is FileStorageException) {
      return ProviderError(
        type: ProviderErrorType.fileStorage,
        message: error.message,
        code: error.code,
      );
    }

    if (error is AiException) {
      return ProviderError(
        type: ProviderErrorType.ai,
        message: error.message,
        code: error.code,
      );
    }

    return ProviderError(
      type: ProviderErrorType.unknown,
      message: error.toString(),
    );
  }
}
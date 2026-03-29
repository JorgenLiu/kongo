/// 应用异常基类。
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final Exception? originalException;

  const AppException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() => message;
}

class DatabaseException extends AppException {
  const DatabaseException({
    required super.message,
    super.code,
    super.originalException,
  });
}

class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
  });
}

class BusinessException extends AppException {
  const BusinessException({
    required super.message,
    super.code,
  });
}

class FileStorageException extends AppException {
  const FileStorageException({
    required super.message,
    super.code,
    super.originalException,
  });
}

class AiException extends AppException {
  const AiException({
    required super.message,
    super.code,
    super.originalException,
  });
}

class ReminderException extends AppException {
  const ReminderException({
    required super.message,
    super.code,
    super.originalException,
  });
}
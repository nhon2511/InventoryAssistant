/// Base exception for server-related errors from Supabase.
class ServerException implements Exception {
  const ServerException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException(message: $message, statusCode: $statusCode)';
}

/// Exception for Supabase Auth errors.
class AuthException implements Exception {
  const AuthException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'AuthException(message: $message, statusCode: $statusCode)';
}

/// Exception for local cache operations.
class CacheException implements Exception {
  const CacheException({required this.message});

  final String message;

  @override
  String toString() => 'CacheException(message: $message)';
}

/// Exception for barcode/QR scanner operations.
class ScannerException implements Exception {
  const ScannerException({required this.message});

  final String message;

  @override
  String toString() => 'ScannerException(message: $message)';
}

/// Exception for OCR text recognition operations.
class OcrException implements Exception {
  const OcrException({required this.message});

  final String message;

  @override
  String toString() => 'OcrException(message: $message)';
}

/// Exception for AI / LLM / Edge Function operations.
class AiException implements Exception {
  const AiException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'AiException(message: $message, statusCode: $statusCode)';
}

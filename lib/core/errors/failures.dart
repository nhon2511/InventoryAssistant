import 'package:equatable/equatable.dart';

/// Base sealed class for all failures in the application.
///
/// Extends [Equatable] to enable value comparison for testing.
sealed class Failure extends Equatable {
  const Failure({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

/// Failure from Supabase REST / Realtime / Edge Function calls.
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

/// Failure from Supabase Auth operations.
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.statusCode});
}

/// Failure from local cache / shared preferences / secure storage.
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// Failure when no internet connection is available.
class NetworkFailure extends Failure {
  const NetworkFailure()
      : super(message: 'Không có kết nối mạng. Vui lòng kiểm tra lại.');
}

/// Failure from barcode/QR scanning operations.
class ScannerFailure extends Failure {
  const ScannerFailure({required super.message});
}

/// Failure from OCR text recognition operations.
class OcrFailure extends Failure {
  const OcrFailure({required super.message});
}

/// Failure from AI / LLM / Edge Function operations.
class AiFailure extends Failure {
  const AiFailure({required super.message, super.statusCode});
}

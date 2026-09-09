import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/ai_assistant/data/datasources/ai_remote_datasource.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/parsed_intent.dart';
import 'package:smart_wms/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';

class AiAssistantRepositoryImpl implements AiAssistantRepository {
  const AiAssistantRepositoryImpl(this._remoteDataSource);

  final AiRemoteDataSource _remoteDataSource;

  @override
  FutureEither<ParsedIntent> parseIntent(String userText) async {
    try {
      final data = await _remoteDataSource.parseIntent(userText);
      final intent = ParsedIntent(
        intent: data['intent'] as String? ?? 'unknown',
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
        entities: (data['entities'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v.toString())) ??
            {},
      );
      return Right(intent);
    } on AiException catch (e) {
      return Left(AiFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  FutureEither<String> queryStock(Map<String, String> entities) async {
    try {
      final result = await _remoteDataSource.queryStock(entities);
      return Right(result);
    } on AiException catch (e) {
      return Left(AiFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}

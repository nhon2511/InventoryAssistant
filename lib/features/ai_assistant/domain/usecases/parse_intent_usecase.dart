import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/parsed_intent.dart';
import 'package:smart_wms/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';

/// Parses user text into a structured intent via LLM.
class ParseIntentUseCase extends UseCase<ParsedIntent, String> {
  const ParseIntentUseCase(this._repository);

  final AiAssistantRepository _repository;

  @override
  FutureEither<ParsedIntent> call(String userText) {
    return _repository.parseIntent(userText);
  }
}

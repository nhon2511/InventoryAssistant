import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/parsed_intent.dart';

/// Abstract repository contract for AI assistant operations.
abstract class AiAssistantRepository {
  /// Sends user text to the LLM Edge Function for intent parsing.
  FutureEither<ParsedIntent> parseIntent(String userText);

  /// Queries stock information based on parsed entities.
  FutureEither<String> queryStock(Map<String, String> entities);
}

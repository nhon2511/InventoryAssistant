import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/core/network/supabase_client_provider.dart';
import 'package:smart_wms/features/ai_assistant/data/datasources/ai_remote_datasource.dart';
import 'package:smart_wms/features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:smart_wms/features/ai_assistant/domain/usecases/parse_intent_usecase.dart';
import 'package:smart_wms/features/ai_assistant/domain/usecases/query_stock_usecase.dart';

part 'ai_chat_controller.g.dart';

/// Controller managing the AI assistant chat conversation.
@riverpod
class AiChatController extends _$AiChatController {
  late final ParseIntentUseCase _parseIntent;
  late final QueryStockUseCase _queryStock;

  @override
  AiChatState build() {
    final client = ref.watch(supabaseClientProvider);
    final ds = AiRemoteDataSourceImpl(client);
    final repo = AiAssistantRepositoryImpl(ds);

    _parseIntent = ParseIntentUseCase(repo);
    _queryStock = QueryStockUseCase(repo);

    return const AiChatState();
  }

  /// Processes a user message: parse intent → execute action → respond.
  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    // Add user message to chat history.
    final userMessage = ChatMessage(
      role: ChatRole.user,
      content: userText,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isProcessing: true,
    );

    // Step 1: Parse intent via LLM Edge Function.
    final intentResult = await _parseIntent(userText);

    final String response = await intentResult.fold(
      (failure) async => failure.message,
      (intent) async {
        if (!intent.isConfident) {
          return 'Xin lỗi, tôi không hiểu rõ yêu cầu. '
              'Bạn có thể nói rõ hơn được không?';
        }

        // Step 2: Execute action based on intent.
        return switch (intent.intent) {
          'query_stock' => await _handleQueryStock(intent.entities),
          'create_order' => 'Chức năng tạo đơn qua giọng nói '
              'sẽ sớm được hỗ trợ.',
          _ => 'Tôi nhận được yêu cầu "${intent.intent}" '
              'nhưng chưa hỗ trợ xử lý.',
        };
      },
    );

    // Add assistant response.
    final assistantMessage = ChatMessage(
      role: ChatRole.assistant,
      content: response,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, assistantMessage],
      isProcessing: false,
    );
  }

  Future<String> _handleQueryStock(Map<String, String> entities) async {
    final result = await _queryStock(entities);
    return result.fold(
      (failure) => 'Lỗi khi truy vấn: ${failure.message}',
      (answer) => answer,
    );
  }

  /// Clears the chat history.
  void clearChat() {
    state = const AiChatState();
  }
}

/// State for the AI chat conversation.
class AiChatState {
  const AiChatState({
    this.messages = const [],
    this.isProcessing = false,
  });

  final List<ChatMessage> messages;
  final bool isProcessing;

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isProcessing,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

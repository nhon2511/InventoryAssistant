import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/core/config/app_config.dart';
import 'package:smart_wms/core/network/supabase_client_provider.dart';
import 'package:smart_wms/features/ai_assistant/data/datasources/ai_remote_datasource.dart';
import 'package:smart_wms/features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart';
import 'package:smart_wms/features/ai_assistant/data/repositories/mock_ai_assistant_repository.dart';
import 'package:smart_wms/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/ai_result.dart';
import 'package:smart_wms/features/ai_assistant/domain/usecases/parse_intent_usecase.dart';
import 'package:smart_wms/features/ai_assistant/domain/usecases/query_stock_usecase.dart';

part 'ai_chat_controller.g.dart';

/// Controller managing the AI assistant chat conversation.
@riverpod
class AiChatController extends _$AiChatController {
  late ParseIntentUseCase _parseIntent;
  late QueryStockUseCase _queryStock;

  @override
  AiChatState build() {
    final AiAssistantRepository repo;
    if (AppConfig.useMock) {
      repo = const MockAiAssistantRepository();
    } else {
      final client = ref.watch(supabaseClientProvider);
      repo = AiAssistantRepositoryImpl(AiRemoteDataSourceImpl(client));
    }

    _parseIntent = ParseIntentUseCase(repo);
    _queryStock = QueryStockUseCase(repo);

    return const AiChatState();
  }

  /// Processes a user message: parse intent → execute action → respond.
  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty || state.isProcessing) return;

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

    try {
      // Step 1: Parse intent via the selected repository.
      final intentResult = await _parseIntent(userText);

      final String response = await intentResult.fold(
        (failure) async => failure.message,
        (intent) async {
          if (!intent.isConfident) {
            return 'Xin lỗi, tôi không hiểu rõ yêu cầu. '
                'Bạn có thể nói rõ hơn được không?';
          }
          return switch (intent.intent) {
            'query_stock' => await _handleQueryStock(intent.entities),
            'create_order' => 'Tôi đã nhận yêu cầu tạo phiếu '
                '${intent.entities['type'] == 'outbound' ? 'xuất' : 'nhập'}. '
                'Bạn cần kiểm tra mặt hàng và số lượng trước khi xác nhận.',
            _ => 'Tôi nhận được yêu cầu "${intent.intent}" '
                'nhưng chưa hỗ trợ xử lý.',
          };
        },
      );

      final assistantMessage = ChatMessage(
        role: ChatRole.assistant,
        content: response,
        timestamp: DateTime.now(),
        result: intentResult.fold(
          (_) => AiResult(type: AiResultType.text, text: response),
          (intent) {
            if (!intent.isConfident) return AiResult(type: AiResultType.text, text: response);
            if (intent.intent == 'query_stock') {
              return AiResult(type: AiResultType.stockInfo, text: response,
                  productName: intent.entities['product_name']);
            }
            if (intent.intent == 'create_order') {
              final match = RegExp(r'[0-9]+').firstMatch(userText);
              return AiResult(
                type: intent.entities['type'] == 'outbound'
                    ? AiResultType.draftOutbound : AiResultType.draftInbound,
                text: response,
                productName: intent.entities['product_name'] ??
                    (userText.toLowerCase().contains('hảo hảo') ? 'Mì Hảo Hảo' : null),
                quantity: int.tryParse(match?.group(0) ?? ''),
                lotCode: intent.entities['lot_code'],
                locationCode: intent.entities['location_code'],
              );
            }
            return AiResult(type: AiResultType.text, text: response);
          },
        ),
        metadata: intentResult.fold(
          (_) => null,
          (intent) => intent.intent == 'create_order' && intent.isConfident
              ? {
                  'type': intent.entities['type'] == 'outbound'
                      ? 'draft_outbound'
                      : 'draft_inbound',
                }
              : intent.intent == 'query_stock' && intent.isConfident
                  ? {'type': 'stock_info'}
                  : null,
        ),
      );
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isProcessing: false,
      );
    } catch (_) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            role: ChatRole.assistant,
            content: 'Không thể xử lý yêu cầu lúc này. Vui lòng thử lại.',
            timestamp: DateTime.now(),
          ),
        ],
        isProcessing: false,
      );
    }
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

  void updateDraft(int index, AiResult result) {
    if (index < 0 || index >= state.messages.length || !result.isDraft) return;
    final messages = [...state.messages];
    final old = messages[index];
    messages[index] = ChatMessage(role: old.role, content: old.content,
        timestamp: old.timestamp, result: result);
    state = state.copyWith(messages: messages);
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

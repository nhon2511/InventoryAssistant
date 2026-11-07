import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/core/di/ai_assistant_providers.dart';
import 'package:smart_wms/core/di/inventory_providers.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/order_draft_preview.dart';
import 'package:smart_wms/features/ai_assistant/domain/usecases/resolve_order_draft_usecase.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/order_draft.dart';
import 'package:smart_wms/features/ai_assistant/domain/usecases/create_draft_order_usecase.dart';
import 'package:smart_wms/features/ai_assistant/domain/usecases/parse_intent_usecase.dart';
import 'package:smart_wms/features/ai_assistant/domain/usecases/query_stock_usecase.dart';

part 'ai_chat_controller.g.dart';

@riverpod
class AiChatController extends _$AiChatController {
  late final ParseIntentUseCase _parseIntent;
  late final QueryStockUseCase _queryStock;
  late final CreateDraftOrderUseCase _createDraftOrder;

  @override
  AiChatState build() {
    _parseIntent = ref.watch(parseIntentUseCaseProvider);
    _queryStock = ref.watch(queryStockUseCaseProvider);
    _createDraftOrder = ref.watch(createDraftOrderUseCaseProvider);

    return const AiChatState();
  }

  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty || state.isProcessing) return;
    final text = userText.trim();
    state = AiChatState(
      messages: [
        ...state.messages,
        ChatMessage(
          role: ChatRole.user,
          content: text,
          timestamp: DateTime.now(),
        ),
      ],
      isProcessing: true,
    );

    // Step 1: Parse intent via LLM Edge Function.
    final intentResult = await _parseIntent(userText);

    await intentResult.fold(
      (failure) async {
        final errorMessage = ChatMessage(
          role: ChatRole.assistant,
          content: failure.message,
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          messages: [...state.messages, errorMessage],
          isProcessing: false,
        );
      },
      (intent) async {
        if (!intent.isConfident) {
          final msg = ChatMessage(
            role: ChatRole.assistant,
            content: 'Xin lỗi, tôi không hiểu rõ yêu cầu. '
                'Bạn có thể nói rõ hơn được không?',
            timestamp: DateTime.now(),
          );
          state = state.copyWith(
            messages: [...state.messages, msg],
            isProcessing: false,
          );
          return;
        }

        // Step 2: Execute action based on intent.
        switch (intent.intent) {
          case 'query_stock':
            await _handleQueryStock(intent.entities);
          case 'create_order':
            await _handleCreateOrder(intent.entities);
          default:
            final msg = ChatMessage(
              role: ChatRole.assistant,
              content: 'Tôi nhận được yêu cầu "${intent.intent}" '
                  'nhưng chưa hỗ trợ xử lý.',
              timestamp: DateTime.now(),
            );
            state = state.copyWith(
              messages: [...state.messages, msg],
              isProcessing: false,
            );
        }
      },
    );
  }

  Future<void> _handleQueryStock(Map<String, String> entities) async {
    final result = await _queryStock(entities);
    final content = result.fold(
      (failure) => 'Lỗi khi truy vấn: ${failure.message}',
      (answer) => answer,
    );

    final msg = ChatMessage(
      role: ChatRole.assistant,
      content: content,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, msg],
      isProcessing: false,
    );
  }

  Future<void> _handleCreateOrder(Map<String, String> entities) async {
    final result = await _createDraftOrder(entities);
    result.fold(
      (failure) {
        final msg = ChatMessage(
          role: ChatRole.assistant,
          content: 'Không thể tạo phiếu nháp: ${failure.message}',
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          messages: [...state.messages, msg],
          isProcessing: false,
        );
      },
      (draft) {
        final msg = ChatMessage(
          role: ChatRole.assistant,
          content: 'AI đã tạo bản nháp **${draft.orderTypeLabel}** '
              'với ${draft.items.length} mặt hàng. '
              'Vui lòng kiểm tra và xác nhận bên dưới.',
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          messages: [...state.messages, msg],
          isProcessing: false,
          pendingDraft: draft,
        );
      },
    );
  }

  /// Clears the pending draft after confirmation or cancellation.
  void clearDraft() {
    state = AiChatState(
      messages: state.messages,
      isProcessing: state.isProcessing,
    );
  }

  /// Clears the chat history.
  void clearChat() {
    if (!state.isProcessing) state = const AiChatState();
  }

  void dismissDraft() => state = AiChatState(
    messages: state.messages,
    error: state.error,
    lastFailedText: state.lastFailedText,
  );
}

class AiChatState {
  const AiChatState({
    this.messages = const [],
    this.isProcessing = false,
    this.pendingDraft,
  });

  final List<ChatMessage> messages;
  final bool isProcessing;
  final OrderDraft? pendingDraft;

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isProcessing,
    OrderDraft? pendingDraft,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isProcessing: isProcessing ?? this.isProcessing,
      pendingDraft: pendingDraft ?? this.pendingDraft,
    );
  }
}

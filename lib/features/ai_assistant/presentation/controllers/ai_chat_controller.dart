import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/core/di/ai_assistant_providers.dart';
import 'package:smart_wms/core/di/inventory_providers.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/order_draft_preview.dart';
import 'package:smart_wms/features/ai_assistant/domain/usecases/resolve_order_draft_usecase.dart';

part 'ai_chat_controller.g.dart';

@riverpod
class AiChatController extends _$AiChatController {
  @override
  AiChatState build() => const AiChatState();

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
    OrderDraftPreview? draft;
    String? error;
    String response;
    try {
      final intentResult = await ref.read(parseIntentUseCaseProvider)(text);
      response = await intentResult.fold(
        (failure) async {
          error = 'Không xử lý được yêu cầu. Kiểm tra kết nối và thử lại.';
          return error!;
        },
        (intent) async {
          if (!intent.isConfident) {
            return 'Chưa hiểu rõ yêu cầu. Vui lòng cung cấp SKU, số lượng và vị trí cụ thể.';
          }
          if (intent.intent == 'query_stock') {
            final result = await ref.read(queryStockUseCaseProvider)(
              intent.entities,
            );
            return result.fold((failure) {
              error = 'Không truy vấn được tồn kho. Vui lòng thử lại.';
              return error!;
            }, (answer) => answer);
          }
          if ([
            'create_order',
            'create_inbound_draft',
            'create_outbound_draft',
          ].contains(intent.intent)) {
            final result = await ResolveOrderDraftUseCase(
              ref.read(inventoryRepositoryProvider),
            )(intent);
            return result.fold((failure) => failure.message, (preview) {
              draft = preview;
              return 'Đã chuẩn bị bản xem trước. Mở để kiểm tra, sửa hoặc hủy. Chưa lưu phiếu và chưa thay đổi tồn kho.';
            });
          }
          return 'Chưa hỗ trợ yêu cầu này. Bạn có thể tra tồn hoặc tạo phiếu nháp.';
        },
      );
    } on Exception {
      error = 'Không kết nối được trợ lý. Vui lòng thử lại.';
      response = error!;
    }
    if (!ref.mounted) return;
    state = AiChatState(
      messages: [
        ...state.messages,
        ChatMessage(
          role: ChatRole.assistant,
          content: response,
          timestamp: DateTime.now(),
        ),
      ],
      draft: draft,
      error: error,
      lastFailedText: error == null ? null : text,
    );
  }

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
    this.draft,
    this.error,
    this.lastFailedText,
  });
  final List<ChatMessage> messages;
  final bool isProcessing;
  final OrderDraftPreview? draft;
  final String? error;
  final String? lastFailedText;
}

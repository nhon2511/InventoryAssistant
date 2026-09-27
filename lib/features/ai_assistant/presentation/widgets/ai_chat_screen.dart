import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_wms/app/theme/app_tokens.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/ai_result.dart';
import 'package:smart_wms/features/ai_assistant/presentation/widgets/ai_result_card.dart';
import 'package:smart_wms/features/ai_assistant/presentation/controllers/ai_chat_controller.dart';

/// AI assistant chat screen with text input and conversation display.
class AiChatScreen extends HookConsumerWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(aiChatControllerProvider);
    final textController = useTextEditingController();
    final scrollController = useScrollController();
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
      return null;
    }, [chatState.messages.length, chatState.isProcessing]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ lý AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Xóa hội thoại',
            onPressed: chatState.messages.isEmpty
                ? null
                : () => showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Xóa hội thoại?'),
                        content: const Text('Các tin nhắn hiện tại sẽ bị xóa.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Hủy'),
                          ),
                          FilledButton(
                            onPressed: () {
                              ref.read(aiChatControllerProvider.notifier).clearChat();
                              Navigator.pop(dialogContext);
                            },
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages list
          Expanded(
            child: chatState.messages.isEmpty
                ? _EmptyChat(onSuggestion: (text) {
                    textController.text = text;
                    _sendMessage(ref, textController);
                  })
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      return _ChatBubble(
                        message: chatState.messages[index],
                        onDraftChanged: (result) => ref.read(aiChatControllerProvider.notifier).updateDraft(index, result),
                      );
                    },
                  ),
          ),

          // Processing indicator
          if (chatState.isProcessing)
            const Padding(
              padding: EdgeInsets.all(AppTokens.md),
              child: Row(
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: AppTokens.md),
                  Text('Trợ lý đang xử lý...'),
                ],
              ),
            ),

          // Text input
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: 'Hỏi về tồn kho...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (text) {
                      _sendMessage(ref, textController);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: chatState.isProcessing
                      ? null
                      : () => _sendMessage(ref, textController),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(WidgetRef ref, TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isNotEmpty) {
      ref.read(aiChatControllerProvider.notifier).sendMessage(text);
      controller.clear();
    }
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onSuggestion});
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Xin chào! Tôi là trợ lý AI kho hàng.\n'
            'Hãy hỏi tôi về tồn kho nhé!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppTokens.lg),
          ActionChip(
            label: const Text('Kho hiện còn những gì?'),
            onPressed: () => onSuggestion('Kho hiện còn những gì?'),
          ),
          ActionChip(
            label: const Text('Tạo phiếu xuất kho'),
            onPressed: () => onSuggestion('Tạo phiếu xuất kho'),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.onDraftChanged});

  final ChatMessage message;
  final ValueChanged<AiResult> onDraftChanged;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.result != null && !isUser)
              AiResultCard(result: message.result!, onChanged: onDraftChanged)
            else
              Text(message.content, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

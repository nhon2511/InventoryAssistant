import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_wms/core/di/ai_assistant_providers.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/order_draft.dart';
import 'package:smart_wms/features/ai_assistant/presentation/controllers/ai_chat_controller.dart';

class AiChatScreen extends HookConsumerWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(aiChatControllerProvider);
    final textController = useTextEditingController();
    final scrollController = useScrollController();
    final speechService = ref.watch(speechServiceProvider);
    final isListeningState = useState(false);

    useEffect(() {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      return null;
    }, [chatState.messages.length]);

    useEffect(() {
      if (chatState.pendingDraft != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showDraftPreviewSheet(context, ref, chatState.pendingDraft!);
        });
      }
      return null;
    }, [chatState.pendingDraft]);

    Future<void> toggleListening() async {
      if (isListeningState.value) {
        await speechService.stopListening();
        isListeningState.value = false;
      } else {
        final available = await speechService.initialize();
        if (!available) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể khởi động micro.')),
            );
          }
          return;
        }
        isListeningState.value = true;
        await speechService.startListening(
          onResult: (result) {
            textController.text = result.recognizedWords;
            if (result.finalResult) {
              isListeningState.value = false;
              if (textController.text.trim().isNotEmpty) {
                ref.read(aiChatControllerProvider.notifier).sendMessage(textController.text);
                textController.clear();
              }
            }
          },
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ lý AI Kho Hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => ref.read(aiChatControllerProvider.notifier).clearChat(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty
                ? const _EmptyChat()
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) => _ChatBubble(message: chatState.messages[index]),
                  ),
          ),
          if (chatState.isProcessing) const LinearProgressIndicator(),
          if (isListeningState.value)
            Container(
              color: Colors.red.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('Đang lắng nghe...'),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      await speechService.stopListening();
                      isListeningState.value = false;
                    },
                    child: const Text('Dừng'),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  onPressed: toggleListening,
                  icon: Icon(
                    isListeningState.value ? Icons.mic : Icons.mic_none,
                    color: isListeningState.value ? Colors.red : null,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: 'Hỏi tồn kho hoặc tạo phiếu...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (text) => _sendMessage(ref, textController),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: chatState.isProcessing ? null : () => _sendMessage(ref, textController),
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

  void _showDraftPreviewSheet(BuildContext context, WidgetRef ref, OrderDraft draft) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(draft.isInbound ? Icons.input : Icons.output),
                const SizedBox(width: 8),
                Text('Xác nhận ', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Vui lòng kiểm tra lại phiếu nháp trước khi lưu.'),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: draft.items.length,
                itemBuilder: (context, index) {
                  final item = draft.items[index];
                  return Card(
                    child: ListTile(
                      title: Text(item.productName),
                      subtitle: const Text('SKU: N/A'),
                      trailing: const Text('Số lượng'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    ref.read(aiChatControllerProvider.notifier).clearDraft();
                    Navigator.pop(context);
                  },
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(aiChatControllerProvider.notifier).clearDraft();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã lưu phiếu thành công!')),
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Xác nhận lưu'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Xin chào! Hãy hỏi tôi về tồn kho hoặc tạo phiếu nhé!', textAlign: TextAlign.center));
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message.content),
      ),
    );
  }
}

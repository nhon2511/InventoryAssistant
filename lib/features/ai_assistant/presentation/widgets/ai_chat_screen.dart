import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wms/core/preview/preview_mode.dart';
import 'package:smart_wms/core/services/voice_input_service.dart';
import 'package:smart_wms/core/widgets/confirm_dialog.dart';
import 'package:smart_wms/core/widgets/workspace_layout.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:smart_wms/features/ai_assistant/presentation/controllers/ai_chat_controller.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});
  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final text = TextEditingController();
  final scroll = ScrollController();
  final voice = VoiceInputService();
  String? voiceError;
  bool voiceBusy = false;
  @override
  void dispose() {
    text.dispose();
    scroll.dispose();
    unawaited(voice.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatControllerProvider);
    ref.listen(aiChatControllerProvider, (_, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && scroll.hasClients) {
          scroll.jumpTo(scroll.position.maxScrollExtent);
        }
      });
    });
    return Scaffold(
      body: SafeArea(
        child: WorkspaceContent(
          maxWidth: 960,
          child: Column(
            children: [
              Padding(
                padding: workspacePadding(context).copyWith(bottom: 0),
                child: WorkspaceHeader(
                  title: 'Trợ lý kho',
                  description:
                      'Hỏi về tồn kho và chuẩn bị phiếu nháp để kiểm tra.',
                  actions: [
                    TextButton.icon(
                      onPressed: state.isProcessing || state.messages.isEmpty
                          ? null
                          : () async {
                              if (await ConfirmDialog.show(
                                context,
                                title: 'Xóa cuộc trò chuyện?',
                                content:
                                    'Lịch sử hội thoại trong phiên sẽ bị xóa.',
                              )) {
                                if (mounted) {
                                  ref
                                      .read(aiChatControllerProvider.notifier)
                                      .clearChat();
                                }
                              }
                            },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Xóa cuộc trò chuyện'),
                    ),
                  ],
                ),
              ),
              if (ref.watch(frontendPreviewProvider))
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'AI MÔ PHỎNG · Gõ “tồn kho” hoặc “phiếu nhập nháp” / “phiếu xuất nháp”. Fixture luôn dùng 5 đôi găng tay tại A-01-01-01.',
                  ),
                ),
              Expanded(
                child: state.messages.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Hỏi tồn kho theo SKU hoặc yêu cầu phiếu nháp.\nMọi phiếu phải được bạn kiểm tra và xác nhận.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final message = state.messages[index];
                          final user = message.role == ChatRole.user;
                          return Align(
                            alignment: user
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 660),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: user
                                    ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                    : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SelectableText(message.content),
                            ),
                          );
                        },
                      ),
              ),
              if (state.isProcessing) const LinearProgressIndicator(),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(child: Text(state.error!)),
                      TextButton(
                        onPressed: state.isProcessing
                            ? null
                            : () => ref
                                  .read(aiChatControllerProvider.notifier)
                                  .sendMessage(state.lastFailedText!),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              if (state.draft != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 12,
                    children: [
                      FilledButton(
                        onPressed: () =>
                            context.go('/ai-draft', extra: state.draft),
                        child: const Text('Xem & sửa phiếu nháp'),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(aiChatControllerProvider.notifier)
                            .dismissDraft(),
                        child: const Text('Hủy bản nháp'),
                      ),
                    ],
                  ),
                ),
              if (voiceError != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(voiceError!),
                ),
              if (voice.listening)
                const Text(
                  'Đang nghe tiếng Việt · Bấm micro để dừng. Văn bản chưa được gửi.',
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: voice.supported
                          ? voice.listening
                                ? 'Dừng micro'
                                : 'Nhập giọng nói'
                          : 'Giọng nói chưa hỗ trợ trên nền tảng này',
                      onPressed:
                          voice.supported && !voiceBusy && !state.isProcessing
                          ? toggleVoice
                          : null,
                      icon: Icon(
                        voice.listening
                            ? Icons.stop_circle_outlined
                            : Icons.mic_none,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: text,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Yêu cầu về kho',
                        ),
                        onSubmitted: (_) => send(),
                      ),
                    ),
                    IconButton.filled(
                      tooltip: 'Gửi yêu cầu',
                      onPressed: state.isProcessing ? null : send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void send() {
    if (ref.read(aiChatControllerProvider).isProcessing ||
        text.text.trim().isEmpty) {
      return;
    }
    unawaited(voice.stop());
    ref.read(aiChatControllerProvider.notifier).sendMessage(text.text);
    text.clear();
  }

  Future<void> toggleVoice() async {
    if (voice.listening) {
      await voice.stop();
      if (mounted) setState(() {});
      return;
    }
    setState(() {
      voiceBusy = true;
      voiceError = null;
    });
    try {
      final ready = await voice.start(
        onText: (value) {
          if (mounted) {
            text.text = value;
            text.selection = TextSelection.collapsed(offset: value.length);
          }
        },
        onError: (error) {
          if (mounted) setState(() => voiceError = error);
        },
        onStatus: () {
          if (mounted) setState(() {});
        },
      );
      if (!ready && mounted) {
        setState(
          () => voiceError = 'Không mở được micro. Kiểm tra quyền, trình duyệt hoặc nhập văn bản.',
        );
      }
    } on Exception {
      if (mounted) {
        setState(
          () => voiceError = 'Nhập giọng nói chưa khả dụng trên thiết bị này.',
        );
      }
    } finally {
      if (mounted) setState(() => voiceBusy = false);
    }
  }
}

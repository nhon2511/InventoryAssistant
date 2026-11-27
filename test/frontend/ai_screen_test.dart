import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wms/core/di/ai_assistant_providers.dart';
import 'package:smart_wms/core/preview/preview_ai_repository.dart';
import 'package:smart_wms/core/preview/preview_repository.dart';
import 'package:smart_wms/core/services/speech_service.dart';
import 'package:smart_wms/features/ai_assistant/presentation/widgets/ai_chat_screen.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class _FakeSpeechService extends SpeechService {
  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> startListening({
    required ValueChanged<SpeechRecognitionResult> onResult,
    String localeId = 'vi-VN',
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    onResult(
      SpeechRecognitionResult([
        const SpeechRecognitionWords('hỏi tồn kho', null, 1),
      ], ResultType.finalResult.value),
    );
  }

  @override
  Future<void> cancelListening() async {}

  @override
  void dispose() {}
}

void main() {
  testWidgets('voice fills text and waits for explicit send', (tester) async {
    final speech = _FakeSpeechService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [speechServiceProvider.overrideWithValue(speech)],
        child: const MaterialApp(home: AiChatScreen()),
      ),
    );
    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'hỏi tồn kho',
    );
    expect(find.text('hỏi tồn kho'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('unverified AI gives honest error without Supabase call', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AiChatScreen())),
    );
    await tester.enterText(find.byType(TextField), 'Tồn kho còn bao nhiêu?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.textContaining('Trợ lý AI hiện chưa khả dụng'), findsOneWidget);
    expect(find.textContaining('Đã lưu phiếu thành công'), findsNothing);
  });

  testWidgets('AI draft suggestion opens form only after user action', (
    tester,
  ) async {
    final repository = PreviewRepository();
    addTearDown(repository.dispose);
    final router = GoRouter(
      initialLocation: '/ai-chat',
      routes: [
        GoRoute(path: '/ai-chat', builder: (_, _) => const AiChatScreen()),
        GoRoute(
          path: '/inbound/new',
          builder: (_, _) => const Scaffold(body: Text('Form phiếu nhập')),
        ),
        GoRoute(
          path: '/outbound/new',
          builder: (_, _) => const Scaffold(body: Text('Form phiếu xuất')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiAssistantRepositoryProvider.overrideWithValue(
            PreviewAiRepository(repository),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.enterText(find.byType(TextField), 'phiếu nhập nháp');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('Mở form để kiểm tra'), findsOneWidget);
    expect(repository.orders.length, 3);
    await tester.tap(find.text('Mở form để kiểm tra'));
    await tester.pumpAndSettle();
    expect(find.text('Form phiếu nhập'), findsOneWidget);
    expect(repository.orders.length, 3);
  });
}

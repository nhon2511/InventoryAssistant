import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/di/ai_assistant_providers.dart';
import 'package:smart_wms/core/di/inventory_providers.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/preview/preview_ai_repository.dart';
import 'package:smart_wms/core/preview/preview_repository.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/parsed_intent.dart';
import 'package:smart_wms/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import 'package:smart_wms/features/ai_assistant/domain/usecases/resolve_order_draft_usecase.dart';
import 'package:smart_wms/features/ai_assistant/presentation/controllers/ai_chat_controller.dart';

class _DelayedAi implements AiAssistantRepository {
  final result = Completer<Either<Failure, ParsedIntent>>();
  int calls = 0;
  @override
  FutureEither<ParsedIntent> parseIntent(String text) {
    calls++;
    return result.future;
  }

  @override
  FutureEither<String> queryStock(Map<String, String> entities) async =>
      const Right('fixture');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'AI draft requires explicit type, quantity and unique product/location',
    () async {
      final repository = PreviewRepository();
      addTearDown(repository.dispose);
      final resolver = ResolveOrderDraftUseCase(repository);
      expect(
        (await resolver(
          const ParsedIntent(intent: 'create_order', confidence: 1),
        )).isLeft(),
        isTrue,
      );
      expect(
        (await resolver(
          const ParsedIntent(
            intent: 'create_inbound_draft',
            confidence: 1,
            entities: {'quantity': '0'},
          ),
        )).isLeft(),
        isTrue,
      );
      expect(
        (await resolver(
          const ParsedIntent(
            intent: 'create_inbound_draft',
            confidence: 1,
            entities: {
              'quantity': '3',
              'product_name': 'unknown',
              'location': 'A-01-01-01',
            },
          ),
        )).isLeft(),
        isTrue,
      );
      final draft = await resolver(
        const ParsedIntent(
          intent: 'create_outbound_draft',
          confidence: 1,
          entities: {
            'quantity': '3',
            'sku': 'BH-001',
            'location': 'A-01-01-01',
          },
        ),
      );
      expect(draft.isRight(), isTrue);
      expect(repository.orders.length, 3);
    },
  );
  test(
    'chat locks repeat requests and exposes localized retry state',
    () async {
      final ai = _DelayedAi();
      final container = ProviderContainer(
        overrides: [aiAssistantRepositoryProvider.overrideWithValue(ai)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        aiChatControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      final controller = container.read(aiChatControllerProvider.notifier);
      final request = controller.sendMessage('tồn kho');
      expect(container.read(aiChatControllerProvider).isProcessing, isTrue);
      await controller.sendMessage('lặp');
      expect(ai.calls, 1);
      ai.result.complete(
        const Left(AiFailure(message: 'internal transport details')),
      );
      await request;
      final state = container.read(aiChatControllerProvider);
      expect(state.isProcessing, isFalse);
      expect(state.error, isNot(contains('transport')));
      expect(state.lastFailedText, 'tồn kho');
    },
  );
  test(
    'preview chat creates editable preview only, dismiss never saves',
    () async {
      final repository = PreviewRepository();
      addTearDown(repository.dispose);
      final container = ProviderContainer(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(repository),
          aiAssistantRepositoryProvider.overrideWithValue(
            PreviewAiRepository(repository),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        aiChatControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      final controller = container.read(aiChatControllerProvider.notifier);
      await controller.sendMessage('phiếu nhập nháp');
      expect(container.read(aiChatControllerProvider).draft, isNotNull);
      expect(repository.orders.length, 3);
      expect(repository.orders.length, 3);
    },
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/ai_result.dart';

void main() {
  test('draft fields survive JSON round trip and review', () {
    const draft = AiResult(type: AiResultType.draftOutbound, text: 'Bản nháp',
      productName: 'Mì Hảo Hảo', quantity: 5, lotCode: 'LOT-1');
    final restored = AiResult.fromJson(draft.toJson());
    expect(restored.productName, 'Mì Hảo Hảo');
    expect(restored.quantity, 5);
    expect(restored.copyWith(draftState: AiDraftState.reviewed).draftState,
      AiDraftState.reviewed);
  });
}

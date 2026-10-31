import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/order_draft.dart';
import 'package:smart_wms/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';

/// Creates a draft order from parsed AI intent entities.
///
/// The draft is returned for human review before being persisted.
class CreateDraftOrderUseCase
    extends UseCase<OrderDraft, Map<String, String>> {
  const CreateDraftOrderUseCase(this._repository);

  final AiAssistantRepository _repository;

  @override
  FutureEither<OrderDraft> call(Map<String, String> entities) {
    return _repository.createDraftOrder(entities);
  }
}

import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';

/// Queries stock information based on parsed intent entities.
class QueryStockUseCase extends UseCase<String, Map<String, String>> {
  const QueryStockUseCase(this._repository);

  final AiAssistantRepository _repository;

  @override
  FutureEither<String> call(Map<String, String> entities) {
    return _repository.queryStock(entities);
  }
}

import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/outbound/domain/repositories/outbound_repository.dart';

/// Calls the PostgreSQL stored procedure to confirm outbound and deduct stock.
class ConfirmOutboundOrderUseCase extends UseCase<void, String> {
  const ConfirmOutboundOrderUseCase(this._repository);

  final OutboundRepository _repository;

  @override
  FutureVoid call(String orderId) {
    return _repository.confirmOutboundOrder(orderId);
  }
}

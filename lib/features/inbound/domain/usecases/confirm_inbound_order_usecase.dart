import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inbound/domain/repositories/inbound_repository.dart';

/// Confirms an inbound order, updating its status and adding stock.
class ConfirmInboundOrderUseCase extends UseCase<WarehouseOrder, String> {
  const ConfirmInboundOrderUseCase(this._repository);

  final InboundRepository _repository;

  @override
  FutureEither<WarehouseOrder> call(String orderId) {
    return _repository.confirmInboundOrder(orderId);
  }
}

import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/outbound/domain/repositories/outbound_repository.dart';

/// Retrieves all outbound warehouse orders.
class GetOutboundOrdersUseCase extends UseCase<List<WarehouseOrder>, NoParams> {
  const GetOutboundOrdersUseCase(this._repository);

  final OutboundRepository _repository;

  @override
  FutureEither<List<WarehouseOrder>> call(NoParams params) {
    return _repository.getOutboundOrders();
  }
}

import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inbound/domain/repositories/inbound_repository.dart';

/// Retrieves all inbound warehouse orders.
class GetInboundOrdersUseCase extends UseCase<List<WarehouseOrder>, NoParams> {
  const GetInboundOrdersUseCase(this._repository);

  final InboundRepository _repository;

  @override
  FutureEither<List<WarehouseOrder>> call(NoParams params) {
    return _repository.getInboundOrders();
  }
}

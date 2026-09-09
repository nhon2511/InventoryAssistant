import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/outbound/domain/repositories/outbound_repository.dart';

/// Creates a new outbound order in DRAFT status.
class CreateOutboundOrderUseCase extends UseCase<WarehouseOrder, String?> {
  const CreateOutboundOrderUseCase(this._repository);

  final OutboundRepository _repository;

  @override
  FutureEither<WarehouseOrder> call(String? note) {
    return _repository.createOutboundOrder(note: note);
  }
}

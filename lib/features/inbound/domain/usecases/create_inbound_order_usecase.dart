import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inbound/domain/repositories/inbound_repository.dart';

/// Creates a new inbound order in DRAFT status.
class CreateInboundOrderUseCase extends UseCase<WarehouseOrder, String?> {
  const CreateInboundOrderUseCase(this._repository);

  final InboundRepository _repository;

  @override
  FutureEither<WarehouseOrder> call(String? note) {
    return _repository.createInboundOrder(note: note);
  }
}

import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inbound/domain/repositories/inbound_repository.dart';

/// Adds a scanned item to an existing inbound order.
class AddScannedItemUseCase extends UseCase<WarehouseOrderItem, AddScannedItemParams> {
  const AddScannedItemUseCase(this._repository);

  final InboundRepository _repository;

  @override
  FutureEither<WarehouseOrderItem> call(AddScannedItemParams params) {
    return _repository.addScannedItem(
      orderId: params.orderId,
      productId: params.productId,
      quantity: params.quantity,
      locationId: params.locationId,
      lotNumber: params.lotNumber,
      expiryDate: params.expiryDate,
    );
  }
}

class AddScannedItemParams {
  const AddScannedItemParams({
    required this.orderId,
    required this.productId,
    required this.quantity,
    this.locationId,
    this.lotNumber,
    this.expiryDate,
  });

  final String orderId;
  final String productId;
  final int quantity;
  final String? locationId;
  final String? lotNumber;
  final DateTime? expiryDate;
}

import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/auth/domain/entities/profile.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:smart_wms/features/orders/domain/usecases/order_workspace_usecase.dart';
import 'package:smart_wms/features/reports/domain/entities/warehouse_report.dart';

class LoadWarehouseReportUseCase {
  const LoadWarehouseReportUseCase(this.inventory, this.orders);
  final InventoryRepository inventory;
  final ReadOrdersUseCase orders;
  FutureEither<WarehouseReport> call(Profile profile) async {
    final products = await inventory.getAllProducts();
    final locations = await inventory.getAllLocations();
    final stock = await inventory.getAllInventoryItems();
    final inbound = await orders.list(OrderType.inbound, profile);
    final outbound = await orders.list(OrderType.outbound, profile);
    return products.flatMap(
      (ps) => locations.flatMap(
        (ls) => stock.flatMap(
          (ss) => inbound.flatMap(
            (ins) => outbound.map(
              (outs) => WarehouseReport(
                products: ps,
                locations: ls,
                stock: ss,
                orders: [...ins, ...outs],
                loadedAt: DateTime.now(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

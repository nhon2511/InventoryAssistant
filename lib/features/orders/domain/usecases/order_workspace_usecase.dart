import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/auth/domain/entities/profile.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inbound/domain/repositories/inbound_repository.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_wms/features/orders/domain/repositories/order_workflow_repository.dart';
import 'package:smart_wms/features/outbound/domain/repositories/outbound_repository.dart';

class ReadOrdersUseCase {
  const ReadOrdersUseCase(this.inbound, this.outbound);
  final InboundRepository inbound;
  final OutboundRepository outbound;
  FutureEither<List<WarehouseOrder>> list(
    OrderType type,
    Profile profile,
  ) async {
    final result = type == OrderType.inbound
        ? await inbound.getInboundOrders()
        : await outbound.getOutboundOrders();
    return result.map(
      (orders) => orders
          .where(
            (o) => profile.role.isManagerOrAbove || o.createdBy == profile.id,
          )
          .toList(),
    );
  }

  FutureEither<WarehouseOrder> detail(
    OrderType type,
    String id,
    Profile profile,
  ) async {
    final result = type == OrderType.inbound
        ? await inbound.getInboundOrderById(id)
        : await outbound.getOutboundOrderById(id);
    return result.flatMap(
      (order) => profile.role.isManagerOrAbove || order.createdBy == profile.id
          ? Right(order)
          : const Left(
              ServerFailure(message: 'Bạn không có quyền xem phiếu này.'),
            ),
    );
  }
}

class OrderWorkspaceUseCase {
  const OrderWorkspaceUseCase(this.repository);
  final OrderWorkflowRepository repository;
  static String? validate(
    OrderType type,
    List<WarehouseOrderItem> items,
    List<InventoryItem>? stock,
  ) {
    if (items.isEmpty) return 'Thêm ít nhất một dòng hàng.';
    final requested = <String, int>{};
    for (final item in items) {
      if (item.productId.trim().isEmpty ||
          (item.locationId?.trim().isEmpty ?? true) ||
          item.expectedQuantity <= 0) {
        return 'Chọn sản phẩm, vị trí và số lượng nguyên lớn hơn 0.';
      }
      final key = '${item.productId}|${item.locationId}';
      requested[key] = (requested[key] ?? 0) + item.expectedQuantity;
    }
    if (type == OrderType.outbound && stock != null) {
      for (final entry in requested.entries) {
        final available = stock
            .where((s) => '${s.productId}|${s.locationId}' == entry.key)
            .fold<int>(0, (sum, s) => sum + s.quantityAvailable);
        if (entry.value > available) {
          return 'Số lượng xuất vượt tồn khả dụng tại vị trí đã chọn (còn $available).';
        }
      }
    }
    return null;
  }

  FutureEither<WarehouseOrder> save({
    required OrderType type,
    required Profile profile,
    required List<WarehouseOrderItem> items,
    required String requestId,
    List<InventoryItem>? stock,
    String? note,
  }) async {
    final error = validate(type, items, stock);
    if (error != null) return Left(ServerFailure(message: error));
    return repository.saveDraft(
      type: type,
      createdBy: profile.id,
      items: items,
      requestId: requestId,
      note: note,
    );
  }

  FutureEither<WarehouseOrder> review(
    WarehouseOrder order,
    Profile profile, {
    required bool approve,
  }) async {
    if (!profile.role.isManagerOrAbove || order.status != OrderStatus.draft) {
      return const Left(
        ServerFailure(
          message: 'Chỉ Admin/Manager được duyệt hoặc từ chối phiếu nháp.',
        ),
      );
    }
    return repository.review(
      orderId: order.id,
      expectedStatus: order.status,
      approve: approve,
      reviewerId: profile.id,
    );
  }
}

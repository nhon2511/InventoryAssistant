import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';

/// Pure domain entity representing a warehouse order (Inbound / Outbound).
class WarehouseOrder {
  const WarehouseOrder({
    required this.id,
    required this.orderCode,
    required this.type,
    required this.status,
    this.createdBy,
    this.approvedBy,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  final String id;
  final String orderCode;
  final OrderType type;
  final OrderStatus status;
  final String? createdBy;
  final String? approvedBy;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<WarehouseOrderItem> items;
}

/// A single line item within a [WarehouseOrder].
class WarehouseOrderItem {
  const WarehouseOrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.expectedQuantity,
    required this.actualQuantity,
    this.locationId,
    this.lotNumber,
    this.expiryDate,
    this.productName,
  });

  final String id;
  final String orderId;
  final String productId;
  final String? locationId;
  final String? lotNumber;
  final DateTime? expiryDate;
  final int expectedQuantity;
  final int actualQuantity;

  /// Denormalized for display convenience.
  final String? productName;
}

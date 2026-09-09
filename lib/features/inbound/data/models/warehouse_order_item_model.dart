import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';

class WarehouseOrderItemModel {
  const WarehouseOrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.expectedQuantity,
    required this.actualQuantity,
    this.locationId,
    this.lotNumber,
    this.expiryDate,
  });

  final String id;
  final String orderId;
  final String productId;
  final String? locationId;
  final String? lotNumber;
  final String? expiryDate;
  final int expectedQuantity;
  final int actualQuantity;

  factory WarehouseOrderItemModel.fromJson(Map<String, dynamic> json) {
    return WarehouseOrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      locationId: json['location_id'] as String?,
      lotNumber: json['lot_number'] as String?,
      expiryDate: json['expiry_date'] as String?,
      expectedQuantity: json['expected_quantity'] as int? ?? 0,
      actualQuantity: json['actual_quantity'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'location_id': locationId,
      'lot_number': lotNumber,
      'expiry_date': expiryDate,
      'expected_quantity': expectedQuantity,
      'actual_quantity': actualQuantity,
    };
  }

  WarehouseOrderItem toEntity({String? productName}) {
    return WarehouseOrderItem(
      id: id,
      orderId: orderId,
      productId: productId,
      locationId: locationId,
      lotNumber: lotNumber,
      expiryDate: expiryDate != null ? DateTime.tryParse(expiryDate!) : null,
      expectedQuantity: expectedQuantity,
      actualQuantity: actualQuantity,
      productName: productName,
    );
  }
}


import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';

class WarehouseOrderModel {
  const WarehouseOrderModel({
    required this.id,
    required this.orderCode,
    required this.type,
    required this.status,
    this.createdBy,
    this.approvedBy,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String orderCode;
  final String type;
  final String status;
  final String? createdBy;
  final String? approvedBy;
  final String? note;
  final String? createdAt;
  final String? updatedAt;

  factory WarehouseOrderModel.fromJson(Map<String, dynamic> json) {
    return WarehouseOrderModel(
      id: json['id'] as String,
      orderCode: json['order_code'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      createdBy: json['created_by'] as String?,
      approvedBy: json['approved_by'] as String?,
      note: json['note'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_code': orderCode,
      'type': type,
      'status': status,
      'created_by': createdBy,
      'approved_by': approvedBy,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  WarehouseOrder toEntity({List<WarehouseOrderItem> items = const []}) {
    return WarehouseOrder(
      id: id,
      orderCode: orderCode,
      type: OrderType.fromString(type),
      status: OrderStatus.fromString(status),
      createdBy: createdBy,
      approvedBy: approvedBy,
      note: note,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
      updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt!) : null,
      items: items,
    );
  }
}


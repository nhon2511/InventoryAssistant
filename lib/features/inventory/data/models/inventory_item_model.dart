import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';

class InventoryItemModel {
  const InventoryItemModel({
    required this.id,
    required this.productId,
    required this.locationId,
    required this.quantityOnHand,
    required this.quantityReserved,
    this.lotNumber,
    this.expiryDate,
    this.updatedAt,
  });

  final String id;
  final String productId;
  final String locationId;
  final String? lotNumber;
  final String? expiryDate;
  final int quantityOnHand;
  final int quantityReserved;
  final String? updatedAt;

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      locationId: json['location_id'] as String,
      lotNumber: json['lot_number'] as String?,
      expiryDate: json['expiry_date'] as String?,
      quantityOnHand: json['quantity_on_hand'] as int? ?? 0,
      quantityReserved: json['quantity_reserved'] as int? ?? 0,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'location_id': locationId,
      'lot_number': lotNumber,
      'expiry_date': expiryDate,
      'quantity_on_hand': quantityOnHand,
      'quantity_reserved': quantityReserved,
      'updated_at': updatedAt,
    };
  }

  InventoryItem toEntity({String? productName, String? locationLabel}) {
    return InventoryItem(
      id: id,
      productId: productId,
      locationId: locationId,
      lotNumber: lotNumber,
      expiryDate: expiryDate != null ? DateTime.tryParse(expiryDate!) : null,
      quantityOnHand: quantityOnHand,
      quantityReserved: quantityReserved,
      updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt!) : null,
      productName: productName,
      locationLabel: locationLabel,
    );
  }
}


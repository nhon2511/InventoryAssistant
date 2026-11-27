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

  factory InventoryItemModel.fromNestJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        json['productId'] is! String ||
        json['locationId'] is! String ||
        json['quantityOnHand'] is! int ||
        json['quantityReserved'] is! int ||
        (json['lotNumber'] != null && json['lotNumber'] is! String) ||
        (json['expiryDate'] != null && json['expiryDate'] is! String) ||
        (json['updatedAt'] != null && json['updatedAt'] is! String)) {
      throw const FormatException('Invalid stock item');
    }
    return InventoryItemModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      locationId: json['locationId'] as String,
      quantityOnHand: json['quantityOnHand'] as int,
      quantityReserved: json['quantityReserved'] as int,
      lotNumber: json['lotNumber'] as String?,
      expiryDate: json['expiryDate'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  final String id;
  final String productId;
  final String locationId;
  final String? lotNumber;
  final String? expiryDate;
  final int quantityOnHand;
  final int quantityReserved;
  final String? updatedAt;

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

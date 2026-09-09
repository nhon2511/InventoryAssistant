import 'package:smart_wms/features/inventory/domain/entities/product.dart';

class ProductModel {
  const ProductModel({
    required this.id,
    required this.sku,
    required this.barcode,
    required this.name,
    required this.unit,
    required this.minSafetyStock,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String sku;
  final String barcode;
  final String name;
  final String? description;
  final String unit;
  final int minSafetyStock;
  final String? createdAt;
  final String? updatedAt;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      unit: json['unit'] as String? ?? 'Pcs',
      minSafetyStock: json['min_safety_stock'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'barcode': barcode,
      'name': name,
      'description': description,
      'unit': unit,
      'min_safety_stock': minSafetyStock,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Product toEntity() => Product(
        id: id,
        sku: sku,
        barcode: barcode,
        name: name,
        description: description,
        unit: unit,
        minSafetyStock: minSafetyStock,
        createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
        updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt!) : null,
      );
}


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

  factory ProductModel.fromNestJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        json['sku'] is! String ||
        json['barcode'] is! String ||
        json['name'] is! String ||
        json['unit'] is! String ||
        json['minSafetyStock'] is! int ||
        (json['description'] != null && json['description'] is! String) ||
        (json['createdAt'] != null && json['createdAt'] is! String) ||
        (json['updatedAt'] != null && json['updatedAt'] is! String)) {
      throw const FormatException('Invalid product');
    }
    return ProductModel(
      id: json['id'] as String,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      minSafetyStock: json['minSafetyStock'] as int,
      description: json['description'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  final String id;
  final String sku;
  final String barcode;
  final String name;
  final String? description;
  final String unit;
  final int minSafetyStock;
  final String? createdAt;
  final String? updatedAt;

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

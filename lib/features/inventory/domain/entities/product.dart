/// Pure domain entity representing a product / SKU.
///
/// Maps to the `products` table in Supabase.
class Product {
  const Product({
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
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

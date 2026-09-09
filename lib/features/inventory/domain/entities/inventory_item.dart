/// Pure domain entity representing stock balance at a specific location.
///
/// Maps to the `inventory_items` table in Supabase.
class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.productId,
    required this.locationId,
    required this.quantityOnHand,
    required this.quantityReserved,
    this.lotNumber,
    this.expiryDate,
    this.updatedAt,
    this.productName,
    this.locationLabel,
  });

  final String id;
  final String productId;
  final String locationId;
  final String? lotNumber;
  final DateTime? expiryDate;
  final int quantityOnHand;
  final int quantityReserved;
  final DateTime? updatedAt;

  /// Denormalized product name (for display convenience).
  final String? productName;

  /// Denormalized location label (for display convenience).
  final String? locationLabel;

  /// Available quantity = on hand - reserved.
  int get quantityAvailable => quantityOnHand - quantityReserved;
}

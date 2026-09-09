/// Represents a single item in a pick list for outbound verification.
class PickListItem {
  const PickListItem({
    required this.productId,
    required this.productName,
    required this.barcode,
    required this.locationLabel,
    required this.expectedQuantity,
    required this.pickedQuantity,
    this.lotNumber,
  });

  final String productId;
  final String productName;
  final String barcode;
  final String locationLabel;
  final String? lotNumber;
  final int expectedQuantity;
  final int pickedQuantity;

  /// Whether this item has been fully picked.
  bool get isComplete => pickedQuantity >= expectedQuantity;

  /// Remaining quantity to pick.
  int get remaining => expectedQuantity - pickedQuantity;
}

/// Stock safety status for report display.
///
/// Derived by comparing current quantity on hand against
/// the product's [minSafetyStock] threshold.
enum StockStatus {
  inStock('Đủ hàng'),
  lowStock('Sắp hết'),
  outOfStock('Hết hàng');

  const StockStatus(this.label);

  /// Vietnamese display label.
  final String label;

  /// Derives status from current quantity and safety threshold.
  static StockStatus fromQuantity({
    required int quantityOnHand,
    required int minSafetyStock,
  }) {
    if (quantityOnHand <= 0) return StockStatus.outOfStock;
    if (quantityOnHand <= minSafetyStock) return StockStatus.lowStock;
    return StockStatus.inStock;
  }
}

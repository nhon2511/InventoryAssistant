/// Represents a draft order created by the AI assistant.
///
/// This is shown in the Human-in-the-loop Preview Sheet for the user
/// to review and confirm before persisting to the database.
class OrderDraft {
  const OrderDraft({
    required this.orderType,
    required this.items,
    this.note,
  });

  /// The type of order: 'inbound' or 'outbound'.
  final String orderType;

  /// The list of draft line items extracted by AI.
  final List<OrderDraftItem> items;

  /// Optional note/reason for the order.
  final String? note;

  /// Whether this is an inbound order.
  bool get isInbound => orderType == 'inbound';

  /// Whether this is an outbound order.
  bool get isOutbound => orderType == 'outbound';

  /// Human-readable label for the order type.
  String get orderTypeLabel => isInbound ? 'Phiếu nhập kho' : 'Phiếu xuất kho';

  OrderDraft copyWith({
    String? orderType,
    List<OrderDraftItem>? items,
    String? note,
  }) {
    return OrderDraft(
      orderType: orderType ?? this.orderType,
      items: items ?? this.items,
      note: note ?? this.note,
    );
  }
}

/// A single line item within an [OrderDraft].
class OrderDraftItem {
  const OrderDraftItem({
    required this.productName,
    required this.quantity,
    this.sku,
    this.locationLabel,
    this.lotNumber,
  });

  /// Product name as extracted by AI.
  final String productName;

  /// Quantity as extracted by AI.
  final int quantity;

  /// Optional SKU code.
  final String? sku;

  /// Optional location label (e.g., 'A-01-01').
  final String? locationLabel;

  /// Optional lot number.
  final String? lotNumber;

  OrderDraftItem copyWith({
    String? productName,
    int? quantity,
    String? sku,
    String? locationLabel,
    String? lotNumber,
  }) {
    return OrderDraftItem(
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      sku: sku ?? this.sku,
      locationLabel: locationLabel ?? this.locationLabel,
      lotNumber: lotNumber ?? this.lotNumber,
    );
  }
}

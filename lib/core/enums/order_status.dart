/// Maps to PostgreSQL ENUM `order_status`
/// ('DRAFT', 'CONFIRMED', 'PROCESSING', 'COMPLETED', 'CANCELLED').
enum OrderStatus {
  draft('DRAFT'),
  confirmed('CONFIRMED'),
  processing('PROCESSING'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  const OrderStatus(this.dbValue);

  /// The value stored in PostgreSQL.
  final String dbValue;

  /// Parses a database string into an [OrderStatus].
  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.dbValue == value.toUpperCase(),
      orElse: () => throw ArgumentError('Unknown OrderStatus: $value'),
    );
  }

  /// Whether the order can still be modified.
  bool get isEditable => this == OrderStatus.draft || this == OrderStatus.confirmed;

  /// Whether the order has reached a terminal state.
  bool get isTerminal => this == OrderStatus.completed || this == OrderStatus.cancelled;
}

/// Maps to PostgreSQL ENUM `order_type` ('INBOUND', 'OUTBOUND').
enum OrderType {
  inbound('INBOUND'),
  outbound('OUTBOUND');

  const OrderType(this.dbValue);

  /// The value stored in PostgreSQL.
  final String dbValue;

  /// Parses a database string into an [OrderType].
  static OrderType fromString(String value) {
    return OrderType.values.firstWhere(
      (e) => e.dbValue == value.toUpperCase(),
      orElse: () => throw ArgumentError('Unknown OrderType: $value'),
    );
  }
}

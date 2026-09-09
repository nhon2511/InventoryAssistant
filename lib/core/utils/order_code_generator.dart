import 'package:intl/intl.dart';
import 'package:smart_wms/core/constants/app_constants.dart';
import 'package:smart_wms/core/enums/order_type.dart';

/// Generates order codes following the pattern:
/// - Inbound: `INB-YYYYMMDD-NNN`
/// - Outbound: `OUT-YYYYMMDD-NNN`
class OrderCodeGenerator {
  const OrderCodeGenerator._();

  static final _dateFormat = DateFormat('yyyyMMdd');

  /// Generates an order code.
  ///
  /// [type] determines the prefix (INB or OUT).
  /// [sequenceNumber] is the daily sequence (1-based, zero-padded to 3 digits).
  ///
  /// Example: `OrderCodeGenerator.generate(OrderType.inbound, 1)`
  /// returns `'INB-20260909-001'`.
  static String generate(OrderType type, int sequenceNumber) {
    final prefix = switch (type) {
      OrderType.inbound => AppConstants.inboundPrefix,
      OrderType.outbound => AppConstants.outboundPrefix,
    };
    final dateStr = _dateFormat.format(DateTime.now());
    final seqStr = sequenceNumber.toString().padLeft(3, '0');
    return '$prefix-$dateStr-$seqStr';
  }
}

/// Pure domain entity representing a warehouse location (Zone-Aisle-Rack-Bin).
///
/// Maps to the `locations` table in Supabase.
class Location {
  const Location({
    required this.id,
    required this.zoneCode,
    required this.aisleCode,
    required this.rackCode,
    required this.binCode,
    required this.locationBarcode,
    this.maxCapacityKg,
    this.createdAt,
  });

  final String id;
  final String zoneCode;
  final String aisleCode;
  final String rackCode;
  final String binCode;
  final String locationBarcode;
  final double? maxCapacityKg;
  final DateTime? createdAt;

  /// Returns a human-readable location label.
  String get displayLabel => '$zoneCode-$aisleCode-$rackCode-$binCode';
}

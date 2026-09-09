import 'package:smart_wms/features/inventory/domain/entities/location.dart';

class LocationModel {
  const LocationModel({
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
  final String? createdAt;

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String,
      zoneCode: json['zone_code'] as String,
      aisleCode: json['aisle_code'] as String,
      rackCode: json['rack_code'] as String,
      binCode: json['bin_code'] as String,
      locationBarcode: json['location_barcode'] as String,
      maxCapacityKg: (json['max_capacity_kg'] as num?)?.toDouble(),
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'zone_code': zoneCode,
      'aisle_code': aisleCode,
      'rack_code': rackCode,
      'bin_code': binCode,
      'location_barcode': locationBarcode,
      'max_capacity_kg': maxCapacityKg,
      'created_at': createdAt,
    };
  }

  Location toEntity() => Location(
        id: id,
        zoneCode: zoneCode,
        aisleCode: aisleCode,
        rackCode: rackCode,
        binCode: binCode,
        locationBarcode: locationBarcode,
        maxCapacityKg: maxCapacityKg,
        createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
      );
}


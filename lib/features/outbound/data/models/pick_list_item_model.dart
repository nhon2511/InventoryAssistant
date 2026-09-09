import 'package:smart_wms/features/outbound/domain/entities/pick_list_item.dart';

class PickListItemModel {
  const PickListItemModel({
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

  factory PickListItemModel.fromJson(Map<String, dynamic> json) {
    return PickListItemModel(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      locationLabel: json['location_label'] as String? ?? '',
      lotNumber: json['lot_number'] as String?,
      expectedQuantity: json['expected_quantity'] as int? ?? 0,
      pickedQuantity: json['picked_quantity'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'barcode': barcode,
      'location_label': locationLabel,
      'lot_number': lotNumber,
      'expected_quantity': expectedQuantity,
      'picked_quantity': pickedQuantity,
    };
  }

  PickListItem toEntity() => PickListItem(
        productId: productId,
        productName: productName,
        barcode: barcode,
        locationLabel: locationLabel,
        lotNumber: lotNumber,
        expectedQuantity: expectedQuantity,
        pickedQuantity: pickedQuantity,
      );
}


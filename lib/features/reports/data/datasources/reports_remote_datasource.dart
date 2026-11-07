import 'package:smart_wms/core/constants/app_constants.dart';
import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:smart_wms/features/reports/data/models/report_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for report queries via Supabase.
// This interface is intentional: it keeps Supabase details behind a data
// boundary and makes the datasource replaceable in tests.
// ignore: one_member_abstracts
abstract class ReportsRemoteDataSource {
  /// Fetches all products joined with their aggregated inventory data.
  Future<List<ReportItemModel>> getReportItems();
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  const ReportsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ReportItemModel>> getReportItems() async {
    try {
      final products = await _client
          .from(AppConstants.productsTable)
          .select()
          .order('name');

      final inventoryItems = await _client
          .from(AppConstants.inventoryItemsTable)
          .select();

      final locations = await _client
          .from(AppConstants.locationsTable)
          .select();

      final locationMap = <String, String>{};
      for (final loc in locations) {
        final id = loc['id'] as String;
        final zone = loc['zone_code'] as String? ?? '';
        final aisle = loc['aisle_code'] as String? ?? '';
        final rack = loc['rack_code'] as String? ?? '';
        final bin = loc['bin_code'] as String? ?? '';
        locationMap[id] = '$zone-$aisle-$rack-$bin';
      }

      final stockMap = <String, _AggregatedStock>{};
      for (final inv in inventoryItems) {
        final productId = inv['product_id'] as String;
        final onHand = inv['quantity_on_hand'] as int? ?? 0;
        final reserved = inv['quantity_reserved'] as int? ?? 0;
        final locationId = inv['location_id'] as String;
        final label = locationMap[locationId] ?? locationId;

        final existing = stockMap[productId];
        if (existing != null) {
          existing
            ..totalOnHand += onHand
            ..totalReserved += reserved;
          if (!existing.locations.contains(label)) {
            existing.locations.add(label);
          }
        } else {
          stockMap[productId] = _AggregatedStock(
            totalOnHand: onHand,
            totalReserved: reserved,
            locations: [label],
          );
        }
      }

      return products.map((p) {
        final productId = p['id'] as String;
        final stock = stockMap[productId];

        return ReportItemModel(
          productId: productId,
          sku: p['sku'] as String? ?? '',
          productName: p['name'] as String? ?? '',
          category: p['unit'] as String? ?? 'N/A',
          totalOnHand: stock?.totalOnHand ?? 0,
          totalReserved: stock?.totalReserved ?? 0,
          minSafetyStock: p['min_safety_stock'] as int? ?? 0,
          locationLabel: stock?.locations.join(', ') ?? 'N/A',
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    }
  }
}

class _AggregatedStock {
  _AggregatedStock({
    required this.totalOnHand,
    required this.totalReserved,
    required this.locations,
  });

  int totalOnHand;
  int totalReserved;
  List<String> locations;
}

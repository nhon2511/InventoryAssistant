import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_wms/features/inventory/domain/entities/location.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';

/// Abstract repository contract for inventory operations.
abstract class InventoryRepository {
  // ── Products ──────────────────────────────────────────────────────
  FutureEither<List<Product>> getAllProducts();
  FutureEither<Product> getProductByBarcode(String barcode);
  FutureEither<Product> getProductById(String id);

  // ── Locations ─────────────────────────────────────────────────────
  FutureEither<List<Location>> getAllLocations();
  FutureEither<Location> getLocationByBarcode(String barcode);

  // ── Inventory Items ───────────────────────────────────────────────
  FutureEither<List<InventoryItem>> getStockByProduct(String productId);
  FutureEither<List<InventoryItem>> getAllInventoryItems();

  // ── Realtime ──────────────────────────────────────────────────────
  Stream<List<InventoryItem>> subscribeInventoryRealtime();
}

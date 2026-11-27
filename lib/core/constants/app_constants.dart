/// Application-wide constants.
///
/// Centralizes Supabase table names, RPC function names, and other
/// configuration values so they can be changed in one place.
abstract final class AppConstants {
  // ── Supabase Table Names ──────────────────────────────────────────
  static const String profilesTable = 'profiles';
  static const String productsTable = 'products';
  static const String locationsTable = 'locations';
  static const String inventoryItemsTable = 'inventory_items';
  static const String warehouseOrdersTable = 'warehouse_orders';
  static const String warehouseOrderItemsTable = 'warehouse_order_items';

  // ── Supabase RPC Function Names ───────────────────────────────────
  static const String confirmOutboundOrderRpc = 'confirm_outbound_order';

  // ── Supabase Storage Buckets ──────────────────────────────────────
  static const String productImagesBucket = 'product-images';

  // ── Supabase Edge Function Slugs ──────────────────────────────────
  static const String parseIntentFunction = 'parse-intent';
  static const String queryStockFunction = 'query-stock';
  static const String createDraftOrderFunction = 'create-draft-order';

  // ── NestJS Backend Base URL ───────────────────────────────────────
  /// Change to your server IP/domain in production.
  static const String nestJsBaseUrl = 'http://10.0.2.2:3000/api/v1';
  static const String nestJsPath = '/ai';

  // ── Order Code Prefixes ───────────────────────────────────────────
  static const String inboundPrefix = 'INB';
  static const String outboundPrefix = 'OUT';

  // ── Timeouts & Limits ─────────────────────────────────────────────
  static const Duration requestTimeout = Duration(seconds: 15);
  static const int maxBatchScanItems = 100;
  static const double minConfidenceScore = 0.7;

  // ── Safety Stock Badge Thresholds ─────────────────────────────────
  static const int criticalStockThreshold = 5;
}

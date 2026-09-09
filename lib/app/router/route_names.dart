/// Centralized route name constants used by [GoRouter].
///
/// Using constants prevents typos and makes refactoring easier.
abstract final class RouteNames {
  // ── Auth ──────────────────────────────────────────────────────────
  static const String login = 'login';
  static const String register = 'register';

  // ── Main Shell ────────────────────────────────────────────────────
  static const String home = 'home';

  // ── Inventory ─────────────────────────────────────────────────────
  static const String productList = 'product-list';
  static const String productDetail = 'product-detail';
  static const String locationList = 'location-list';
  static const String stockOverview = 'stock-overview';

  // ── Inbound ───────────────────────────────────────────────────────
  static const String inboundList = 'inbound-list';
  static const String inboundDetail = 'inbound-detail';
  static const String batchScan = 'batch-scan';
  static const String ocrScan = 'ocr-scan';

  // ── Outbound ──────────────────────────────────────────────────────
  static const String outboundList = 'outbound-list';
  static const String outboundDetail = 'outbound-detail';
  static const String pickVerify = 'pick-verify';

  // ── AI Assistant ──────────────────────────────────────────────────
  static const String aiChat = 'ai-chat';
}

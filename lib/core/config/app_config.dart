/// Enable the offline UI demo with --dart-define=USE_MOCK=true.
abstract final class AppConfig {
  static const useMock = bool.fromEnvironment('USE_MOCK');
}

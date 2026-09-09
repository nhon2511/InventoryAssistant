/// Represents the parsed intent from an NLU (Natural Language Understanding)
/// analysis of the user's text/voice input.
class ParsedIntent {
  const ParsedIntent({
    required this.intent,
    required this.confidence,
    this.entities = const {},
  });

  /// The detected intent type (e.g., 'query_stock', 'create_order', 'report').
  final String intent;

  /// Confidence score (0.0 - 1.0).
  final double confidence;

  /// Extracted entities/slots (e.g., {'product_name': 'iPhone 15', 'location': 'A-01-01'}).
  final Map<String, String> entities;

  /// Whether the confidence is above the minimum threshold.
  bool get isConfident => confidence >= 0.7;
}

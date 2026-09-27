enum AiResultType { text, stockInfo, draftInbound, draftOutbound }
enum AiDraftState { pending, reviewed, cancelled }

class AiResult {
  const AiResult({required this.type, required this.text, this.productName,
    this.quantity, this.lotCode, this.locationCode,
    this.draftState = AiDraftState.pending});
  final AiResultType type;
  final String text;
  final String? productName, lotCode, locationCode;
  final int? quantity;
  final AiDraftState draftState;

  bool get isDraft => type == AiResultType.draftInbound || type == AiResultType.draftOutbound;

  Map<String, dynamic> toJson() => {
    'type': type.name, 'text': text, 'product_name': productName,
    'quantity': quantity, 'lot_code': lotCode, 'location_code': locationCode,
    'draft_state': draftState.name,
  };

  factory AiResult.fromJson(Map<String, dynamic> json) => AiResult(
    type: AiResultType.values.firstWhere((e) => e.name == json['type'], orElse: () => AiResultType.text),
    text: json['text'] as String? ?? '',
    productName: json['product_name'] as String?,
    quantity: (json['quantity'] as num?)?.toInt(),
    lotCode: json['lot_code'] as String?,
    locationCode: json['location_code'] as String?,
    draftState: AiDraftState.values.firstWhere((e) => e.name == json['draft_state'], orElse: () => AiDraftState.pending),
  );

  AiResult copyWith({String? productName, int? quantity, String? lotCode,
    String? locationCode, AiDraftState? draftState}) => AiResult(
      type: type, text: text, productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity, lotCode: lotCode ?? this.lotCode,
      locationCode: locationCode ?? this.locationCode,
      draftState: draftState ?? this.draftState,
    );
}

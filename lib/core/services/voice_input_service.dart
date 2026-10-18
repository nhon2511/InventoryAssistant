import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Device capability only; recognized words never submit a warehouse action.
class VoiceInputService {
  final SpeechToText speech = SpeechToText();
  bool get supported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
  bool get listening => speech.isListening;
  Future<bool> start({
    required void Function(String) onText,
    required void Function(String) onError,
    required void Function() onStatus,
  }) async {
    if (!supported) return false;
    final ready = await speech.initialize(
      onError: (_) => onError(
        'Không nhận được giọng nói. Kiểm tra quyền micro hoặc nhập văn bản.',
      ),
      onStatus: (_) => onStatus(),
    );
    if (!ready) return false;
    await speech.listen(
      onResult: (result) => onText(result.recognizedWords),
      listenOptions: SpeechListenOptions(
        localeId: 'vi_VN',
        cancelOnError: true,
      ),
    );
    return true;
  }

  Future<void> stop() => speech.stop();
  Future<void> dispose() => speech.cancel();
}

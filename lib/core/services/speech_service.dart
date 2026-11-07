import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Service wrapping the [SpeechToText] plugin for voice input.
class SpeechService {
  SpeechService({SpeechToText? speechToText})
      : _speech = speechToText ?? SpeechToText();

  final SpeechToText _speech;

  bool _isInitialized = false;

  bool get isListening => _speech.isListening;
  bool get isAvailable => _isInitialized;

  static const String _defaultLocaleId = 'vi-VN';

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('SpeechService error: ${error.errorMsg}');
        },
        onStatus: (status) {
          debugPrint('SpeechService status: $status');
        },
      );
    } on Object catch (e) {
      debugPrint('SpeechService init failed: $e');
      _isInitialized = false;
    }

    return _isInitialized;
  }

  Future<void> startListening({
    required ValueChanged<SpeechRecognitionResult> onResult,
    String localeId = _defaultLocaleId,
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_isInitialized) {
      final available = await initialize();
      if (!available) return;
    }

    await _speech.listen(
      onResult: onResult,
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: listenFor,
        pauseFor: pauseFor,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancelListening() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }

  void dispose() {
    if (_speech.isListening) {
      _speech.cancel();
    }
  }
}

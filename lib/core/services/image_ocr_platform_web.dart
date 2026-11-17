import 'dart:async';
import 'dart:js_interop';

import 'package:smart_wms/core/services/image_ocr_service.dart';
import 'package:web/web.dart' as web;

@JS('smartWmsOcr.recognize')
external JSPromise<JSString> _recognizeImage(
  web.File file,
  JSFunction onProgress,
);

class _WebImageOcrService implements ImageOcrService {
  @override
  Future<ImageOcrResult?> pickAndRecognize({
    required OcrProgressCallback onProgress,
  }) {
    final completer = Completer<ImageOcrResult?>();
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = 'image/*'
      ..style.display = 'none'
      ..setAttribute('capture', 'environment');
    input.addEventListener(
      'cancel',
      ((web.Event _) {
        input.remove();
        if (!completer.isCompleted) completer.complete(null);
      }).toJS,
    );
    input.onchange = ((web.Event _) {
      final file = input.files?.item(0);
      input.remove();
      if (file == null) {
        completer.complete(null);
        return;
      }

      final previewUrl = web.URL.createObjectURL(file);
      final progressCallback = ((JSString status, JSNumber progress) {
        onProgress(status.toDart, progress.toDartDouble);
      }).toJS;
      _recognizeImage(file, progressCallback).toDart.then(
        (recognizedText) {
          completer.complete(
            ImageOcrResult(previewUrl: previewUrl, text: recognizedText.toDart),
          );
        },
        onError: (Object error) {
          revokePreview(previewUrl);
          completer.completeError(error);
        },
      );
    }).toJS;

    web.document.body?.append(input);
    input.click();
    return completer.future;
  }

  @override
  void revokePreview(String previewUrl) {
    web.URL.revokeObjectURL(previewUrl);
  }
}

ImageOcrService createImageOcrService() => _WebImageOcrService();


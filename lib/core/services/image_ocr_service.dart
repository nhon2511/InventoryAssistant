import 'package:smart_wms/core/services/image_ocr_platform_stub.dart'
    if (dart.library.js_interop) 'package:smart_wms/core/services/image_ocr_platform_web.dart'
    as platform;

class ImageOcrResult {
  const ImageOcrResult({required this.previewUrl, required this.text});

  final String previewUrl;
  final String text;
}

typedef OcrProgressCallback = void Function(String status, double progress);

abstract interface class ImageOcrService {
  Future<ImageOcrResult?> pickAndRecognize({
    required OcrProgressCallback onProgress,
  });

  void revokePreview(String previewUrl);
}

ImageOcrService createImageOcrService() => platform.createImageOcrService();


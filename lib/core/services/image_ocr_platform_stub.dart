import 'package:smart_wms/core/services/image_ocr_service.dart';

ImageOcrService createImageOcrService() => _UnsupportedImageOcrService();

class _UnsupportedImageOcrService implements ImageOcrService {
  @override
  Future<ImageOcrResult?> pickAndRecognize({
    required OcrProgressCallback onProgress,
  }) => Future.error(UnsupportedError('Image OCR is only available on web.'));

  @override
  void revokePreview(String previewUrl) {}
}


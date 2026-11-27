import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smart_wms/core/services/image_ocr_service.dart';
import 'package:smart_wms/core/utils/ocr_text_extractor.dart';
import 'package:smart_wms/core/widgets/scanner_back_button.dart';
import 'package:smart_wms/core/widgets/workspace_layout.dart';

class OcrScanScreen extends StatefulWidget {
  const OcrScanScreen({super.key, this.onApply, this.ocrService});

  final ValueChanged<Map<String, String>>? onApply;
  final ImageOcrService? ocrService;

  @override
  State<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends State<OcrScanScreen> {
  bool get imageOcrAvailable => kIsWeb || widget.ocrService != null;
  final input = TextEditingController();
  final lotNumber = TextEditingController();
  final expiryDate = TextEditingController();
  late final ImageOcrService ocrService;
  String? previewUrl;
  String? errorMessage;
  String progressStatus = '';
  double progress = 0;
  bool isRecognizing = false;
  bool hasResult = false;

  @override
  void initState() {
    super.initState();
    ocrService = widget.ocrService ?? createImageOcrService();
  }

  @override
  void dispose() {
    if (previewUrl case final url?) {
      ocrService.revokePreview(url);
    }
    input.dispose();
    lotNumber.dispose();
    expiryDate.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    setState(() {
      errorMessage = null;
      isRecognizing = true;
      progress = 0;
      progressStatus = 'Đang mở ảnh…';
      hasResult = false;
    });

    try {
      final result = await ocrService.pickAndRecognize(
        onProgress: (status, value) {
          if (!mounted) return;
          setState(() {
            progressStatus = _localizedProgress(status);
            progress = value.clamp(0, 1).toDouble();
          });
        },
      );
      if (!mounted) {
        if (result != null) ocrService.revokePreview(result.previewUrl);
        return;
      }
      if (result == null) return;

      if (previewUrl case final oldUrl?) {
        ocrService.revokePreview(oldUrl);
      }
      final extracted = OcrTextExtractor.extractAll(result.text);
      setState(() {
        previewUrl = result.previewUrl;
        input.text = result.text;
        lotNumber.text = extracted.lotNumber ?? '';
        expiryDate.text = extracted.expiryDate ?? '';
        hasResult = true;
      });
    } on Object {
      if (mounted) {
        setState(() {
          errorMessage = 'Không nhận diện được ảnh. Hãy thử ảnh rõ hơn hoặc nhập thông tin thủ công.';
        });
      }
    } finally {
      if (mounted) setState(() => isRecognizing = false);
    }
  }

  void _analyzeText() {
    final extracted = OcrTextExtractor.extractAll(input.text);
    setState(() {
      lotNumber.text = extracted.lotNumber ?? '';
      expiryDate.text = extracted.expiryDate ?? '';
      hasResult = true;
    });
  }

  void _applyResult() {
    final values = <String, String>{};
    final lot = lotNumber.text.trim();
    final expiry = expiryDate.text.trim();
    if (lot.isNotEmpty) values['lotNumber'] = lot;
    if (expiry.isNotEmpty) values['expiryDate'] = expiry;
    if (values.isNotEmpty) widget.onApply?.call(values);
  }

  String _localizedProgress(String status) => switch (status) {
    'loading tesseract core' => 'Đang tải bộ nhận diện chữ…',
    'loading language traineddata' =>
      'Đang tải dữ liệu tiếng Việt và tiếng Anh…',
    'initializing api' => 'Đang khởi tạo bộ nhận diện…',
    'recognizing text' => 'Đang nhận diện chữ trong ảnh…',
    _ => 'Đang chuẩn bị xử lý ảnh…',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const ScannerBackButton(fallback: '/batch-scan'),
      title: const Text('Số lô & hạn sử dụng'),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: workspacePadding(context),
          children: [
            Text(
              'Nhận diện thông tin trên nhãn sản phẩm',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              imageOcrAvailable
                  ? 'Chọn ảnh hoặc chụp nhãn bằng camera. Kết quả được xử lý trong trình duyệt; hãy kiểm tra lại trước khi dùng.'
                  : 'OCR ảnh hiện chỉ hỗ trợ Web. Nhập văn bản hoặc LOT/HSD thủ công để xem trước.',
            ),
            const SizedBox(height: 16),
            if (imageOcrAvailable)
              FilledButton.icon(
                onPressed: isRecognizing ? null : _chooseImage,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Chọn ảnh hoặc chụp ảnh'),
              ),
            if (isRecognizing) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progress > 0 ? progress : null),
              const SizedBox(height: 8),
              Text(progressStatus),
            ],
            if (errorMessage case final message?) ...[
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (previewUrl case final url?) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  height: 260,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 100,
                    child: Center(
                      child: Text('Không hiển thị được ảnh xem trước.'),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: input,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Văn bản nhận diện (có thể chỉnh sửa)',
                hintText: 'LOT: ABC123\nHSD: 25/12/2027',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isRecognizing ? null : _analyzeText,
              icon: const Icon(Icons.manage_search),
              label: const Text('Phân tích văn bản đã nhập'),
            ),
            if (hasResult || !imageOcrAvailable) ...[
              const SizedBox(height: 20),
              Text(
                'Kiểm tra và chỉnh kết quả',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lotNumber,
                decoration: const InputDecoration(
                  labelText: 'Số lô',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: expiryDate,
                decoration: const InputDecoration(
                  labelText: 'Hạn sử dụng (kiểm tra định dạng/ngày hợp lệ)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Kết quả chưa lưu phiếu và chưa cập nhật tồn kho.'),
              if (widget.onApply != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: FilledButton.icon(
                    onPressed:
                        lotNumber.text.trim().isEmpty &&
                            expiryDate.text.trim().isEmpty
                        ? null
                        : _applyResult,
                    icon: const Icon(Icons.playlist_add_check),
                    label: const Text('Dùng kết quả xem trước'),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            if (kIsWeb)
              const Text(
                'Lần đầu dùng OCR cần tải bộ nhận diện và dữ liệu tiếng Việt/Anh từ internet. Ảnh không được gửi lên backend.',
              ),
          ],
        ),
      ),
    ),
  );
}

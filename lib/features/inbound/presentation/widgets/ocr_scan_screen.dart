import 'package:flutter/material.dart';
import 'package:smart_wms/core/utils/ocr_text_extractor.dart';
import 'package:smart_wms/core/widgets/scanner_back_button.dart';
import 'package:smart_wms/core/widgets/workspace_layout.dart';

class OcrScanScreen extends StatefulWidget {
  const OcrScanScreen({super.key});
  @override
  State<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends State<OcrScanScreen> {
  final input = TextEditingController();
  ({String? expiryDate, String? lotNumber})? result;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const ScannerBackButton(fallback: '/batch-scan'),
      title: const Text('Số lô & hạn sử dụng'),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: ListView(
          padding: workspacePadding(context),
          children: [
            const Text(
              'MÔ PHỎNG PHÂN TÍCH VĂN BẢN · Dán nội dung nhãn hoặc nhập thủ công. Không phải OCR từ camera/ảnh.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: input,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Văn bản nhãn',
                hintText: 'LOT: ABC123\nHSD: 25/12/2027',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => setState(
                () => result = OcrTextExtractor.extractAll(input.text),
              ),
              child: const Text('Phân tích văn bản'),
            ),
            if (result != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Số lô: ${result!.lotNumber ?? "Không tìm thấy"}\nChuỗi ngày nhận diện: ${result!.expiryDate ?? "Không tìm thấy"}\nCần kiểm tra ngày hợp lệ trước khi sử dụng. Chưa lưu dữ liệu.',
                ),
              ),
            const Divider(height: 32),
            const ListTile(
              leading: Icon(Icons.camera_alt_outlined),
              title: Text('OCR camera / ảnh: chưa khả dụng'),
              subtitle: Text(
                'Chưa triển khai nguồn ảnh và kiểm chứng ML Kit trên thiết bị Android/iOS.',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';

/// Full-screen OCR scanning screen for expiry dates and lot numbers.
///
/// Uses `google_mlkit_text_recognition` for on-device OCR.
class OcrScanScreen extends StatelessWidget {
  const OcrScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét OCR - HSD / Số lô')),
      body: const Center(
        child: Text('TODO: Implement ML Kit Text Recognition'),
        // TODO: Integrate google_mlkit_text_recognition
        //       with OcrTextExtractor utility
      ),
    );
  }
}

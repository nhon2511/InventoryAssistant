import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_wms/core/di/reports_providers.dart';
import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/features/reports/domain/entities/inventory_summary.dart';
import 'package:smart_wms/features/reports/domain/usecases/export_excel_usecase.dart';
import 'package:smart_wms/features/reports/domain/usecases/generate_pdf_usecase.dart';
import 'package:smart_wms/features/reports/domain/usecases/get_report_data_usecase.dart';

part 'reports_controller.g.dart';

@riverpod
class ReportsController extends _$ReportsController {
  late final GetReportDataUseCase _getReportData;
  late final ExportExcelUseCase _exportExcel;
  late final GeneratePdfUseCase _generatePdf;

  @override
  Future<InventorySummary> build() async {
    _getReportData = ref.watch(getReportDataUseCaseProvider);
    _exportExcel = ref.watch(exportExcelUseCaseProvider);
    _generatePdf = ref.watch(generatePdfUseCaseProvider);

    return _fetchReportData();
  }

  Future<InventorySummary> _fetchReportData() async {
    final result = await _getReportData(const NoParams());
    return result.fold(
      (failure) => throw StateError(failure.message),
      (summary) => summary,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchReportData);
  }

  /// Exports inventory data as an Excel file and shares it.
  ///
  /// Returns a user-facing status message.
  Future<String> exportExcel() async {
    final summary = state.value;
    if (summary == null) return 'Chưa có dữ liệu để xuất.';

    final result = await _exportExcel(summary.items);
    return result.fold(
      (failure) => failure.message,
      (bytes) async {
        final fileName = _generateFileName('xlsx');
        await _saveAndShareFile(bytes, fileName, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        return 'Đã xuất file Excel: $fileName';
      },
    );
  }

  /// Generates a PDF and opens the print preview dialog.
  ///
  /// Returns a user-facing status message.
  Future<String> exportPdf() async {
    final summary = state.value;
    if (summary == null) return 'Chưa có dữ liệu để xuất.';

    final result = await _generatePdf(summary);
    return result.fold(
      (failure) => failure.message,
      (bytes) async {
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: _generateFileName('pdf'),
        );
        return 'Đã mở bản xem trước PDF.';
      },
    );
  }

  /// Generates a PDF and shares it.
  Future<String> sharePdf() async {
    final summary = state.value;
    if (summary == null) return 'Chưa có dữ liệu để xuất.';

    final result = await _generatePdf(summary);
    return result.fold(
      (failure) => failure.message,
      (bytes) async {
        final fileName = _generateFileName('pdf');
        await Printing.sharePdf(bytes: bytes, filename: fileName);
        return 'Đã chia sẻ file PDF: $fileName';
      },
    );
  }

  String _generateFileName(String extension) {
    final now = DateTime.now();
    final formatted = DateFormat('yyyyMMdd_HHmmss').format(now);
    return 'bao_cao_ton_kho_$formatted.$extension';
  }

  Future<void> _saveAndShareFile(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    if (kIsWeb) {
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: fileName, mimeType: mimeType)],
      );
      return;
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path, mimeType: mimeType)]);
  }
}

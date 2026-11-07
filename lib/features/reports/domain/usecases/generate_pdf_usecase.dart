import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/reports/domain/entities/inventory_summary.dart';

/// Generates a PDF report document from [InventorySummary].
///
/// The PDF follows a standard A4 layout:
/// - Header with company name and report date
/// - Summary metrics
/// - Data table with product details
/// - Footer with signature blocks
class GeneratePdfUseCase {
  const GeneratePdfUseCase();

  FutureEither<Uint8List> call(InventorySummary summary) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader(dateStr),
          footer: _buildFooter,
          build: (context) => [
            _buildSummarySection(summary),
            pw.SizedBox(height: 16),
            _buildDataTable(summary),
            pw.SizedBox(height: 32),
            _buildSignatureSection(),
          ],
        ),
      );

      final bytes = await pdf.save();
      return Right(bytes);
    } on Exception catch (e) {
      return Left(CacheFailure(message: 'Lỗi khi tạo PDF: $e'));
    }
  }

  pw.Widget _buildHeader(String dateStr) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SMART WMS',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1B6B5A'),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'He Thong Quan Ly Kho Hang Thong Minh',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'BAO CAO TON KHO',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Ngay xuat: $dateStr',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 2, color: PdfColor.fromHex('#1B6B5A')),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.Widget _buildSummarySection(InventorySummary summary) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F7FA'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryMetric('Tong mat hang', '${summary.totalProducts}'),
          _summaryMetric('Tong ton kho', '${summary.totalStockQuantity}'),
          _summaryMetric('Sap het hang', '${summary.lowStockCount}'),
          _summaryMetric('Het hang', '${summary.outOfStockCount}'),
        ],
      ),
    );
  }

  pw.Widget _summaryMetric(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1B6B5A'),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _buildDataTable(InventorySummary summary) {
    final headers = [
      'Ma SKU',
      'Ten san pham',
      'Danh muc',
      'Ton kho',
      'Vi tri',
      'Trang thai',
    ];

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1B6B5A')),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(2.5),
        5: const pw.FlexColumnWidth(1.5),
      },
      headers: headers,
      data: summary.items
          .map(
            (item) => [
              item.sku,
              item.productName,
              item.category,
              '${item.totalOnHand}',
              item.locationLabel,
              item.status.label,
            ],
          )
          .toList(),
    );
  }

  pw.Widget _buildSignatureSection() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _signatureBlock('Nguoi lap phieu'),
        _signatureBlock('Thu kho'),
      ],
    );
  }

  pw.Widget _signatureBlock(String title) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '(Ky va ghi ro ho ten)',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 60),
        pw.Container(
          width: 150,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Trang ${context.pageNumber} / ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }
}

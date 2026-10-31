import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/reports/domain/entities/report_item.dart';

/// Generates an Excel (.xlsx) file from the given report items.
///
/// Returns the raw file bytes so the caller can save or share them.
class ExportExcelUseCase {
  const ExportExcelUseCase();

  FutureEither<Uint8List> call(List<ReportItem> items) async {
    try {
      final excel = Excel.createExcel();
      final sheetName = 'Báo cáo tồn kho';
      excel.rename(excel.getDefaultSheet()!, sheetName);
      final sheet = excel[sheetName];

      // ── Header style ──────────────────────────────────────────────
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1B6B5A'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      final headers = [
        'Mã SKU',
        'Tên sản phẩm',
        'Danh mục',
        'Tồn kho hiện tại',
        'Vị trí',
        'Trạng thái',
      ];

      // Write header row
      for (var col = 0; col < headers.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[col]);
        cell.cellStyle = headerStyle;
      }

      // ── Data rows ─────────────────────────────────────────────────
      for (var row = 0; row < items.length; row++) {
        final item = items[row];
        final dataRow = row + 1;

        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: dataRow),
            )
            .value = TextCellValue(item.sku);
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: dataRow),
            )
            .value = TextCellValue(item.productName);
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: dataRow),
            )
            .value = TextCellValue(item.category);
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: dataRow),
            )
            .value = IntCellValue(item.totalOnHand);
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: dataRow),
            )
            .value = TextCellValue(item.locationLabel);
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: dataRow),
            )
            .value = TextCellValue(item.status.label);
      }

      // ── Column widths ─────────────────────────────────────────────
      sheet.setColumnWidth(0, 15); // SKU
      sheet.setColumnWidth(1, 30); // Product name
      sheet.setColumnWidth(2, 15); // Category
      sheet.setColumnWidth(3, 18); // Stock quantity
      sheet.setColumnWidth(4, 25); // Location
      sheet.setColumnWidth(5, 15); // Status

      final bytes = excel.save();
      if (bytes == null) {
        return const Left(
          CacheFailure(message: 'Không thể tạo file Excel.'),
        );
      }

      return Right(Uint8List.fromList(bytes));
    } catch (e) {
      return Left(
        CacheFailure(message: 'Lỗi khi xuất Excel: ${e.toString()}'),
      );
    }
  }
}

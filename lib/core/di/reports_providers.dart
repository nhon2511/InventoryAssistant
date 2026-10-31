import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/core/network/supabase_client_provider.dart';
import 'package:smart_wms/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:smart_wms/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:smart_wms/features/reports/domain/repositories/reports_repository.dart';
import 'package:smart_wms/features/reports/domain/usecases/export_excel_usecase.dart';
import 'package:smart_wms/features/reports/domain/usecases/generate_pdf_usecase.dart';
import 'package:smart_wms/features/reports/domain/usecases/get_report_data_usecase.dart';

final reportsRemoteDataSourceProvider = Provider<ReportsRemoteDataSource>((
  ref,
) {
  return ReportsRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepositoryImpl(ref.watch(reportsRemoteDataSourceProvider));
});

final getReportDataUseCaseProvider = Provider<GetReportDataUseCase>((ref) {
  return GetReportDataUseCase(ref.watch(reportsRepositoryProvider));
});

final exportExcelUseCaseProvider = Provider<ExportExcelUseCase>((ref) {
  return const ExportExcelUseCase();
});

final generatePdfUseCaseProvider = Provider<GeneratePdfUseCase>((ref) {
  return const GeneratePdfUseCase();
});

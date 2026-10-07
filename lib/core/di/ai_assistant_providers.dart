import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/core/network/supabase_client_provider.dart';
import 'package:smart_wms/features/ai_assistant/data/datasources/ai_remote_datasource.dart';
import 'package:smart_wms/features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart';
import 'package:smart_wms/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import 'package:smart_wms/features/ai_assistant/domain/usecases/parse_intent_usecase.dart';
import 'package:smart_wms/features/ai_assistant/domain/usecases/query_stock_usecase.dart';

final aiRemoteDataSourceProvider = Provider<AiRemoteDataSource>((ref) {
  return AiRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>((ref) {
  return AiAssistantRepositoryImpl(ref.watch(aiRemoteDataSourceProvider));
});

final parseIntentUseCaseProvider = Provider<ParseIntentUseCase>((ref) {
  return ParseIntentUseCase(ref.watch(aiAssistantRepositoryProvider));
});

final queryStockUseCaseProvider = Provider<QueryStockUseCase>((ref) {
  return QueryStockUseCase(ref.watch(aiAssistantRepositoryProvider));
});

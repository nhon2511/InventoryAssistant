import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_client_provider.g.dart';

/// Provides the singleton [SupabaseClient] instance to the entire app.
///
/// This provider is kept alive for the app's lifetime so the Supabase
/// connection is never disposed.
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) {
  return Supabase.instance.client;
}

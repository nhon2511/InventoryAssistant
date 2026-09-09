import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Global logger instance.
final logger = Logger(
  printer: PrettyPrinter(methodCount: 0, printEmojis: false),
  level: kDebugMode ? Level.debug : Level.warning,
);

/// Bootstraps the application before `runApp`.
///
/// Initializes:
/// 1. Flutter binding
/// 2. Environment variables from `.env`
/// 3. Supabase SDK
/// 4. System UI overlays
Future<void> bootstrap() async {
  // 1. Ensure Flutter binding is initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load environment variables.
  await dotenv.load();

  // 3. Initialize Supabase.
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    debug: kDebugMode,
  );

  logger.i('Supabase initialized successfully');

  // 4. Set preferred orientations for mobile.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

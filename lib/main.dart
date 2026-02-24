import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/supabase_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: Failed to load .env file: $e');
  }

  // Set SupabaseConstants values from environment variables
  SupabaseConstants.supabaseUrl = dotenv.get('SUPABASE_URL');
  SupabaseConstants.supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY');
  SupabaseConstants.supabaseServiceRoleKey = dotenv.get(
    'SUPABASE_SERVICE_ROLE_KEY',
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
    debug: false,
  );

  runApp(const ProviderScope(child: SuggestaApp()));
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'core/constants/supabase_constants.dart';
import 'core/services/firebase_messaging_service.dart';
import 'features/notifications/data/notification_repository.dart';

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

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
    debug: false,
  );

  // Get Supabase client
  final supabaseClient = Supabase.instance.client;

  // Initialize Firebase Messaging
  if (kDebugMode) {
    print('Initializing Firebase Messaging...');
  }
  final notificationRepository = NotificationRepository(
    supabase: supabaseClient,
  );
  final messagingService = FirebaseMessagingService(
    notificationRepository: notificationRepository,
  );
  await messagingService.initialize();
  if (kDebugMode) {
    print('Firebase Messaging initialization complete');
  }

  runApp(const ProviderScope(child: SuggestaApp()));
}

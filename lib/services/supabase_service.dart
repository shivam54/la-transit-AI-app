import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

/// SupabaseService - singleton wrapper around Supabase client.
/// Assumes `Supabase.initialize` is called in `main.dart` before `runApp`.
class SupabaseService {
  SupabaseService._internal();
  static final SupabaseService _instance = SupabaseService._internal();
  static SupabaseService get instance => _instance;

  SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase. Call this once in main() before runApp.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }
}



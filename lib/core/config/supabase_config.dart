import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static bool _initialized = false;
  
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      
      final url = dotenv.env['SUPABASE_URL'];
      final key = dotenv.env['SUPABASE_ANON_KEY'];
      
      if (url != null && key != null && !url.contains('placeholder')) {
        await Supabase.initialize(url: url, anonKey: key);
        _initialized = true;
      } else {
        if (kDebugMode) {
          debugPrint('SupabaseConfig: Running in local storage mode');
        }
        _initialized = false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SupabaseConfig: Failed to initialize - $e');
      }
      _initialized = false;
    }
  }

  static bool get isInitialized => _initialized;
  
  static SupabaseClient get client {
    if (!_initialized) {
      throw Exception('Supabase not initialized - app is in local storage mode');
    }
    return Supabase.instance.client;
  }
}

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // supabase
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // wiredash
  static String get wiredashProjectId =>
      dotenv.env['WIREDASH_PROJECT_ID'] ?? '';
  static String get wiredashSecret => dotenv.env['WIREDASH_SECRET'] ?? '';

  // validation
  static bool get isConfigValid {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        wiredashProjectId.isNotEmpty &&
        wiredashSecret.isNotEmpty;
  }
}

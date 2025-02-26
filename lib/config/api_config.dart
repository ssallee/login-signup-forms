import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (!_isInitialized) {
      try {
        await dotenv.load(fileName: '.env');
        _isInitialized = true;
        print('API Config initialized successfully');
      } catch (e) {
        print('Error loading .env file: $e');
        rethrow;
      }
    }
  }

  static String get openAiKey {
    final key = dotenv.env['OPENAI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('OPENAI_API_KEY not found in .env file');
    }
    return key;
  }
  
  static bool get isConfigured {
    try {
      return openAiKey.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

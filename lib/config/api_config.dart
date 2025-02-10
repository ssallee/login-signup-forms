import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get openAiKey => 
      dotenv.env['OPENAI_API_KEY'] ?? '';
  
  static bool get isConfigured => 
      openAiKey.isNotEmpty;
}

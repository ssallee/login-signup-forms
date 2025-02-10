class ApiConfig {
  static const String openAiKey = 'YOUR_OPENAI_API_KEY';
  
  static bool get isConfigured => 
      openAiKey.isNotEmpty && 
      openAiKey != 'YOUR_OPENAI_API_KEY';
}

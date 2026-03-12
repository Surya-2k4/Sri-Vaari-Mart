import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiConfig {
  static String get groqApiKey {
    // 1. Try from environment (set via --dart-define during build)
    const envKey = String.fromEnvironment('GROQ_API_KEY');
    if (envKey.isNotEmpty) return envKey;

    // 2. Try from .env file (local development)
    return dotenv.env['GROQ_API_KEY'] ?? '';
  }
}

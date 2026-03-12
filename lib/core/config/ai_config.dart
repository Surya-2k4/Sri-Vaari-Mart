import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiConfig {
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
}

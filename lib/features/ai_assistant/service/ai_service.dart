import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../products/model/product_model.dart';

class AiService {
  final String _apiKey;
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  AiService(this._apiKey);

  Future<String> getAiResponse(
    String userMessage,
    List<ProductModel> products,
    List<Map<String, String>> history,
  ) async {
    try {
      final productInfo = products.map((p) => 
        'Product: ${p.name}, Price: ₹${p.price}, Description: ${p.description}, Category: ${p.type}'
      ).join('\n');

      final systemPrompt = '''
You are a helpful AI assistant for "Sri Vaari Mart", an e-commerce application. 
Your goal is to help users find products, check availability, and provide information about the application.
Always be polite, professional, and concise.

Current Product Data:
$productInfo

Instructions:
- If the user asks about products, use the provided product data.
- If a product is not in the list, politely inform them we don't have it currently or ask them to search for something else.
- Help users with their shopping experience.
- Keep responses friendly and helpful.
''';

      final messages = [
        {'role': 'system', 'content': systemPrompt},
        ...history,
        {'role': 'user', 'content': userMessage},
      ];

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': messages,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? "No response received.";
      } else {
        return "Error: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }
}

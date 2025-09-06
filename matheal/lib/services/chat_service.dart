import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  Future<String> sendMessage(String message) async {
    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception("❌ OPENAI_API_KEY not found in .env");
      }

      print("🔑 API Key loaded: ${apiKey.isNotEmpty}");

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-5', // safer to test than gpt-4o-mini
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a maternal health assistant. Give safe, conservative tips and always recommend consulting a doctor for severe issues.',
            },
            {
              'role': 'user',
              'content': message,
            },
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      print("📡 Response code: ${response.statusCode}");
      print("📩 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        final errorData = jsonDecode(response.body);

        // Special handling for quota issue (429)
        if (response.statusCode == 429 &&
            errorData['error']?['code'] == 'insufficient_quota') {
          return "⚠️ Your API quota has been exceeded. Please check your OpenAI billing or use a different API key.";
        }

        // Other errors
        final errorMessage = errorData['error']?['message'] ??
            "Unknown error occurred (${response.statusCode}).";
        return "❌ API Error: $errorMessage";
      }
    } catch (e) {
      print("❌ ChatService error: $e");
      return "Sorry, something went wrong. Please try again later.";
    }
  }
}

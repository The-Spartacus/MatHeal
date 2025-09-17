import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  // ✅ Updated model and base URL for Gemini
  static const String _model = 'gemini-1.5-flash-latest';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  Future<String> sendMessage(String message) async {
    try {
      // ✅ Updated to use GEMINI_API_KEY
      final apiKey = dotenv.env['GEMINI_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception("❌ GEMINI_API_KEY not found in .env");
      }

      final url = '$_baseUrl?key=$apiKey';
      
      print("📡 Sending request to Gemini...");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        // ✅ Updated body structure for Gemini API
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': message}
              ]
            }
          ],
          'systemInstruction': {
            'parts': [
              {
                'text':
                    'You are a maternal health assistant. Give safe, conservative tips and always recommend consulting a doctor for severe issues.',
              }
            ]
          },
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 500,
          }
        }),
      );
      
      print("📩 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // ✅ Updated response parsing for Gemini
        return data['candidates'][0]['content']['parts'][0]['text'].toString().trim();
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? "Unknown API error occurred (${response.statusCode}).";
        return "❌ API Error: $errorMessage";
      }
    } catch (e) {
      print("❌ ChatService error: $e");
      return "Sorry, something went wrong. Please try again later.";
    }
  }
}

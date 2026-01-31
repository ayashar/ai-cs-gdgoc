import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<String> getSummary(int messageId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/$messageId/summary'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['summary'];
    }
    return "Failed to load summary";
  }

  static Future<String> getSuggestReply(int messageId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/$messageId/suggest-reply'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['suggested_response'];
    }
    return "Failed to generate suggestion";
  }
}

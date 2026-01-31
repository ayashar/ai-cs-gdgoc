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

  // Instance method: Login
  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    return response.statusCode == 200;
  }

  // Instance method: Register
  Future<bool> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'email': email, 'password': password}),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }
}

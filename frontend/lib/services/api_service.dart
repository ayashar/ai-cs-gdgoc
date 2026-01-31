import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // Get stored JWT token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Build headers with Authorization bearer token
  Future<Map<String, String>> _getHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    final token = await _getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<String> getSummary(int messageId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(
      Uri.parse('$baseUrl/messages/$messageId/summary'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['summary'];
    }
    return "Failed to load summary";
  }

  Future<String> suggestReply(int messageId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/messages/$messageId/suggest-reply'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['suggested_response'];
      }
    } catch (e) {
      // Error generating suggestion
    }
    return "Error generating suggestion.";
  }

  Future<void> sendMessage(String content, String customerName) async {
    final headers = await _getHeaders();
    await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: headers,
      body: json.encode({
        "customer_name": customerName,
        "content": content,
        "role": "cs_agent", // Tandai bahwa ini balasan dari CS/Kita
      }),
    );
  }

  // Instance method: Login
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();

        if (data['user'] != null) {
          await prefs.setString('user_name', data['user']['name'] ?? "");
        }
        if (data['token'] != null) {
          await prefs.setString('auth_token', data['token']);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Instance method: Register
  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();

        if (data['user'] != null) {
          await prefs.setString('user_name', data['user']['name'] ?? "");
        }
        if (data['token'] != null) {
          await prefs.setString('auth_token', data['token']);
        }
        await prefs.setString('user_name', name);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
  }

  // Debug: Check if token is stored
  Future<void> debugToken() async {
    final token = await _getToken();
  }
}

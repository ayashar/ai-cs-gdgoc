import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<String> suggestReply(int messageId) async {
    try { 
      final response = await http.post(
        Uri.parse('$baseUrl/messages/$messageId/suggest-reply'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['suggested_response'];
      } 
    } catch (e) {
      print("Error suggest: $e");
    }
    return "Error generating suggestion.";
  }

  Future<void> sendMessage(String content, String customerName) async {
    await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "customer_name": customerName,
        "content": content,
        "role": "cs_agent" // Tandai bahwa ini balasan dari CS/Kita
      }),
    );
  }


  // Instance method: Login
  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      // 1. Ambil data dari response body
      final Map<String, dynamic> data = json.decode(response.body);

      // 2. Inisialisasi SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // 3. Simpan nama (sesuaikan key 'name' dengan JSON dari backend Go kamu)
      // Biasanya di backend kamu: return c.JSON(fiber.Map{"user": user})
      if (data['user'] != null && data['user']['name'] != null) {
        await prefs.setString('user_name', data['user']['name']);
      }

      return true;
    }

    return false;
  }

  // Instance method: Register
  Future<bool> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'user_name',
        name,
      ); // Simpan nama langsung dari input
      return true;
    }
    return false;
  }
}

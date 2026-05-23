import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://50.0.0.150:5000";

  // REGISTER
  static Future registerUser({
    required String fullName,
    required String phone,
    required String password,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "full_name": fullName,
        "phone": phone,
        "password": password,
        "role": role,
      }),
    );

    return jsonDecode(response.body);
  }

  // LOGIN
  static Future loginUser({
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "phone": phone,
        "password": password,
      }),
    );

    return jsonDecode(response.body);
  }

  // GET MARKETPLACE
  static Future getMarketplace() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/marketplace'),
    );

    return jsonDecode(response.body);
  }
}
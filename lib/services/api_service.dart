import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://103.165.226.178:8084/api";
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static Map<String, String> get headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    if (_token != null) "Authorization": "Bearer $_token",
  };

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/employee/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['token'] != null) {
          setToken(data['token']);
          return {"status": "success", "user": data['data']};
        } else {
          return {"status": "error", "message": data['message'] ?? "Login gagal"};
        }
      } else {
        throw Exception("Gagal login: Error ${response.statusCode}");
      }
    } on TimeoutException {
      throw Exception("Koneksi ke server time out. Periksa koneksi internet Anda.");
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> logout() async {
    _token = null;
    return;
  }
}
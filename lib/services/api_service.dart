import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
// mock_api_service.dart tidak lagi digunakan, Anda bisa menghapus impor ini jika mau
import 'mock_api_service.dart';

class ApiService {
  // --- PERBAIKAN 1: Alamat Server yang Benar ---
  static const String baseUrl = "http://103.165.226.178:8084/api";
  static String? _token;

  // --- PERBAIKAN 2: Matikan Mode Mock ---
  static const bool USE_MOCK = false;

  static void setToken(String token) {
    _token = token;
  }

  static Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    if (_token != null) "Authorization": "Bearer $_token",
  };

  static Future<Map<String, dynamic>> login(String email, String password) async {
    // Kode ini sekarang akan berjalan karena USE_MOCK = false
    if (USE_MOCK) return await MockApiService.login(email, password);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/employee/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      ).timeout(const Duration(seconds: 20)); // Waktu tunggu sedikit lebih lama

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

  // --- Sisa Kode (logout, getProfile, dll.) ---
  // (Pastikan sisa kode di file ini juga sudah sesuai dengan versi sebelumnya)

  static Future<Map<String, dynamic>> logout() async {
    if (USE_MOCK) return await MockApiService.logout();

    final response = await http.post(
      Uri.parse("$baseUrl/employee/logout"), // Asumsi endpoint
      headers: _headers,
    );

    _token = null;
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal logout dari server.");
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    if (USE_MOCK) return await MockApiService.getProfile();

    final response = await http.get(
      Uri.parse("$baseUrl/employee/profile"), // Asumsi endpoint
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return {"status": "success", "user": data['data']};
      } else {
        throw Exception(data['message'] ?? "Gagal mengambil data profil");
      }
    } else {
      throw Exception("Gagal memuat profil: ${response.statusCode}");
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    if (USE_MOCK) return {};

    final body = <String, dynamic>{};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (email != null) body['email'] = email;

    final response = await http.put(
      Uri.parse("$baseUrl/employee/profile"), // Asumsi endpoint
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal memperbarui profil");
    }
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'mock_api_service.dart'; // Import mock service

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000/api"; // emulator Android
  static String? _token;

  // Toggle untuk menggunakan mock atau real API
  static const bool USE_MOCK = true; // Set false ketika backend sudah ready

  // Setter untuk menyimpan token setelah login
  static void setToken(String token) {
    _token = token;
    if (USE_MOCK) MockApiService.setToken(token);
  }

  // Getter untuk mendapatkan headers dengan token
  static Map<String, String> get _headers => {
    "Content-Type": "application/json",
    if (_token != null) "Authorization": "Bearer $_token",
  };

  // Login - POST /login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    if (USE_MOCK) {
      return await MockApiService.login(email, password);
    }

    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Simpan token jika ada
      if (data['token'] != null) {
        setToken(data['token']);
      }

      return data;
    } else {
      throw Exception("Failed to login: ${response.statusCode} - ${response.body}");
    }
  }

  // Logout - POST /logout
  static Future<Map<String, dynamic>> logout() async {
    if (USE_MOCK) {
      return await MockApiService.logout();
    }

    final response = await http.post(
      Uri.parse("$baseUrl/logout"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      _token = null; // Clear token
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to logout: ${response.statusCode}");
    }
  }

  // Get User Profile - GET /profile
  static Future<Map<String, dynamic>> getProfile() async {
    if (USE_MOCK) {
      return await MockApiService.getProfile();
    }

    final response = await http.get(
      Uri.parse("$baseUrl/profile"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to get profile: ${response.statusCode}");
    }
  }

  // Update User Profile - PUT /profile
  static Future<Map<String, dynamic>> updateProfile({
    String? nama,
    String? email,
    String? jabatan,
    String? divisi,
  }) async {
    if (USE_MOCK) {
      return await MockApiService.updateProfile(
        nama: nama,
        email: email,
        jabatan: jabatan,
        divisi: divisi,
      );
    }

    final body = <String, dynamic>{};
    if (nama != null) body['nama'] = nama;
    if (email != null) body['email'] = email;
    if (jabatan != null) body['jabatan'] = jabatan;
    if (divisi != null) body['divisi'] = divisi;

    final response = await http.put(
      Uri.parse("$baseUrl/profile"),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to update profile: ${response.statusCode}");
    }
  }

  // ========== ADMIN ENDPOINTS ==========

  // Get All Users - GET /admin/users
  static Future<List<Map<String, dynamic>>> getUsers() async {
    if (USE_MOCK) {
      return await MockApiService.getUsers();
    }

    final response = await http.get(
      Uri.parse("$baseUrl/admin/users"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['users']);
    } else {
      throw Exception("Failed to get users: ${response.statusCode}");
    }
  }

  // Add User - POST /admin/users
  static Future<Map<String, dynamic>> addUser({
    required String nama,
    required String email,
    required String password,
    required String jabatan,
    required String divisi,
    String role = 'user',
  }) async {
    if (USE_MOCK) {
      return await MockApiService.addUser(
        nama: nama,
        email: email,
        password: password,
        jabatan: jabatan,
        divisi: divisi,
        role: role,
      );
    }

    final response = await http.post(
      Uri.parse("$baseUrl/admin/users"),
      headers: _headers,
      body: jsonEncode({
        "nama": nama,
        "email": email,
        "password": password,
        "jabatan": jabatan,
        "divisi": divisi,
        "role": role,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to add user: ${response.statusCode}");
    }
  }

  // Update User - PUT /admin/users/{id}
  static Future<Map<String, dynamic>> updateUser(int userId, {
    String? nama,
    String? email,
    String? jabatan,
    String? divisi,
    String? role,
  }) async {
    if (USE_MOCK) {
      return await MockApiService.updateUser(
        userId,
        nama: nama,
        email: email,
        jabatan: jabatan,
        divisi: divisi,
        role: role,
      );
    }

    final body = <String, dynamic>{};
    if (nama != null) body['nama'] = nama;
    if (email != null) body['email'] = email;
    if (jabatan != null) body['jabatan'] = jabatan;
    if (divisi != null) body['divisi'] = divisi;
    if (role != null) body['role'] = role;

    final response = await http.put(
      Uri.parse("$baseUrl/admin/users/$userId"),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to update user: ${response.statusCode}");
    }
  }

  // Delete User - DELETE /admin/users/{id}
  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    if (USE_MOCK) {
      return await MockApiService.deleteUser(userId);
    }

    final response = await http.delete(
      Uri.parse("$baseUrl/admin/users/$userId"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to delete user: ${response.statusCode}");
    }
  }

  // Get All Divisions - GET /admin/divisions
  static Future<List<String>> getDivisions() async {
    if (USE_MOCK) {
      return await MockApiService.getDivisions();
    }

    final response = await http.get(
      Uri.parse("$baseUrl/admin/divisions"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['divisions']);
    } else {
      throw Exception("Failed to get divisions: ${response.statusCode}");
    }
  }

  // Add Division - POST /admin/divisions
  static Future<Map<String, dynamic>> addDivision(String nama) async {
    if (USE_MOCK) {
      return await MockApiService.addDivision(nama);
    }

    final response = await http.post(
      Uri.parse("$baseUrl/admin/divisions"),
      headers: _headers,
      body: jsonEncode({"nama": nama}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to add division: ${response.statusCode}");
    }
  }

  // Delete Division - DELETE /admin/divisions/{id}
  static Future<Map<String, dynamic>> deleteDivision(int divisionId) async {
    if (USE_MOCK) {
      return await MockApiService.deleteDivision(divisionId);
    }

    final response = await http.delete(
      Uri.parse("$baseUrl/admin/divisions/$divisionId"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to delete division: ${response.statusCode}");
    }
  }

  // Get Dashboard Stats - GET /admin/dashboard
  static Future<Map<String, dynamic>> getDashboardStats() async {
    if (USE_MOCK) {
      return await MockApiService.getDashboardStats();
    }

    final response = await http.get(
      Uri.parse("$baseUrl/admin/dashboard"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to get dashboard stats: ${response.statusCode}");
    }
  }

  // Helper methods
  static bool get isUsingMock => USE_MOCK;

  static void resetMockData() {
    if (USE_MOCK) {
      MockApiService.resetMockData();
    }
  }
}
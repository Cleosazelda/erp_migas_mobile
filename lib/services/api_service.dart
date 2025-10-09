import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://103.165.226.178:8084/api";

  // Variabel statis untuk menyimpan token. Bisa diakses dari mana saja.
  static String? _token;

  // Fungsi untuk mengisi token setelah login berhasil.
  static void setToken(String token) {
    _token = token;
  }

  // Getter yang secara otomatis membuat header otorisasi.
  // Ini akan dipakai oleh service lain (seperti JadwalApiService).
  static Map<String, String> get headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    // Baris ini hanya akan menambahkan header Authorization jika token tidak null.
    if (_token != null) "Authorization": "Bearer $_token",
  };

  // Fungsi untuk login
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
          setToken(data['token']); // Simpan token jika login sukses
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

  // Fungsi logout sesuai permintaan: hanya menghapus token secara lokal.
  static Future<void> logout() async {
    _token = null; // Menghapus token dari memori aplikasi
    return;
  }
}
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiService {
  // Ganti port ke 8085 sesuai contoh API
  static const String baseUrl = "http://103.165.226.178:8085/api";

  // Variabel statis untuk menyimpan token. Bisa diakses dari mana saja.
  static String? _token;

  // Fungsi untuk mengisi token setelah login berhasil.
  static void setToken(String token) {
    _token = token;
  }

  // Getter yang secara otomatis membuat header otorisasi.
  // Ini akan dipakai oleh service lain (seperti JadwalApiService).
  static Map<String, String> get headers {
    Map<String, String> baseHeaders = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    // Baris ini hanya akan menambahkan header Authorization jika token tidak null.
    if (_token != null) {
      baseHeaders["Authorization"] = "Bearer $_token";
    }
    return baseHeaders;
  }


  // Fungsi untuk login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/employee/login"),
        // Gunakan headers dari getter agar otomatis menyertakan Content-Type & Accept
        headers: headers,
        body: jsonEncode({"email": email, "password": password}),
      ).timeout(const Duration(seconds: 20)); // Tambahkan timeout

      // Cek jika response body kosong atau tidak valid JSON
      if (response.body.isEmpty) {
        throw Exception("Respons dari server kosong.");
      }

      final data = jsonDecode(response.body); // Decode JSON di sini

      if (response.statusCode == 200) {
        if (data is Map<String, dynamic> && data['success'] == true && data['token'] != null) {
          setToken(data['token']); // Simpan token jika login sukses
          return {"status": "success", "user": data['data']};
        } else {
          // Jika success false atau tidak ada token, kembalikan pesan error dari API
          return {"status": "error", "message": data is Map<String, dynamic> ? data['message'] : "Format respons tidak dikenal"};
        }
      } else {
        // Tangani error HTTP lainnya
        String errorMessage = "Gagal login: Error ${response.statusCode}";
        if (data is Map<String, dynamic> && data['message'] != null) {
          errorMessage += ". Pesan: ${data['message']}";
        }
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      throw Exception("Koneksi ke server time out. Periksa koneksi internet Anda.");
    } on FormatException {
      throw Exception("Gagal memproses respons dari server. Format tidak valid.");
    } catch (e) {
      // Tangkap error lain dan lempar kembali
      throw Exception("Terjadi kesalahan: ${e.toString()}");
    }
  }

  // Fungsi logout sesuai permintaan: hanya menghapus token secara lokal.
  static Future<void> logout() async {
    _token = null; // Menghapus token dari memori aplikasi
    print("Token direset saat logout."); // Tambahkan log
    return;
  }
}
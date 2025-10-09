import 'dart:convert';
import 'package:http/http.dart' as http;
import '../src/models/jadwal_model.dart';
import 'api_service.dart'; // Penting untuk mengambil token

class JadwalApiService {
  static const String baseUrl = "http://103.165.226.178:8084/api";

  // Fungsi ini tidak berubah
  static Future<List<JadwalRapat>> getAllJadwal() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/ruang-rapat"),
        headers: ApiService.headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => JadwalRapat.fromJson(json)).toList();
      } else {
        throw Exception("Gagal memuat jadwal dari server");
      }
    } catch (e) {
      throw Exception("Terjadi kesalahan koneksi: $e");
    }
  }

  // Fungsi ini tidak berubah
  static Future<Map<String, dynamic>> addJadwal(Map<String, dynamic> jadwalData) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/ruang-rapat"),
        headers: ApiService.headers,
        body: jsonEncode(jadwalData),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Gagal menyimpan jadwal: ${response.body}");
      }
    } catch (e) {
      throw Exception("Gagal menyimpan jadwal: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getPerusahaanList() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/perusahaan"),
        headers: ApiService.headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(body['data']);
      } else {
        throw Exception("Gagal memuat daftar perusahaan");
      }
    } catch (e) {
      throw Exception("Kesalahan koneksi saat mengambil perusahaan: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getDivisiList() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/divisi"),
        headers: ApiService.headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(body['data']);
      } else {
        throw Exception("Gagal memuat daftar divisi");
      }
    } catch (e) {
      throw Exception("Kesalahan koneksi saat mengambil divisi: $e");
    }
  }

  // --- PERBAIKAN UTAMA DI SINI ---
  static Future<List<Map<String, dynamic>>> getRuanganList() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/ruangan"),
        headers: ApiService.headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<Map<String, dynamic>> semuaRuangan = List<Map<String, dynamic>>.from(body['data']);

        // Filter daftar ruangan untuk hanya mengambil yang 'detail' == 2
        final ruanganTersaring = semuaRuangan.where((ruangan) => ruangan['detail'] == "2" ).toList();

        return ruanganTersaring;
      } else {
        throw Exception("Gagal memuat daftar ruangan");
      }
    } catch (e) {
      throw Exception("Kesalahan koneksi saat mengambil ruangan: $e");
    }
  }
}
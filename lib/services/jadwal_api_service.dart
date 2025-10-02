// lib/services/jadwal_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart'; // Impor ApiService untuk mendapatkan headers
import '../src/models/jadwal_model.dart';

class JadwalApiService {
  // Fungsi untuk mengambil semua jadwal
  static Future<List<JadwalRapat>> getAllJadwal() async {
    final response = await http.get(
      Uri.parse("${ApiService.baseUrl}/ruang-rapat"),
      headers: ApiService.headers,
    );

    if (response.statusCode == 200) {
      // --- PERBAIKAN DI SINI ---
      // Langsung decode response body karena API mengembalikan List
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((json) => JadwalRapat.fromJson(json)).toList();
    } else {
      throw Exception("Gagal memuat data jadwal");
    }
  }

  // Fungsi untuk POST/ADD JADWAL (sudah benar, tidak perlu diubah)
  static Future<void> addJadwal(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse("${ApiService.baseUrl}/ruang-rapat"),
      headers: ApiService.headers,
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Gagal menambahkan jadwal. Error: ${response.body}");
    }
  }
}
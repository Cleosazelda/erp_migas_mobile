import 'dart:convert';
import 'dart:async'; // Impor async
import 'package:http/http.dart' as http;
import '../src/models/jadwal_model.dart';
import 'api_service.dart'; // Penting untuk mengambil token dan base URL

class JadwalApiService {
  // Gunakan baseUrl dari ApiService agar konsisten
  static String get baseUrl => ApiService.baseUrl;

  // Fungsi ini sudah benar, hanya perlu memastikan headers dari ApiService digunakan
  static Future<List<JadwalRapat>> getAllJadwal() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/ruang-rapat"),
        headers: ApiService.headers, // Gunakan headers dari ApiService
      ).timeout(const Duration(seconds: 15)); // Tambah timeout

      if (response.statusCode == 200) {
        // API ruang-rapat langsung mengembalikan list, bukan object dengan key 'data'
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => JadwalRapat.fromJson(json)).toList();
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception("Gagal memuat jadwal: ${errorBody['message'] ?? response.reasonPhrase}");
      }
    } on TimeoutException {
      throw Exception("Timeout saat mengambil jadwal. Periksa koneksi internet.");
    } on FormatException {
      throw Exception("Format respons jadwal tidak valid.");
    } catch (e) {
      throw Exception("Terjadi kesalahan saat mengambil jadwal: $e");
    }
  }

  // Fungsi ini sudah benar, hanya perlu memastikan headers dari ApiService digunakan
  static Future<Map<String, dynamic>> addJadwal(Map<String, dynamic> jadwalData) async {
    try {
      // Pastikan semua ID dikirim sebagai String jika API mengharapkannya
      final bodyToSend = Map<String, dynamic>.from(jadwalData);
      bodyToSend['perusahaan_id'] = jadwalData['perusahaan_id']?.toString() ?? "0"; // Default "0" jika null
      bodyToSend['divisi'] = jadwalData['divisi']?.toString(); // Kirim ID divisi sebagai String
      bodyToSend['ruangan'] = jadwalData['ruangan']?.toString(); // Kirim ID ruangan sebagai String
      bodyToSend['jml_peserta'] = jadwalData['jml_peserta']?.toString() ?? "1"; // Kirim sebagai String jika perlu
      bodyToSend['status'] = jadwalData['status']?.toString() ?? "1"; // Kirim sebagai String

      // Hapus field 'user' karena tidak ada di format POST API
      bodyToSend.remove('user');


      print("Mengirim data jadwal: ${jsonEncode(bodyToSend)}"); // Log data yang dikirim

      final response = await http.post(
        Uri.parse("$baseUrl/ruang-rapat"),
        headers: ApiService.headers, // Gunakan headers dari ApiService
        body: jsonEncode(bodyToSend),
      ).timeout(const Duration(seconds: 15)); // Tambah timeout

      print("Status Code Add Jadwal: ${response.statusCode}"); // Log status code
      print("Response Body Add Jadwal: ${response.body}"); // Log response body


      if (response.statusCode == 201 || response.statusCode == 200) { // Handle 200 juga jika API mengembalikan itu
        if (response.body.isEmpty) {
          return {"message": "Booking berhasil dibuat (respons kosong)"}; // Beri respons default jika body kosong
        }
        try {
          return jsonDecode(response.body);
        } catch (e) {
          // Jika body bukan JSON tapi sukses, beri respons default
          return {"message": "Booking berhasil dibuat (respons bukan JSON: ${response.body})"};
        }
      } else {
        String errorMessage = "Gagal menyimpan jadwal (Status: ${response.statusCode})";
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage += ": ${errorBody['message'] ?? response.body}";
        } catch (e) {
          errorMessage += ": ${response.body}"; // Jika body error bukan JSON
        }
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      throw Exception("Timeout saat menyimpan jadwal. Periksa koneksi internet.");
    } catch (e) {
      print("Error detail addJadwal: $e"); // Log error detail
      throw Exception("Terjadi kesalahan saat menyimpan jadwal: $e");
    }
  }

  static Future<Map<String, dynamic>> getUserProfileDivisi() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/profile/divisi"), // Endpoint baru
        headers: ApiService.headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return body['data']; // Return objek 'data' langsung
        } else {
          throw Exception("Gagal memuat data profil user: ${body['message']}");
        }
      } else {
        throw Exception("Gagal memuat data profil (Status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error fetch profil: $e");
    }
  }

  // ASUMSI: Endpoint /api/perusahaan ada dan mengembalikan {"data": [...]}
  static Future<List<Map<String, dynamic>>> getPerusahaanList() async {
    try {
      final response = await http.get(
        // Coba endpoint ini, ganti jika endpoint sebenarnya berbeda
        Uri.parse("$baseUrl/perusahaan"),
        headers: ApiService.headers, // Gunakan headers dari ApiService
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        // Pastikan ada key 'data' dan isinya adalah List
        if (body.containsKey('data') && body['data'] is List) {
          // Konversi ID ke int jika perlu (disesuaikan dengan kebutuhan dropdown)
          return List<Map<String, dynamic>>.from(body['data'].map((item) {
            var newItem = Map<String, dynamic>.from(item);
            if (newItem['id'] is String) {
              newItem['id'] = int.tryParse(newItem['id']) ?? newItem['id']; // Coba parse ke int
            } else if (newItem['id'] != null && newItem['id'] is! int) {
              // Handle jika tipe ID tidak terduga
              print("Warning: Tipe ID Perusahaan tidak terduga: ${newItem['id'].runtimeType}");
            }
            return newItem;
          }));
        } else {
          throw Exception("Format respons daftar perusahaan tidak valid (key 'data' tidak ditemukan/bukan list)");
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception("Gagal memuat daftar perusahaan: ${errorBody['message'] ?? response.reasonPhrase}");
      }
    } on TimeoutException {
      throw Exception("Timeout saat mengambil perusahaan. Periksa koneksi internet.");
    } on FormatException {
      throw Exception("Format respons perusahaan tidak valid.");
    } catch (e) {
      throw Exception("Kesalahan koneksi saat mengambil perusahaan: $e");
    }
  }

  // ASUMSI: Endpoint /api/divisi ada dan mengembalikan {"data": [...]}
  static Future<List<Map<String, dynamic>>> getDivisiList() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/divisi"), // Asumsi endpoint ini ada
        headers: ApiService.headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body.containsKey('data') && body['data'] is List) {
          // Mapping ID dan Nama Divisi
          // PERHATIKAN: Key dari API mungkin 'organization_id' dan 'organization_name'
          return List<Map<String, dynamic>>.from(body['data'].map((item) {
            return {
              // Sesuaikan key 'id' dan 'divisi' ini jika nama key dari API berbeda
              'id': item['organization_id'] ?? item['id'], // Coba organization_id dulu
              'divisi': item['organization_name'] ?? item['divisi'] // Coba organization_name dulu
            };
          }));
        } else {
          throw Exception("Format respons daftar divisi tidak valid (key 'data' tidak ditemukan/bukan list)");
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception("Gagal memuat daftar divisi: ${errorBody['message'] ?? response.reasonPhrase}");
      }
    } on TimeoutException {
      throw Exception("Timeout saat mengambil divisi. Periksa koneksi internet.");
    } on FormatException {
      throw Exception("Format respons divisi tidak valid.");
    } catch (e) {
      throw Exception("Kesalahan koneksi saat mengambil divisi: $e");
    }
  }

  // Fungsi ini sudah benar, hanya perlu memastikan headers dari ApiService digunakan
  static Future<List<Map<String, dynamic>>> getRuanganList() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/ruangan"),
        headers: ApiService.headers, // Gunakan headers dari ApiService
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body.containsKey('data') && body['data'] is List) {
          final List<Map<String, dynamic>> semuaRuangan =
          List<Map<String, dynamic>>.from(body['data']);

          bool _isMeetingRoomDetail(dynamic detail) {
            return detail == 2 || detail == '2' || detail == 4 || detail == '4';
          }

          final Map<String, Map<String, dynamic>> meetingRoomsById = {};

          for (final ruangan in semuaRuangan) {
            if (!_isMeetingRoomDetail(ruangan['detail'])) continue;

            final dynamic id = ruangan['id'] ??
                ruangan['ruangan_id'] ??
                ruangan['kode'] ??
                ruangan['ruangan'];
            final String? key = id?.toString();

            if (key != null) {
              meetingRoomsById[key] = ruangan;
            }
          }

          final List<Map<String, dynamic>> meetingRooms =
          meetingRoomsById.values.toList();

          if (meetingRooms.isNotEmpty) {
            return meetingRooms;
          }

          return semuaRuangan;

        } else {
          throw Exception("Format respons daftar ruangan tidak valid (key 'data' tidak ditemukan/bukan list)");
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception("Gagal memuat daftar ruangan: ${errorBody['message'] ?? response.reasonPhrase}");
      }
    } on TimeoutException {
      throw Exception("Timeout saat mengambil ruangan. Periksa koneksi internet.");
    } on FormatException {
      throw Exception("Format respons ruangan tidak valid.");
    } catch (e) {
      throw Exception("Kesalahan koneksi saat mengambil ruangan: $e");
    }
  }
}
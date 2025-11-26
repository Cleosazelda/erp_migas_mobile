import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL API
  static const String baseUrl = "http://103.165.226.178:8085/api";

  // Token disimpan secara lokal
  static String? _token;


  // Setter untuk token
  static void setToken(String token) {
    _token = token;

    print("🔥 TOKEN FLUTTER: ");
    print(token);
  }

  // Getter header
  static Map<String, String> get headers {
    final baseHeaders = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    if (_token != null) {
      baseHeaders["Authorization"] = "Bearer $_token";
    }
    return baseHeaders;
  }

  // =====================================================
  // =============== AUTH =================================
  // =====================================================

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/employee/login"),
        headers: headers,
        body: jsonEncode({"email": email, "password": password}),
      ).timeout(const Duration(seconds: 20));

      if (response.body.isEmpty) {
        throw Exception("Respons dari server kosong.");
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data['success'] == true && data['token'] != null) {
          setToken(data['token']);
          return {"status": "success", "user": data['data']};
        } else {
          return {"status": "error", "message": data['message'] ?? "Login gagal"};
        }
      } else {
        throw Exception("Gagal login: ${response.statusCode} - ${data['message']}");
      }
    } on TimeoutException {
      throw Exception("Koneksi ke server time out. Periksa koneksi internet Anda.");
    } on FormatException {
      throw Exception("Format respons tidak valid dari server.");
    } catch (e) {
      throw Exception("Terjadi kesalahan: $e");
    }
  }

  static Future<void> logout() async {
    _token = null;
    print("Token direset saat logout.");
    return;
  }

  static Future<Map<String, dynamic>> getProfileDivision() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/profile/divisi"), headers: headers)
          .timeout(const Duration(seconds: 20));

      if (response.body.isEmpty) {
        throw Exception("Respons dari server kosong.");
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return Map<String, dynamic>.from(data['data'] ?? {});
      }

      throw Exception(data['message'] ?? "Gagal mengambil data profil.");
    } on TimeoutException {
      throw Exception("Koneksi ke server time out. Periksa koneksi internet Anda.");
    } on FormatException {
      throw Exception("Format respons tidak valid dari server.");
    } catch (e) {
      throw Exception("Terjadi kesalahan: $e");
    }
  }

  // =====================================================
  // =============== RUANG RAPAT APIs ====================
  // =====================================================

  /// 1. Cek ruang rapat yang tersedia saat ini
  static Future<List<String>> getAvailableRooms() async {
    bool _isMeetingRoomDetail(dynamic detail) {
      return detail == 2 || detail == '2' || detail == 4 || detail == '4';
    }

    String? _extractName(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        return value.trim().isEmpty ? null : value.trim();
      }
      if (value is Map<String, dynamic>) {
        final nested = value['ruangan'] ??
            value['nama_ruangan'] ??
            value['nama'] ??
            value['name'];
        if (nested != null) {
          return _extractName(nested);
        }
      }
      return value.toString();
    }
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/ruang-rapat/available-now"), headers: headers)
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> rooms = data['data'] ?? [];
        final Set<String> uniqueNames = {};

        for (final room in rooms) {
          dynamic detail;
          if (room is Map<String, dynamic>) {
            detail = room['detail'] ??
                (room['ruangan'] is Map
                    ? (room['ruangan'] as Map)['detail']
                    : null);
          }

          if (detail != null && !_isMeetingRoomDetail(detail)) {
            continue;
          }

          final name = _extractName(room);
          if (name != null && name.isNotEmpty) {
            uniqueNames.add(name);
          }
        }

        return uniqueNames.isNotEmpty
            ? uniqueNames.toList()
            : rooms.map((e) => e.toString()).toList();
      } else {
        throw Exception(data['message'] ?? "Gagal memuat daftar ruangan.");
      }
    } catch (e) {
      throw Exception("Gagal memuat ruangan tersedia: $e");
    }
  }

  /// 2. Rekap status ruang rapat (total/pending/approved/rejected)
  static Future<Map<String, dynamic>> getRekapStatus({
    required int month,
    required int year,
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/ruang-rapat/count-status?month=$month&year=$year");
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? {};
      } else {
        throw Exception(data['message'] ?? "Gagal memuat rekap status.");
      }
    } catch (e) {
      throw Exception("Gagal memuat rekap status: $e");
    }
  }

  /// 3. Total jam pemakaian ruang rapat untuk grafik
  static Future<List<Map<String, dynamic>>> getTotalJam({
    required int month,
    required int year,
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/ruang-rapat/total-jam?month=$month&year=$year");
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        List<dynamic> list = data['data'] ?? [];
        return List<Map<String, dynamic>>.from(list);
      } else {
        throw Exception(data['message'] ?? "Gagal memuat total jam.");
      }
    } catch (e) {
      throw Exception("Gagal memuat total jam ruang rapat: $e");
    }
  }
}

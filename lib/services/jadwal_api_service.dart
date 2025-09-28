import '../src/models/jadwal_model.dart';
import 'jadwal_mock_service.dart';

class JadwalApiService {
  // =================================================================
  // UBAH MENJADI 'false' SAAT BACKEND SUDAH SIAP
  static const bool USE_MOCK = true;
  // =================================================================

  static const String baseUrl = "http://103.165.226.178:8084/api";

  static Future<List<JadwalRapat>> getAllJadwal() async {
    if (USE_MOCK) {
      return await JadwalMockService.getAllJadwal();
    }
    // Logika untuk API asli akan ditambahkan di sini nanti
    throw UnimplementedError("Backend endpoint for getAllJadwal is not ready yet.");
  }

  static Future<List<Map<String, dynamic>>> getPerusahaanList() async {
    if (USE_MOCK) {
      return await JadwalMockService.getPerusahaanList();
    }
    throw UnimplementedError("Backend endpoint for getPerusahaanList is not ready yet.");
  }

  static Future<List<Map<String, dynamic>>> getDivisiList() async {
    if (USE_MOCK) {
      return await JadwalMockService.getDivisiList();
    }
    throw UnimplementedError("Backend endpoint for getDivisiList is not ready yet.");
  }

  static Future<List<Map<String, dynamic>>> getRuanganList() async {
    if (USE_MOCK) {
      return await JadwalMockService.getRuanganList();
    }
    throw UnimplementedError("Backend endpoint for getRuanganList is not ready yet.");
  }

  static Future<bool> addJadwal(Map<String, dynamic> jadwalData) async {
    if (USE_MOCK) {
      return await JadwalMockService.addJadwal(jadwalData);
    }
    throw UnimplementedError("Backend endpoint for addJadwal is not ready yet.");
  }
}
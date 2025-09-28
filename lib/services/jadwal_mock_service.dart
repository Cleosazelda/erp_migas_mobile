// lib/services/jadwal_mock_service.dart

import 'dart:math';
import '../src/models/jadwal_model.dart';

class JadwalMockService {
  // --- Data Master Sesuai Tabel Database ---
  static final List<Map<String, dynamic>> _perusahaan = [
    {'id': 1, 'perusahaan': 'PT Migas Utama Jabar', 'callsign': 'MUJ'},
    {'id': 2, 'perusahaan': 'PT MUJ ONWJ', 'callsign': 'ONWJ'},
    {'id': 3, 'perusahaan': 'PT Energi Negeri Mandiri', 'callsign': 'ENM'},
    {'id': 4, 'perusahaan': 'PT MUJ Energi Indonesia', 'callsign': 'MUJI'},
  ];

  static final List<Map<String, dynamic>> _divisi = [
    {'id': 1, 'divisi': 'Sekretaris Perusahaan'},
    {'id': 2, 'divisi': 'Satuan Pengawas Internal'},
    {'id': 8, 'divisi': 'Manajemen Aset'},
    // ...tambahkan divisi lain dari database jika perlu
  ];

  static final List<Map<String, dynamic>> _ruangan = [
    {'id': 38, 'ruangan': 'Ruang Rapat Biomasa'},
    {'id': 39, 'ruangan': 'Ruang Rapat Energi Angin'},
    {'id': 40, 'ruangan': 'Ruang Rapat Gas Bumi'},
    {'id': 43, 'ruangan': 'Ruang Rapat Energi Matahari'},
    {'id': 44, 'ruangan': 'Ruang Rapat Minyak Bumi'},
    // ...tambahkan ruangan lain dari database jika perlu
  ];

  // --- Data Transaksi Sesuai Tabel 'agendas' ---
  static final List<Map<String, dynamic>> _jadwalMentah = [
    { 'id_agenda': 6, 'agenda': 'Rapat Pimpinan', 'perusahaan_id': 1, 'divisi_id': 1, 'user': 'Kusnandar', 'ruangan_id': 43, 'tanggal': DateTime(2025, 5, 19), 'jam_mulai': '08:00:00', 'jam_selesai': '09:00:00', 'jml_peserta': 1, 'status': 3, 'keterangan': null },
    { 'id_agenda': 2, 'agenda': 'Rapim', 'perusahaan_id': 1, 'divisi_id': 8, 'user': 'Kusnandar', 'ruangan_id': 44, 'tanggal': DateTime(2025, 5, 19), 'jam_mulai': '08:00:00', 'jam_selesai': '12:00:00', 'jml_peserta': 50, 'status': 2, 'keterangan': null },
    { 'id_agenda': 3, 'agenda': 'Test', 'perusahaan_id': 1, 'divisi_id': 2, 'user': 'Kusnandar', 'ruangan_id': 39, 'tanggal': DateTime(2025, 5, 21), 'jam_mulai': '08:00:00', 'jam_selesai': '10:00:00', 'jml_peserta': 1, 'status': 1, 'keterangan': null },
    { 'id_agenda': 4, 'agenda': 'Water proofing gedung timur', 'perusahaan_id': 1, 'divisi_id': 8, 'user': 'Indra.Purnama', 'ruangan_id': 39, 'tanggal': DateTime(2025, 5, 22), 'jam_mulai': '09:00:00', 'jam_selesai': '10:00:00', 'jml_peserta': 8, 'status': 2, 'keterangan': null },
  ];

  // Fungsi ini mensimulasikan proses 'JOIN' tabel di backend
  static Future<List<JadwalRapat>> getAllJadwal() async {
    await Future.delayed(const Duration(milliseconds: 800));

    final List<Map<String, dynamic>> dataLengkap = _jadwalMentah.map((jadwal) {
      final perusahaan = _perusahaan.firstWhere((p) => p['id'] == jadwal['perusahaan_id'], orElse: () => {});
      final divisi = _divisi.firstWhere((d) => d['id'] == jadwal['divisi_id'], orElse: () => {});
      final ruangan = _ruangan.firstWhere((r) => r['id'] == jadwal['ruangan_id'], orElse: () => {});

      // Mengubah format agar sesuai dengan model JadwalRapat
      var mutableJson = Map<String, dynamic>.from(jadwal);
      mutableJson['tanggal'] = (jadwal['tanggal'] as DateTime).toIso8601String();
      mutableJson['perusahaan_nama'] = perusahaan['callsign'] ?? 'N/A';
      mutableJson['divisi_nama'] = divisi['divisi'] ?? 'N/A';
      mutableJson['ruangan_nama'] = ruangan['ruangan'] ?? 'N/A';

      return mutableJson;
    }).toList();

    return dataLengkap.map((data) => JadwalRapat.fromJson(data)).toList();
  }

  // Fungsi untuk data dropdown
  static Future<List<Map<String, dynamic>>> getPerusahaanList() async => _perusahaan;
  static Future<List<Map<String, dynamic>>> getDivisiList() async => _divisi;
  static Future<List<Map<String, dynamic>>> getRuanganList() async => _ruangan;

  static Future<bool> addJadwal(Map<String, dynamic> jadwalData) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Simulasi penambahan data baru
    print("Data baru diterima (mock): $jadwalData");
    return true; // Anggap selalu berhasil
  }
}
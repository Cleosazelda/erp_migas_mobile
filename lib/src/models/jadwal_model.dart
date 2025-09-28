// lib/src/models/jadwal_model.dart

class JadwalRapat {
  final int id;
  final String agenda;
  final String pic; // Menggunakan 'user' dari DB sebagai PIC
  final DateTime tanggal;
  final String jamMulai;
  final String jamSelesai;
  final int jumlahPeserta;
  final int status;
  final String perusahaan;
  final String divisi;
  final String ruangan;

  JadwalRapat({
    required this.id,
    required this.agenda,
    required this.pic,
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    required this.jumlahPeserta,
    required this.status,
    required this.perusahaan,
    required this.divisi,
    required this.ruangan,
  });

  // Factory constructor untuk membuat instance dari JSON
  factory JadwalRapat.fromJson(Map<String, dynamic> json) {
    return JadwalRapat(
      id: json['id_agenda'] as int,
      agenda: json['agenda'] as String,
      pic: json['user'] as String,
      tanggal: DateTime.parse(json['tanggal'] as String),
      jamMulai: json['jam_mulai'] as String,
      jamSelesai: json['jam_selesai'] as String,
      jumlahPeserta: json['jml_peserta'] as int,
      status: json['status'] as int,
      // Mengambil nama dari data relasi yang di-JOIN (atau dari mock)
      perusahaan: json['perusahaan_nama'] ?? 'N/A',
      divisi: json['divisi_nama'] ?? 'N/A',
      ruangan: json['ruangan_nama'] ?? 'N/A',
    );
  }
}
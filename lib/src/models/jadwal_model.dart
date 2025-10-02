// lib/src/models/jadwal_model.dart

class JadwalRapat {
  final int id;
  final String agenda;
  final String pic;
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

  factory JadwalRapat.fromJson(Map<String, dynamic> json) {
    // Helper function untuk parsing tanggal yang lebih aman
    DateTime _safeParseDateTime(String? dateString) {
      if (dateString == null) return DateTime.now();
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        // Jika format tanggal dari API salah, gunakan tanggal hari ini sebagai fallback
        print("Error parsing date: $dateString. Defaulting to now.");
        return DateTime.now();
      }
    }

    return JadwalRapat(
      id: json['id'] ?? 0,
      agenda: json['agenda']?.toString() ?? 'Tanpa Agenda',

      // Mengambil nama PIC dari field 'user' di JSON
      pic: json['user']?.toString() ?? 'N/A',

      tanggal: _safeParseDateTime(json['tanggal']),

      jamMulai: json['jam_mulai']?.toString() ?? '00:00:00',
      jamSelesai: json['jam_selesai']?.toString() ?? '00:00:00',
      jumlahPeserta: json['jml_peserta'] ?? 0,
      status: json['status'] ?? 0,
      perusahaan: json['perusahaan']?.toString() ?? 'N/A',
      divisi: json['divisi']?.toString() ?? 'N/A',

      // Mengambil nama ruangan dari field 'nama_ruangan' di JSON
      ruangan: json['nama_ruangan']?.toString() ?? 'N/A',
    );
  }
}

// lib/src/models/jadwal_model.dart

class JadwalRapat {
  // 1. Mendefinisikan semua properti yang akan kita terima dari API.
  // Tipe datanya dibuat spesifik (int, String, DateTime) untuk keamanan tipe data.
  final int id;
  final String agenda;
  final String pic; // Diambil dari 'user' di JSON
  final DateTime tanggal;
  final String jamMulai;
  final String jamSelesai;
  final int jumlahPeserta;
  final int status;
  final String perusahaan;
  final String divisi;
  final String ruangan; // Diambil dari 'nama_ruangan' di JSON

  // 2. Constructor untuk membuat objek JadwalRapat di dalam kode.
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

  // 3. Fungsi PENTING: 'factory constructor' ini bertugas "menerjemahkan"
  //    data mentah JSON dari backend menjadi objek JadwalRapat yang rapi.
  factory JadwalRapat.fromJson(Map<String, dynamic> json) {
    return JadwalRapat(
      // 'json['id'] ?? 0' artinya: "Ambil nilai dari key 'id'.
      // Jika key 'id' tidak ada atau nilainya null, gunakan 0 sebagai nilai default."
      // Ini adalah pengaman agar aplikasi tidak crash jika data dari server tidak lengkap.
      id: json['id'] ?? 0,
      agenda: json['agenda'] ?? 'Tanpa Agenda',
      pic: json['user'] ?? 'N/A', // Mapping 'user' dari JSON ke 'pic' di aplikasi
      tanggal: DateTime.parse(json['tanggal'] ?? DateTime.now().toIso8601String()),
      jamMulai: json['jam_mulai'] ?? '00:00:00',
      jamSelesai: json['jam_selesai'] ?? '00:00:00',
      jumlahPeserta: json['jml_peserta'] ?? 0,
      status: json['status'] ?? 0,
      perusahaan: json['perusahaan'] ?? 'N/A',
      divisi: json['divisi'] ?? 'N/A',
      ruangan: json['nama_ruangan'] ?? 'N/A', // key 'nama_ruangan' dari JSON
    );
  }
}
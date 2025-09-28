import 'package:flutter/material.dart';
import '../../models/jadwal_model.dart';
import '../../../services/jadwal_api_service.dart'; // Import service untuk mengambil data

class JadwalTable extends StatefulWidget {
  final List<JadwalRapat> jadwalList;

  const JadwalTable({super.key, required this.jadwalList});

  @override
  State<JadwalTable> createState() => _JadwalTableState();
}

class _JadwalTableState extends State<JadwalTable> {
  String? selectedRoom;

  // --- PERBAIKAN 1: Kosongkan list ini, akan diisi dari API/mock ---
  List<String> rooms = [];
  bool isRoomLoading = true;

  final List<String> times = List.generate(23, (i) { // Jam 08:00 - 19:00
    final hour = 8 + (i / 2).floor();
    final minute = (i % 2) * 30;
    return "${hour.toString().padLeft(2, '0')}.${minute.toString().padLeft(2, '0')}";
  });

  final double _slotHeight = 80.0;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  // --- PERBAIKAN 2: Buat fungsi untuk mengambil SEMUA data ruangan ---
  Future<void> _loadRooms() async {
    try {
      // Panggil service untuk mendapatkan daftar lengkap ruangan
      final ruanganData = await JadwalApiService.getRuanganList();
      if(mounted) {
        setState(() {
          // Ambil nama ruangan dari data yang didapat
          rooms = ruanganData.map((r) => r['ruangan'] as String).toList();
          rooms.sort(); // Urutkan nama ruangan

          // Pilih ruangan pertama sebagai default jika ada
          if (rooms.isNotEmpty) {
            selectedRoom = rooms.first;
          }
          isRoomLoading = false;
        });
      }
    } catch (e) {
      if(mounted) {
        setState(() {
          isRoomLoading = false;
        });
        // Tampilkan error jika gagal memuat ruangan
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memuat daftar ruangan: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isRoomLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter jadwal yang akan ditampilkan berdasarkan ruangan yang dipilih
    final jadwalRuangan = widget.jadwalList.where((j) => j.ruangan == selectedRoom).toList();

    return Column(
      children: [
        _buildRoomSelector(),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildScheduleView(jadwalRuangan),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: DropdownButtonFormField<String>(
        value: selectedRoom,
        items: rooms.map((String room) => DropdownMenuItem<String>(value: room, child: Text(room))).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) setState(() => selectedRoom = newValue);
        },
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          hintText: "Pilih Ruang Rapat",
        ),
      ),
    );
  }

  // Sisa kode di bawah ini tidak perlu diubah, karena sudah benar
  Widget _buildScheduleView(List<JadwalRapat> roomBookings) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeColumn(),
            Container(width: 1, color: Colors.grey.shade300),
            _buildScheduleColumn(roomBookings),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeColumn() {
    return SizedBox(
      width: 80,
      child: Column(
        children: times.map((time) => Container(
          height: _slotHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5))),
          child: Text(time),
        )).toList(),
      ),
    );
  }

  Widget _buildScheduleColumn(List<JadwalRapat> roomBookings) {
    return Expanded(
      child: Stack(
        children: [
          _buildGridLines(),
          if (roomBookings.isEmpty)
            const Center(

            ),
          ...roomBookings.map((booking) => _buildBookingItem(booking)).toList(),
        ],
      ),
    );
  }

  Widget _buildGridLines() {
    return Column(
      children: List.generate(times.length, (index) => Container(
        height: _slotHeight,
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5))),
      )),
    );
  }

  Widget _buildBookingItem(JadwalRapat jadwal) {
    final startTimeString = jadwal.jamMulai.substring(0, 5).replaceAll(':', '.');
    final endTimeString = jadwal.jamSelesai.substring(0, 5).replaceAll(':', '.');
    final startIndex = times.indexOf(startTimeString);
    final endIndex = times.indexOf(endTimeString);

    if (startIndex == -1 || endIndex == -1 || endIndex <= startIndex) {
      return const SizedBox.shrink();
    }

    final timeSpan = endIndex - startIndex;
    final topPosition = startIndex * _slotHeight;
    final height = timeSpan * _slotHeight;

    return Positioned(
      top: topPosition,
      left: 0,
      right: 0,
      height: height,
      child: Container(
        margin: const EdgeInsets.all(1.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.green.shade200)
        ),
        child: _buildBookingContent(jadwal),
      ),
    );
  }

  Widget _buildBookingContent(JadwalRapat jadwal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${jadwal.agenda} (${jadwal.jumlahPeserta} Org)",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1.3),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          "${jadwal.perusahaan} - ${jadwal.divisi}",
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          "PIC : ${jadwal.pic}",
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: jadwal.status == 2 ? Colors.green : (jadwal.status == 1 ? Colors.orange : Colors.red),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              jadwal.status == 2 ? 'DISETUJUI' : (jadwal.status == 1 ? 'PENDING' : 'DITOLAK'),
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import '../../models/jadwal_model.dart';

class JadwalTable extends StatefulWidget {
  final List<JadwalRapat> jadwalList;

  const JadwalTable({super.key, required this.jadwalList});

  @override
  State<JadwalTable> createState() => _JadwalTableState();
}

class _JadwalTableState extends State<JadwalTable> {
  String? selectedRoom;
  List<String> rooms = [];

  final List<String> times = List.generate(23, (i) { // Jam 08:00 - 19:00
    final hour = 8 + (i / 2).floor();
    final minute = (i % 2) * 30;
    return "${hour.toString().padLeft(2, '0')}.${minute.toString().padLeft(2, '0')}";
  });

  final double _slotHeight = 80.0;

  @override
  void initState() {
    super.initState();
    _extractRoomsFromJadwal();
  }

  @override
  void didUpdateWidget(JadwalTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.jadwalList != oldWidget.jadwalList) {
      _extractRoomsFromJadwal();
    }
  }

  void _extractRoomsFromJadwal() {
    if (widget.jadwalList.isEmpty) {
      setState(() {
        rooms = ["Tidak ada jadwal hari ini"];
        selectedRoom = "Tidak ada jadwal hari ini";
      });
      return;
    }

    final uniqueRooms = widget.jadwalList.map((j) => j.ruangan).toSet().toList();
    uniqueRooms.sort();

    setState(() {
      rooms = uniqueRooms;
      if (selectedRoom == null || !rooms.contains(selectedRoom) || selectedRoom == "Tidak ada jadwal hari ini") {
        selectedRoom = rooms.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final jadwalRuangan = widget.jadwalList.where((j) => j.ruangan == selectedRoom).toList();

    return Column(
      children: [
        _buildRoomSelector(),
        const SizedBox(height: 16),
        if (widget.jadwalList.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Tidak ada jadwal rapat yang disetujui untuk tanggal ini.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Theme.of(context).hintColor),
                ),
              ),
            ),
          )
        else
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
        onChanged: widget.jadwalList.isEmpty ? null : (String? newValue) {
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

  Widget _buildScheduleView(List<JadwalRapat> roomBookings) {
    // --- PENYESUAIAN TEMA ---
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
        color: theme.cardColor,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeColumn(),
            Container(width: 1, color: theme.dividerColor),
            _buildScheduleColumn(roomBookings),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeColumn() {
    // --- PENYESUAIAN TEMA ---
    final theme = Theme.of(context);
    return SizedBox(
      width: 80,
      child: Column(
        children: times.map((time) => Container(
          height: _slotHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5))),
          child: Text(time, style: TextStyle(color: theme.colorScheme.onSurface)),
        )).toList(),
      ),
    );
  }

  Widget _buildScheduleColumn(List<JadwalRapat> roomBookings) {
    // --- PENYESUAIAN TEMA ---
    final theme = Theme.of(context);
    return Expanded(
      child: Stack(
        children: [
          _buildGridLines(),
          if (roomBookings.isEmpty && rooms.first != "Tidak ada jadwal hari ini")
            Center(
              child: Text(
                "Jadwal kosong",
                style: TextStyle(color: theme.hintColor),
              ),
            ),
          ...roomBookings.map((booking) => _buildBookingItem(booking)).toList(),
        ],
      ),
    );
  }

  Widget _buildGridLines() {
    // --- PENYESUAIAN TEMA ---
    final theme = Theme.of(context);
    return Column(
      children: List.generate(times.length, (index) => Container(
        height: _slotHeight,
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5))),
      )),
    );
  }

  Widget _buildBookingItem(JadwalRapat jadwal) {
    try {
      final startHour = int.parse(jadwal.jamMulai.substring(0, 2));
      final startMinute = int.parse(jadwal.jamMulai.substring(3, 5));
      final endHour = int.parse(jadwal.jamSelesai.substring(0, 2));
      final endMinute = int.parse(jadwal.jamSelesai.substring(3, 5));

      final totalStartMinutes = startHour * 60 + startMinute;
      final totalEndMinutes = endHour * 60 + endMinute;

      final startOffset = (totalStartMinutes - (8 * 60)) / 30;
      final endOffset = (totalEndMinutes - (8 * 60)) / 30;

      if (startOffset < 0 || endOffset <= startOffset) {
        return const SizedBox.shrink();
      }

      final topPosition = startOffset * _slotHeight;
      final height = (endOffset - startOffset) * _slotHeight;

      // --- PENYESUAIAN TEMA ---
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Positioned(
        top: topPosition,
        left: 0,
        right: 0,
        height: height,
        child: Container(
          margin: const EdgeInsets.all(1.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
              color: isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isDark ? Colors.green.shade700 : Colors.green.shade200)
          ),
          child: _buildBookingContent(jadwal),
        ),
      );
    } catch (e) {
      print("Error parsing time for agenda '${jadwal.agenda}': $e");
      return const SizedBox.shrink();
    }
  }

  Widget _buildBookingContent(JadwalRapat jadwal) {
    // --- PENYESUAIAN TEMA ---
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${jadwal.agenda} (${jadwal.jumlahPeserta} Org)",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1.3, color: theme.colorScheme.onSurface),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          "${jadwal.perusahaan} - ${jadwal.divisi}",
          style: TextStyle(fontSize: 11, color: theme.hintColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          "PIC : ${jadwal.pic}",
          style: TextStyle(fontSize: 11, color: theme.hintColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        // Status tag tidak perlu diubah karena sudah menggunakan warna solid
        Align(
          alignment: Alignment.bottomRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: jadwal.status == 2 ? Colors.green : (jadwal.status == 1 ? Colors.orange : Colors.red),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              jadwal.status == 2 ? 'DISETUJUI' : (jadwal.status == 1 ? 'DIAJUKAN' : 'DITOLAK'),
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
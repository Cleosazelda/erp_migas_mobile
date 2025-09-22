import 'package:flutter/material.dart';
import 'dart:math';

class JadwalTable extends StatefulWidget {
  final List<Map<String, dynamic>> bookings;

  const JadwalTable({super.key, required this.bookings});

  @override
  State<JadwalTable> createState() => _JadwalTableState();
}

class _JadwalTableState extends State<JadwalTable> {
  String selectedRoom = "RR Matahari";

  final List<String> rooms = [
    "RR Matahari", "RR Minyak Bumi", "RR Gas Bumi", "RR Angin", "RR Biomasa"
  ];

  final List<String> times = List.generate(19, (i) {
    final hour = 8 + (i / 2).floor();
    final minute = (i % 2) * 30;
    return "${hour.toString().padLeft(2, '0')}.${minute.toString().padLeft(2, '0')}";
  });

  final double _slotHeight = 70.0;

  @override
  Widget build(BuildContext context) {
    final roomBookings = widget.bookings.where((b) => b['room'] == selectedRoom).toList();

    return Column(
      children: [
        _buildRoomSelector(),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildScheduleView(roomBookings),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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

  Widget _buildScheduleView(List<Map<String, dynamic>> roomBookings) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        children: [
          _buildHeader(),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeColumn(),
                Container(width: 1, color: Colors.grey.shade300),
                _buildScheduleColumn(roomBookings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: const Text("Waktu", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Container(width: 1, height: 50, color: Colors.grey.shade300),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(selectedRoom, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn() {
    return SizedBox(
      width: 80,
      child: Column(
        children: times.map((time) {
          return Container(
            height: _slotHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
            ),
            child: Text(time),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScheduleColumn(List<Map<String, dynamic>> roomBookings) {
    return Expanded(
      child: Stack(
        children: [
          _buildGridLines(),
          ...roomBookings.map((booking) => _buildBookingItem(booking)).toList(),
        ],
      ),
    );
  }

  Widget _buildGridLines() {
    return Column(
      children: List.generate(times.length, (index) {
        return Container(
          height: _slotHeight,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
          ),
        );
      }),
    );
  }

  Widget _buildBookingItem(Map<String, dynamic> booking) {
    // Ubah format waktu mulai dan selesai agar cocok dengan list `times`
    final startTimeString = booking['start']!.replaceAll(':', '.');
    final endTimeString = booking['end']!.replaceAll(':', '.');

    // Cari posisi indeksnya di dalam list `times`
    final startIndex = times.indexOf(startTimeString);
    final endIndex = times.indexOf(endTimeString);

    // Guard clause: Jika salah satu waktu tidak ditemukan di list, jangan tampilkan apa-apa.
    if (startIndex == -1 || endIndex == -1) {
      print("ERROR: Waktu booking '${booking['title']}' tidak valid atau tidak ditemukan.");
      return const SizedBox.shrink();
    }

    // Hitung durasi (timeSpan) berdasarkan selisih indeks. Ini jauh lebih akurat.
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
        ),
        child: _buildBookingContent(booking),
      ),
    );
  }

  Widget _buildBookingContent(Map<String, dynamic> booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "${booking['title']} (${booking['participants']} Org)",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.3),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          booking['company']!,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          "PIC : ${booking['pic']!}",
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        Align(

          alignment: Alignment.bottomLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              booking['status']!,
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
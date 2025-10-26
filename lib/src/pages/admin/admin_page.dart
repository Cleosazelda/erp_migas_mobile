// lib/src/pages/admin/admin_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/jadwal_api_service.dart'; // Service to get schedule data
import '../../../src/models/jadwal_model.dart'; // Model for schedule data
import '../login_page.dart'; // To navigate on logout
import '../../../services/api_service.dart'; // For logout function

class AdminPage extends StatefulWidget {
  final String firstName;
  final String lastName;

  const AdminPage({super.key, required this.firstName, required this.lastName});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<List<JadwalRapat>> _futureJadwal;

  @override
  void initState() {
    super.initState();
    _loadJadwal();
  }

  void _loadJadwal() {
    setState(() {
      // Fetch all schedules - assuming admins see all approved/pending/rejected
      _futureJadwal = JadwalApiService.getAllJadwal();
    });
  }

  // --- Logout Function ---
  Future<void> _logout() async {
    // Optionally add a confirmation dialog here
    await ApiService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String fullName = "${widget.firstName} ${widget.lastName}";

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Admin Dashboard"),
            Text(
              "Welcome, $fullName!",
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Data",
            onPressed: _loadJadwal,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _logout, // Call logout function
          ),
        ],
      ),
      body: FutureBuilder<List<JadwalRapat>>(
        future: _futureJadwal,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Error loading data: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Tidak ada data peminjaman ruang rapat."));
          }

          final jadwalList = snapshot.data!;

          // Sort by date descending (newest first)
          jadwalList.sort((a, b) => b.tanggal.compareTo(a.tanggal));


          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: jadwalList.length,
            itemBuilder: (context, index) {
              final jadwal = jadwalList[index];
              return _buildBookingCard(jadwal, theme);
            },
          );
        },
      ),
      // Floating action button to add new schedule (similar to DigiAm page)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement navigation to Add Schedule Page for Admin
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Fitur tambah jadwal admin belum diimplementasikan.")),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --- Card Widget to Display Booking Info ---
  Widget _buildBookingCard(JadwalRapat jadwal, ThemeData theme) {
    final bool isDark = theme.brightness == Brightness.dark;
    final DateFormat timeFormat = DateFormat('HH:mm'); // Format HH:mm
    final DateFormat dateFormat = DateFormat('dd MMM yyyy', 'id_ID'); // Format tanggal Indonesia

    Color statusColor;
    String statusText;
    switch (jadwal.status) {
      case 1: // Pending
        statusColor = Colors.orange;
        statusText = 'PENDING';
        break;
      case 2: // Disetujui
        statusColor = Colors.green;
        statusText = 'DISETUJUI';
        break;
      case 3: // Ditolak (Assuming 3 is Ditolak based on screenshot)
        statusColor = Colors.red;
        statusText = 'DITOLAK';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'TIDAK DIKETAHUI';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ruangan & Waktu
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jadwal.ruangan,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${timeFormat.format(jadwal.tanggal.add(Duration(hours: int.parse(jadwal.jamMulai.split(':')[0]), minutes: int.parse(jadwal.jamMulai.split(':')[1]))))} - ${timeFormat.format(jadwal.tanggal.add(Duration(hours: int.parse(jadwal.jamSelesai.split(':')[0]), minutes: int.parse(jadwal.jamSelesai.split(':')[1]))))}",
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            // Agenda
            Text(
              jadwal.agenda,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            // Detail Peminjam
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Peminjam: ${jadwal.pic}",
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Tanggal: ${dateFormat.format(jadwal.tanggal)}",
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),

                  ],
                ),
                // Action Buttons (Placeholder)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                      tooltip: "Edit",
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Fitur edit belum tersedia."), duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                      tooltip: "Hapus",
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Fitur hapus belum tersedia."), duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
// import '../../../services/api_service.dart'; // Dinonaktifkan sementara
// import '../login_page.dart'; // Dinonaktifkan sementara

// CustomCard Widget (dibiarkan karena mungkin dipakai di tempat lain)
class CustomCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData? icon;

  const CustomCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Container(
        width: 160,
        height: 100,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (icon != null)
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color),
              ),
            if (icon != null) const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  // Semua logika dan state di dalam AdminPage dinonaktifkan sementara
  // untuk menghilangkan error.

  @override
  Widget build(BuildContext context) {
    // Tampilkan halaman kosong dengan pesan bahwa fitur ini sedang dalam pengembangan.
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Halaman Admin sedang dalam perbaikan dan akan segera tersedia.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
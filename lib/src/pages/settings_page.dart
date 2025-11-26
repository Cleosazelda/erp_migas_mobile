import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../erp.dart';
import 'login_page.dart';
import 'profile_page.dart';

class SettingsPage extends StatefulWidget {
  // 1. Tambahkan variabel untuk menerima nama
  final String firstName;
  final String lastName;
  final String email;
  final String division;
  final String company;

  const SettingsPage({
    super.key,
    required this.firstName,
    required this.lastName,
    this.email = '',
    this.division = '',
    this.company = '',
  });
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ApiService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings",
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 1,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              leading: Icon(isDark ? Icons.dark_mode : Icons.wb_sunny),
              title: Text(isDark ? "Mode Terang" : "Mode Gelap"),
              trailing: Switch(
                value: isDark,
                activeColor: Colors.green,
                onChanged: (val) {
                  themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profil"),
              // 2. Saat ke ProfilePage, kirim data nama yang sudah diterima
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(
                    firstName: widget.firstName,
                    lastName: widget.lastName,
                    email: widget.email,
                    division: widget.division,
                    company: widget.company,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../erp.dart';
import 'login_page.dart';
import 'profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDark = false;

  @override
  void initState() {
    super.initState();
    isDark = themeNotifier.value == ThemeMode.dark;
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],

        );
      },
    );

    if (shouldLogout == true) {
      try {
        await ApiService.logout(); // panggil service logout biar session ke-clear
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal logout: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(
                  isDark ? Icons.dark_mode : Icons.wb_sunny,
                  color: isDark ? Colors.blueGrey : Colors.yellow[700],
                ),
                title: Text(
                  isDark ? "Light Mode" : "Dark Mode",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                trailing: Switch(
                  value: isDark,
                  activeColor: Colors.green,
                  onChanged: (val) {
                    setState(() {
                      isDark = val;
                      themeNotifier.value =
                      isDark ? ThemeMode.dark : ThemeMode.light;
                    });
                  },
                ),
              ),

              ListTile(
                leading: Icon(
                  Icons.person,
                  color:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                title: Text(
                  "Profile",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.logout,
                  color:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                title: Text(
                  "Logout",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: _logout, // pakai handling logout
              ),
            ],
          ),
        ),
      ),
    );
  }
}

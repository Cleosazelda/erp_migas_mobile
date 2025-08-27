import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Settings",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

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
                      themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
                    });
                  },
                ),
              ),

              ListTile(
                leading: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                title: Text(
                  "Logout",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
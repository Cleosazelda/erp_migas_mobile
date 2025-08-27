// lib/pages/home_page.dart
import 'package:erp/src/pages/profile_page.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_card.dart';
import 'detail_page.dart';
import 'history_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _HomeGrid(),
    const HistoryPage(),
    const SettingsPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              "assets/images/logo.png",
              height: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              "ERP MUJ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),

      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "History",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}

class _HomeGrid extends StatelessWidget {
  const _HomeGrid();

  @override
  Widget build(BuildContext context) {
    final apps = [
      {
        "title": "DigiAM",
        "subtitle": "Aplikasi Manajemen Aset",
        "image": "assets/images/digiam.png"
      },
      {
        "title": "Bisnis AP",
        "subtitle": "Monitoring Bisnis AP",
        "image": "assets/images/bisnis_ap.png"
      },
      {
        "title": "PBJ",
        "subtitle": "Pengelolaan PBJ",
        "image": "assets/images/pbj.png"
      },
      {
        "title": "Disposisi",
        "subtitle": "Aplikasi Disposisi",
        "image": "assets/images/disposisi.png"
      },
      {
        "title": "Talenta",
        "subtitle": "Aplikasi HR",
        "image": "assets/images/talenta.png"
      },
      {
        "title": "Mansis",
        "subtitle": "Manajemen Sistem",
        "image": "assets/images/mansis.png"
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Header: foto profil + welcome
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundImage: AssetImage("assets/images/logo.png"), // default foto profil
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Welcome, User!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "ERP MUJ",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),

        // 🔹 Grid aplikasi
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              return CustomCard(
                title: app["title"]!,
                subtitle: app["subtitle"]!,
                image: app["image"]!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailPage(
                        title: app["title"]!,
                        subtitle: app["subtitle"]!,
                        image: app["image"]!,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

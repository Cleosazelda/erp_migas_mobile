import 'package:flutter/material.dart';
import '../widgets/custom_card.dart';
import 'detail_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'history_page.dart';
import '../erp.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return const _HomeGrid();
      case 1:
        return const HistoryPage();
      case 2:
        return const SettingsPage();
      default:
        return const _HomeGrid();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: _selectedIndex == 0
            ? const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bg_home.png"),
            fit: BoxFit.cover,
          ),
        )
            : null,
        child: Column(
          children: [
            if (_selectedIndex == 0)
              SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: const SizedBox(height: 20),
                ),
              ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        child: _getCurrentPage(),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          border: Border(
                            top: BorderSide(
                              color: theme.dividerColor,
                              width: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavItem(0, Icons.home, "Home"),
                            _buildNavItem(1, Icons.history, "History"),
                            _buildNavItem(2, Icons.settings, "Settings"),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.disabledColor,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.disabledColor,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

//  HOME GRID
class _HomeGrid extends StatelessWidget {
  const _HomeGrid();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                //ava
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                  ),
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey.withOpacity(0.6),
                    backgroundImage: AssetImage("assets/images/logo.png"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ERP MUJ",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Welcome User!",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.0,
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
      ),
    );
  }
}

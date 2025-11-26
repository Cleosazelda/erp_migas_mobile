import 'package:flutter/material.dart';
import '../widgets/custom_card.dart';
import 'DigiAm/home_page.dart';
import 'admin/DigiAm/dashboard_admin.dart';
import 'detail_page.dart';
import 'history_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String division;
  final String company;
  final bool isAdmin;
  const HomePage({
    super.key,
    required this.firstName,
    required this.lastName,
    this.email = '',
    this.division = '',
    this.company = '',
    this.isAdmin = false,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<HistoryEntry> _history = [];

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _addToHistory(String appName) {
    setState(() {
      _history.insert(0, HistoryEntry(appName: appName, accessedAt: DateTime.now()));
      if (_history.length > 30) {
        _history.removeLast();
      }
    });
  }

  List<Widget> get _pages => [
    _HomeGrid(
      firstName: widget.firstName,
      lastName: widget.lastName,
      email: widget.email,
      division: widget.division,
      company: widget.company,
      isAdmin: widget.isAdmin,
      onOpenApp: _addToHistory,
    ),
    HistoryPage(historyItems: _history),
    SettingsPage(
      firstName: widget.firstName,
      lastName: widget.lastName,
      email: widget.email,
      division: widget.division,
      company: widget.company,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _HomeGrid extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String division;
  final String company;
  final bool isAdmin;
  final ValueChanged<String> onOpenApp;

  const _HomeGrid({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.division,
    required this.company,
    this.isAdmin = false,
    required this.onOpenApp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final apps = [
      {"title": "DigiAM", "subtitle": "Aplikasi Manajemen Aset", "image": "assets/images/digiam.png"},
      {"title": "Bisnis AP", "subtitle": "Monitoring Bisnis AP", "image": "assets/images/bisnis_ap.png"},
      {"title": "PBJ", "subtitle": "Pengelolaan PBJ", "image": "assets/images/pbj.png"},
      {"title": "Disposisi", "subtitle": "Aplikasi Disposisi", "image": "assets/images/disposisi.png"},
      {"title": "Talenta", "subtitle": "Aplikasi HR", "image": "assets/images/talenta.png"},
      {"title": "Mansis", "subtitle": "Manajemen Sistem", "image": "assets/images/mansis.png"},
    ];

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage("assets/images/bg_home.png"), fit: BoxFit.cover),
      ),
      child: Column(
        children: [
          const SafeArea(bottom: false, child: SizedBox(height: 36)),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfilePage(
                                firstName: firstName,
                                lastName: lastName,
                                email: email,
                                division: division,
                                company: company,
                              ),
                            ),
                          ),
                          child: const CircleAvatar(radius: 25, backgroundColor: Colors.grey, backgroundImage: AssetImage("assets/images/logo.png")),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("ERP MUJ", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              Text("Welcome $firstName $lastName!", style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.0,
                        ),
                        itemCount: apps.length,
                        itemBuilder: (context, index) {
                          final app = apps[index];
                          return CustomCard(
                            title: app["title"]!,
                            subtitle: app["subtitle"]!,
                            image: app["image"]!,
                            onTap: () {
                              onOpenApp(app["title"]!);
                              if (app["title"] == "DigiAM") {
                                if (isAdmin) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminDashboardPage(
                                        firstName: firstName,
                                        lastName: lastName,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DigiAmHomePage(
                                            firstName: firstName,
                                            lastName: lastName,
                                          ),
                                    ),
                                  );
                                }
                              } else {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(
                                  title: app["title"]!, subtitle: app["subtitle"]!, image: app["image"]!,
                                )));
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
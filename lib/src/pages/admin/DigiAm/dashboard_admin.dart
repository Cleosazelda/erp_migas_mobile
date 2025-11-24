// lib/src/pages/admin/DigiAm/dashboard_admin.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';

// --- Impor Anda ---
import 'admin_page.dart';
import '../../login_page.dart';
// PENTING: Impor KEDUA service
import '../../../../services/api_service.dart';
import '../../../../services/jadwal_api_service.dart';
import '../../../models/jadwal_model.dart';
import '../../DigiAm/tambah_jadwal_page.dart';
// ---------------------------------------------
import '../../../erp.dart';
import '../../home_page.dart';

class AdminDashboardPage extends StatefulWidget {
  final String firstName;
  final String lastName;

  const AdminDashboardPage({
    super.key,
    required this.firstName,
    required this.lastName,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  String _currentPageTitle = "Manajemen Aset";
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isExpandedAvailableRooms = false;

  // --- ⭐️ PEMBAGIAN STATE BARU ⭐️ ---

  // 1. Data untuk Tab 2 (List Peminjaman) & Total Ruangan
  Future<Map<String, dynamic>>? _futureDashboardData;
  List<JadwalRapat> _allBookings = [];
  List<Map<String, dynamic>> _allRooms = []; // -> Dipakai untuk total di Card 1

  // 2. Data Real-time untuk Card 1 (Ruangan Tersedia)
  Future<List<String>>? _futureAvailableRooms;

  // 3. Data Filterable untuk Card 2 (Rekap) & Card 3 (Chart)
  Future<Map<String, dynamic>>? _futureDashboardStats;
  // ---------------------------------------------

  bool _isMeetingRoomDetail(dynamic detail) {
    return detail == 2 || detail == '2' || detail == 4 || detail == '4';
  }

  List<Widget> get _adminContentPages {
    return [
      _buildDashboardSummaryContent(context),     // SELALU DI-BUILD ULANG
      AdminPage(firstName: widget.firstName, lastName: widget.lastName),
      _buildPlaceholderPage("Admin PBJ"),
      _buildPlaceholderPage("Manajemen User"),
    ];
  }


  // --- State untuk Filter UI ---
  // Default filter: Okt 2025, sesuai contoh API
  DateTime _selectedDate = DateTime.now();
  // Tanggal real-time untuk AppBar
  final DateTime _currentDate = DateTime.now();
  final List<String> _months = const ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  static const int _firstDashboardYear = 2023;
  late final List<int> _availableYears;
  // ------------------------------------

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);

    // Panggil semua 3 loader data
    _loadDashboardData();   // Data untuk Tab 2 & total ruangan
    _loadAvailableRooms();  // Data real-time Card 1
    _availableYears = _generateAvailableYears();
    _loadDashboardStats();  // Data filterable Card 2 & 3 (pake default _selectedDate)
  }

  List<int> _generateAvailableYears() {
    final currentYear = DateTime.now().year;
    final years = <int>[];
    for (var year = currentYear; year >= _firstDashboardYear; year--) {
      years.add(year);
    }
    if (!years.contains(_selectedDate.year)) {
      years.add(_selectedDate.year);
      years.sort((a, b) => b.compareTo(a));
    }
    return years;
  }

  // --- 1. Loader untuk Tab 2 & Total Ruangan ---
  Future<void> _loadDashboardData() async {
    setState(() {
      _futureDashboardData = _fetchData();
    });
  }

  Future<Map<String, dynamic>> _fetchData() async {
    try {
      final results = await Future.wait([
        JadwalApiService.getAllJadwal(),
        JadwalApiService.getRuanganList(),
      ]);
      final bookings = results[0] as List<JadwalRapat>;
      final rooms = results[1] as List<Map<String, dynamic>>;
      final meetingRooms = rooms
          .where((room) => _isMeetingRoomDetail(room['detail']))
          .toList();
      if (mounted) {
        setState(() {
          _allBookings = bookings;
          _allBookings.sort((a, b) => b.tanggal.compareTo(a.tanggal));
          _allRooms = meetingRooms; // ⭐️ PENTING: Ini ngisi total ruangan
        });
      }
      return {'bookings': bookings, 'rooms': meetingRooms};
    } catch (error) {
      if (mounted) _showError("Gagal memuat data list admin: ${error.toString().replaceFirst('Exception: ', '')}");
      throw error;
    }
  }

  // --- 2. Loader untuk Card 1 (Real-time) ---
  Future<void> _loadAvailableRooms() async {
    if (mounted) {
      setState(() {
        _futureAvailableRooms = ApiService.getAvailableRooms();
      });
    }
  }

  // --- 3. Loader untuk Card 2 & 3 (Filterable) ---
  Future<void> _loadDashboardStats() async {
    if (mounted) {
      setState(() {
        // Panggil _fetchDashboardStats() yang SEKARANG HANYA 2 API
        _futureDashboardStats = _fetchDashboardStats();
      });
    }
  }

  Future<Map<String, dynamic>> _fetchDashboardStats() async {
    try {
      // Panggil HANYA 2 API yang butuh filter month/year
      final results = await Future.wait([
        ApiService.getRekapStatus(month: _selectedDate.month, year: _selectedDate.year),
        ApiService.getTotalJam(month: _selectedDate.month, year: _selectedDate.year),
      ]);
      // Kembalikan data yg sudah di-parse
      return {
        'statusCounts': results[0] as Map<String, dynamic>,
        'totalJam': results[1] as List<Map<String, dynamic>>,
      };
    } catch (e) {
      if (mounted) _showError("Gagal memuat statistik dashboard: ${e.toString().replaceFirst('Exception: ', '')}");
      throw e;
    }
  }


  Future<void> _refreshData() async {
    // Muat ulang KETIGA set data
    await _loadDashboardData();
    await _loadAvailableRooms();
    setState(() {
      _futureDashboardStats = _fetchDashboardStats();
    });
  }


  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
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

  void _onSelectItem(int index, String title) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
        _currentPageTitle = title;
      });
      Navigator.of(context).pop();
    }
  }

  Widget _buildPlaceholderPage(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            "assets/images/DigiAm/ruangan_tersedia.png",
            width: 50,
            height: 50,
            color: Colors.grey[400],
            errorBuilder: (ctx,e,st) => Icon(Icons.construction, size: 50, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            "$title\n(Coming Soon)",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String fullName = "${widget.firstName} ${widget.lastName}";
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(

          leading: IconButton(
            icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/logo.png",
                width: 40,
                height: 40,
                errorBuilder: (ctx, e, st) => Icon(Icons.business, size: 40),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Text(
                    DateFormat('E, dd MMMM yyyy', 'id_ID').format(_currentDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _currentPageTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    "Selamat Datang $fullName!",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Refresh Data",
              onPressed: _refreshData,
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: isDark ? Colors.grey[850] : Colors.white,
          child: Column(
            children: [
              _buildDrawerHeader(context: context, fullName: fullName, isDark: isDark),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildSectionTitle(context, "Layanan Umum"),
                    _buildSidebarItem(
                      context: context,
                      imagePath: "assets/images/home.png",
                      title: "Beranda",
                      index: 0,
                      isSelected: false,
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomePage(
                            firstName: widget.firstName,
                            lastName: widget.lastName,
                          ),
                        ),
                      ),
                    ),

                    _buildSidebarItem(
                      context: context,
                      imagePath: "assets/images/DigiAm/dashboard_logo.png",
                      title: "Dasbor",
                      index: 0,
                      isSelected: _selectedIndex == 0,
                      onTap: () => _onSelectItem(0, "Manajemen Aset"),
                    ),

                        _buildSidebarItem(
                      context: context,
                      imagePath: "assets/images/DigiAm/ruang_rapat_logo.png",
                      title: "Ruang Rapat",
                      index: 1,
                      isSelected: _selectedIndex == 1,
                      onTap: () => _onSelectItem(1, "Admin Ruang Rapat"),
                    ),
                    const SizedBox(height: 12),
                    _buildThemeToggle(context),

                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _logout(context);
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _adminContentPages,
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: TambahJadwalPage(namaPengguna: fullName),
            ),
          ).then((result) {
            if (result == true && mounted) {
              _refreshData();
            }
          });
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Tambah Jadwal Baru',
      )
          : null,
    );
  }

  Widget _buildSidebarItem({
    required BuildContext context,
    required String imagePath,
    required String title,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isSelected ? theme.colorScheme.onSurface : theme.hintColor;
    final bgColor = isSelected
        ? (isDark ? Colors.grey[850] : Colors.grey[200])
        : Colors.transparent;

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Image.asset(
                imagePath,
                width: 22,
                height: 22,
                color: color,
                errorBuilder: (ctx, e, st) => Icon(Icons.error, color: Colors.red, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          ),
        ),
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, mode, _) {
            final darkMode = mode == ThemeMode.dark;
            return SwitchListTile(
              value: darkMode,
              onChanged: (value) {
                themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
              },
              title: Text(
                'Mode ${darkMode ? 'Gelap' : 'Terang'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Sesuaikan tampilan sidebar',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
              secondary: Icon(
                darkMode ? Icons.dark_mode : Icons.light_mode,
                color: theme.colorScheme.primary,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawerHeader({
    required BuildContext context,
    required String fullName,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark ? theme.colorScheme.surface : theme.colorScheme.surfaceVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.grey[850]!.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(6.0),

                child: Image.asset(
                  "assets/images/logo.png",
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.account_circle,
                    size: 38,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName.trim().isEmpty ? "Admin" : fullName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Aplikasi DigiAm",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.hintColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // =========================================================================
  // --- ⭐️ DASHBOARD CONTENT (INDEX 0) SEKARANG DIBAGI JADI 2 BAGIAN ⭐️ ---
  // =========================================================================

  /// Widget utama yang membangun UI Dashboard (Index 0)
  Widget _buildDashboardSummaryContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF0F2F5),
      child: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderAndFilter(theme),
              const SizedBox(height: 20),
              _buildMonthScroller(theme),
              const SizedBox(height: 20),

              // --- BAGIAN 1: REAL-TIME ---
              // Card ini punya FutureBuilder sendiri & tidak terpengaruh filter
              _buildRealtimeAvailableRoomsCard(theme),

              const SizedBox(height: 16),

              // --- BAGIAN 2: FILTERABLE ---
              // Card Rekap & Chart ada di dalam FutureBuilder ini
              // dan akan di-build ulang saat _futureDashboardStats berubah
              _buildFilterableStatsCards(theme),
            ],
          ),
        ),
      ),
    );
  }

  /// Card 1: Ruangan Tersedia (Real-time, tidak ter-filter)
  /// Card 1: Ruangan Tersedia (Real-time, tidak ter-filter)
  Widget _buildRealtimeAvailableRoomsCard(ThemeData theme) {
    return FutureBuilder<List<String>>(
      future: _futureAvailableRooms,
      builder: (context, snapshot) {
        // Ambil data dari API
        List<String> availableRoomNames = [];
        if (snapshot.hasData) {
          availableRoomNames = snapshot.data ?? [];
        }

        if (_allRooms.isNotEmpty) {
          final allowedNames = _allRooms
              .map((room) => (room['ruangan'] ?? room['nama_ruangan'])?.toString())
              .whereType<String>()
              .toSet();
          final filtered = availableRoomNames
              .where((name) => allowedNames.contains(name))
              .toList();

          if (filtered.isNotEmpty) {
            availableRoomNames = filtered;
          }
        }

        int availableRoomCount = availableRoomNames.length;
        int totalRuangan = _allRooms.length;

        final bool isDark = theme.brightness == Brightness.dark;

        // expand/collapse state
        final bool expanded = _isExpandedAvailableRooms;

        // data yang ditampilkan
        final List<String> toShow = expanded
            ? availableRoomNames
            : availableRoomNames.take(2).toList();

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: isDark ? Colors.grey[800] : Colors.white,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  "assets/images/DigiAm/ruangan_tersedia.png",
                  height: 70,
                  width: 70,
                  errorBuilder: (ctx, e, st) =>
                      Icon(Icons.meeting_room, size: 40, color: Colors.green),
                ),
                const SizedBox(width: 16),

                // ====== TEKS KANAN ======
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ruangan Tersedia (Hari Ini)",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // loading / error / jumlah tersedia
                      if (snapshot.connectionState == ConnectionState.waiting)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (snapshot.hasError)
                        Text(
                          "Gagal memuat",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 18,
                          ),
                        )
                      else
                        Text(
                          "$availableRoomCount/$totalRuangan",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),

                      const SizedBox(height: 8),

                      // ====== LIST RUANGAN ======
                      ...toShow.map((name) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            "• $name",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),

                      // ====== tombol expand ======
                      if (!expanded && availableRoomNames.length > 2)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isExpandedAvailableRooms = true;
                            });
                          },
                          child: Text(
                            "klik untuk lihat ${availableRoomNames.length - 2} lainnya...",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      // ====== tombol collapse ======
                      if (expanded)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isExpandedAvailableRooms = false;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              "Tutup",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  /// Card 2 & 3: Rekap Status dan Chart (Filterable)
  Widget _buildFilterableStatsCards(ThemeData theme) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _futureDashboardStats,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Tampilkan placeholder loading untuk kedua card
          return Column(
            children: [
              Card(elevation: 0, child: Container(height: 120, child: Center(child: CircularProgressIndicator()))),
              const SizedBox(height: 16),
              Card(elevation: 0, child: Container(height: 250, child: Center(child: CircularProgressIndicator()))),
            ],
          );
        }

        if (snapshot.hasError) {
          // Tampilkan error
          return Card(
            elevation: 0,
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 30),
                    SizedBox(height: 10),
                    Text(
                      "Gagal memuat data rekap & grafik: ${snapshot.error.toString().replaceFirst('Exception: ', '')}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Jika sukses, ekstrak datanya
        final stats = snapshot.data ?? {};
        final statusCounts = (stats['statusCounts'] as Map<String, dynamic>?) ?? {};

        // --- ⭐️⭐️⭐️ INI DIA FIXNYA ⭐️⭐️⭐️ ---
        // Baris ini yang menyebabkan error. Kita harus cast dengan benar.
        final totalJamData = List<Map<String, dynamic>>.from(stats['totalJam'] ?? []);
        // --- ⭐️⭐️⭐️ SELESAI FIX ⭐️⭐️⭐️ ---

        return Column(
          children: [
            // --- Card 2: Rekap Status (BARU) ---
            _buildRekapStatusCard(theme, statusCounts),
            const SizedBox(height: 16),
            // --- Card 3: Grafik (BARU) ---
            _buildUsageChartCard(theme, totalJamData),
          ],
        );
      },
    );
  }


  /// Membangun header: HANYA Filter Tahun (Teks judul/sapaan dihapus)
  Widget _buildHeaderAndFilter(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end, // Dorong filter ke kanan
      children: [
        // Filter Tahun
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedDate.year,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              dropdownColor: Colors.green[700],
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              items: _availableYears.map((int year) {
                return DropdownMenuItem<int>(
                  value: year,
                  child: Text(year.toString()),
                );
              }).toList(),
              onChanged: (int? newYear) {
                if (newYear != null && newYear != _selectedDate.year) {
                  setState(() {
                    _selectedDate = DateTime(newYear, _selectedDate.month, 1);
                    _futureDashboardStats = _fetchDashboardStats(); // WAJIB!
                  });

                }
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Membangun scroller horizontal untuk bulan
  /// =============================
  /// FIXED MONTH SCROLLER + MONTH CARD
  /// =============================
  Widget _buildMonthScroller(ThemeData theme) {
    return SizedBox(
      height: 65,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _months.length,
        itemBuilder: (context, index) {
          final monthName = _months[index];
          final monthNumber = index + 1;
          final isSelected = monthNumber == _selectedDate.month;

          final yearString = _selectedDate.year.toString().substring(2, 4);

          return _buildMonthCard(
            theme,
            monthName,
            yearString,
            isSelected,
                () {
              print("Tapped month: $monthNumber"); // Debugging

              if (monthNumber != _selectedDate.month) {
                setState(() {
                  _selectedDate = DateTime(_selectedDate.year, monthNumber, 1);
                  _futureDashboardStats = _fetchDashboardStats(); // WAJIB!
                });
              }

            },
          );
        },
      ),
    );
  }

  /// =============================
  /// FIXED MONTH CARD (Inkwell)
  /// =============================
  Widget _buildMonthCard(
      ThemeData theme,
      String month,
      String yearSuffix,
      bool isSelected,
      VoidCallback onTap,
      ) {
    final Color selectedColor = const Color(0xFF27A843); // Selected
    final Color unselectedColor = const Color(0xFF82B43F); // Not selected

    Color cardColor = isSelected ? selectedColor : unselectedColor;
    Color monthColor = isSelected ? Colors.white : Colors.white;
    Color yearColor = isSelected ? Colors.white : Colors.white;

    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 10),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withOpacity(0.2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  month,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: monthColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  yearSuffix,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: yearColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  /// Card 2: Membangun kartu "Rekap Status Ruang Rapat" (Sebelumnya "Permintaan Tertunda")
  Widget _buildRekapStatusCard(ThemeData theme, Map<String, dynamic> statusCounts) {
    final bool isDark = theme.brightness == Brightness.dark;

    // Ambil data dari map, berikan default 0 jika null
    final int total = (statusCounts['total'] is int) ? statusCounts['total'] : (int.tryParse(statusCounts['total']?.toString() ?? '0') ?? 0);
    final int pending = (statusCounts['diproses'] is int) ? statusCounts['diproses'] : (int.tryParse(statusCounts['pending']?.toString() ?? '0') ?? 0);
    final int approved = (statusCounts['disetujui'] is int) ? statusCounts['disetujui'] : (int.tryParse(statusCounts['approved']?.toString() ?? '0') ?? 0);
    final int rejected = (statusCounts['ditolak'] is int) ? statusCounts['ditolak'] : (int.tryParse(statusCounts['rejected']?.toString() ?? '0') ?? 0);


    return Card(
      elevation: 0, // Sesuai mockup
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF82B43F),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Aksi: pindah ke tab list (Index 1)
          _onSelectItem(1, "Manajemen Aset");
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Image.asset(
                "assets/images/DigiAm/permintaan_tertunda.png",
                width: 80,
                height: 80,
                errorBuilder: (ctx, e, st) => Icon(Icons.pending_actions, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Rekap Status Ruang Rapat",
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ⭐️ Tampilkan semua data
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildRekapChip("Total", total, Colors.blue.shade100, Colors.blue.shade900),
                        _buildRekapChip("Diproses", pending, Colors.orange.shade100, Colors.orange.shade900),
                        _buildRekapChip("Disetujui", approved, Colors.green.shade100, Colors.green.shade900),
                        _buildRekapChip("Ditolak", rejected, Colors.red.shade100, Colors.red.shade900),
                      ],
                    )
                  ],
                ),
              ),
              // Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.7), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget untuk chip di card rekap
  Widget _buildRekapChip(String label, int count, Color bgColor, Color textColor) {
    return Column(
      children: [
        Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w500)
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
              count.toString(),
              style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)
          ),
        ),
      ],
    );
  }


  /// Card 3: Membangun kartu "Bar Chart" (Sekarang menerima data API langsung)
  Widget _buildUsageChartCard(ThemeData theme, List<Map<String, dynamic>> totalJamData) {
    final bool isDark = theme.brightness == Brightness.dark;

    // --- ⭐️ Logika dipindah ke sini ---
    // Konversi format API ke format yang dibutuhkan chart
    final Map<String, double> roomUsage = {
      for (var item in totalJamData.whereType<Map<String, dynamic>>())
        (item['nama_ruangan']?.toString() ?? 'Unknown') : (double.tryParse(item['total_jam']?.toString() ?? '0.0') ?? 0.0)
    };
    // --------------------------------

    double maxUsage = roomUsage.values.fold(0.0, (prev, e) => e > prev ? e : prev);
    if (maxUsage == 0.0) maxUsage = 10;

    // Ambil urutan ruangan dari _allRooms agar konsisten
    // Ambil urutan ruangan gabungan dari daftar master (_allRooms) dan data chart
    final Set<String> roomNames = {
      for (final room in _allRooms)
        if ((room['ruangan'] ?? room['nama_ruangan']) != null)
          (room['ruangan'] ?? room['nama_ruangan']).toString(),
      ...roomUsage.keys,
    };



    final List<String> roomOrder = roomNames.toList()..sort();

    List<BarChartGroupData> barGroups = [];
    int i = 0;
    for (String roomFullName in roomOrder) {
      final value = roomUsage[roomFullName] ?? 0.0;
      barGroups.add(
          _makeBarGroup(
            i,
            value,
            isDark,
          )
      );
      i++;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF333333) : Colors.grey[700],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Total Jam Pemakaian Ruang Rapat",
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white
              ),
            ),
            const SizedBox(height: 30),
            // Tampilkan pesan jika tidak ada data
            if (roomUsage.values.every((v) => v == 0.0))
              Container(
                height: 200,
                child: Center(
                  child: Text(
                    "Tidak ada data pemakaian di bulan ini.",
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxUsage * 1.2,
                    barTouchData: _buildBarTouchData(theme),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => _getBarTitles(value, meta, theme, roomOrder),
                          reservedSize: 42,
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxUsage > 0 ? maxUsage / 4 : 2,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.white.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Helper untuk data tooltip chart
  BarTouchData _buildBarTouchData(ThemeData theme) {
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        tooltipBgColor: theme.scaffoldBackgroundColor,
        tooltipBorder: BorderSide(color: theme.dividerColor),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          // Data jam murni dari API
          String jam = "${rod.toY.toStringAsFixed(1)} jam";
          return BarTooltipItem(
            'Total Pemakaian\n',
            TextStyle(color: theme.hintColor, fontSize: 10),
            children: [
              TextSpan(
                text: jam,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Helper untuk label bawah chart
  Widget _getBarTitles(double value, TitleMeta meta, ThemeData theme, List<String> roomOrder) {
    const style = TextStyle(
      color: Colors.white70,
      fontWeight: FontWeight.w500,
      fontSize: 10,
    );

    String shortLabel = "";
    if (value.toInt() >= 0 && value.toInt() < roomOrder.length) {
      final fullName = roomOrder[value.toInt()];
      // Logika pemendek nama
      if (fullName.contains("Matahari")) shortLabel = "Matahari";
      else if (fullName.contains("Gas Bumi")) shortLabel = "Gas\nBumi";
      else if (fullName.contains("Konservasi")) shortLabel = "Konservasi\nEnergi";
      else if (fullName.contains("Biomasa")) shortLabel = "Biomasa";
      else if (fullName.contains("Energi Angin")) shortLabel = "Angin";
      else if (fullName.contains("Minyak Bumi")) shortLabel = "Minyak\nBumi";
      else {
        var parts = fullName.split(" ");
        shortLabel = parts.length > 2 ? parts[2] : fullName;
      }
    }

    Widget text = Text(shortLabel, style: style, textAlign: TextAlign.center,);

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: text,
    );
  }

  /// Helper untuk membuat 1 bar group
  BarChartGroupData _makeBarGroup(int x, double y, bool isDark) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Colors.white,
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }
}
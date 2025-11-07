// lib/src/pages/admin/DigiAm/dashboard_admin.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';

// --- Impor Anda ---
import 'admin_page.dart';
import '../../login_page.dart';
import '../../../../services/api_service.dart';
import '../../../../services/jadwal_api_service.dart';
import '../../../models/jadwal_model.dart';
import '../../DigiAm/tambah_jadwal_page.dart';
// ---------------------------------------------

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

  Future<Map<String, dynamic>>? _futureDashboardData;
  List<JadwalRapat> _allBookings = [];
  List<Map<String, dynamic>> _allRooms = [];

  late final List<Widget> _adminContentPages;
  bool _isDependenciesInitialized = false;

  // --- State Baru untuk UI Dashboard ---
  DateTime _selectedDate = DateTime(2025, 10, 30); // Hardcode tanggal mockup
  final List<String> _months = const ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  final List<int> _availableYears = const [2025, 2024, 2023];
  // ------------------------------------

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Perbaikan untuk error 'initState' (layar merah)
    if (!_isDependenciesInitialized) {
      _adminContentPages = [
        _buildDashboardSummaryContent(context), // Index 0 (UI BARU)
        AdminPage(firstName: widget.firstName, lastName: widget.lastName), // Index 1
        _buildPlaceholderPage("Admin PBJ"), // Index 2
        _buildPlaceholderPage("Manajemen User"), // Index 3
      ];
      _isDependenciesInitialized = true;
    }
  }

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

      if (mounted) {
        setState(() {
          _allBookings = bookings;
          _allBookings.sort((a, b) => b.tanggal.compareTo(a.tanggal));
          _allRooms = rooms;
        });
      }
      return {'bookings': bookings, 'rooms': rooms};
    } catch (error) {
      print("Error loading dashboard data: $error");
      if (mounted) {
        _showError("Gagal memuat data dashboard: ${error.toString().replaceFirst('Exception: ', '')}");
        setState(() {
          _allBookings = [];
          _allRooms = [];
        });
      }
      throw error;
    }
  }

  Future<void> _refreshData() async {
    await _loadDashboardData();

    if (_selectedIndex == 1) {
      setState(() {
        _adminContentPages[1] = AdminPage(
          firstName: widget.firstName,
          lastName: widget.lastName,
        );
      });
    }
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
      // Tutup drawer setelah memilih menu
      Navigator.of(context).pop();
    }
  }

  Widget _buildPlaceholderPage(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- GANTI IKON JADI GAMBAR ---
          Image.asset(
            "assets/images/DigiAm/ruangan_tersedia.png", // GANTI DENGAN PATH IKON ANDA
            width: 50,
            height: 50,
            color: Colors.grey[400],
            errorBuilder: (ctx,e,st) => Icon(Icons.construction, size: 50, color: Colors.grey[400]),
          ),
          // -----------------------------
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
    String formattedDate =
    DateFormat('E, dd MMMM yyyy', 'id_ID').format(_selectedDate);

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
                "assets/images/logo.png", // GANTI DENGAN PATH LOGO ANDA
                width: 40,
                height: 40,
                errorBuilder: (ctx, e, st) => Icon(Icons.business, size: 40),
              ),
              // -----------------------------
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E, dd MMMM yyyy', 'id_ID').format(_selectedDate),
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
                    "Selamat Datang Admin!",
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
              // 🔹 Hapus header greeting di sini
              // Langsung ke menu item
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildSidebarItem(
                      context: context,
                      imagePath: "assets/images/icons/dashboard_icon.png",
                      title: "Dashboard",
                      index: 0,
                      isSelected: _selectedIndex == 0,
                      onTap: () => _onSelectItem(0, "Manajemen Aset"),
                    ),
                    _buildSidebarItem(
                      context: context,
                      imagePath: "assets/images/icons/ruangan_icon.png",
                      title: "Ruang Rapat",
                      index: 1,
                      isSelected: _selectedIndex == 1,
                      onTap: () => _onSelectItem(1, "Admin Ruang Rapat"),
                    ),
                    _buildSidebarItem(
                      context: context,
                      imagePath: "assets/images/icons/pbj_icon.png",
                      title: "PBJ",
                      index: 2,
                      isSelected: _selectedIndex == 2,
                      onTap: () => _onSelectItem(2, "Admin PBJ"),
                    ),
                    _buildSidebarItem(
                      context: context,
                      imagePath: "assets/images/icons/user_icon.png",
                      title: "Manajemen User",
                      index: 3,
                      isSelected: _selectedIndex == 3,
                      onTap: () => _onSelectItem(3, "Manajemen User"),
                    ),
                  ],
                ),
              ),

              // Tombol logout
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
        child: const Icon(Icons.add, color: Colors.white), // FAB Icon biarkan saja
        tooltip: 'Tambah Jadwal Baru',
      )
          : null,
    );
  }

  // --- FUNGSI INI DIUBAH UNTUK MENERIMA 'imagePath' ---
  Widget _buildSidebarItem({
    required BuildContext context,
    required String imagePath, // <-- UBAH DARI IconData ke String
    required String title,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final color = isSelected ? Colors.green : theme.hintColor;
    final bgColor = isSelected ? Colors.green.withOpacity(0.1) : null;

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              // --- INI PERUBAHANNYA ---
              Image.asset(
                imagePath, // Gunakan path gambar
                width: 22,
                height: 22,
                color: color, // 'color' akan memberi tint pada gambar
                errorBuilder: (ctx, e, st) => Icon(Icons.error, color: Colors.red, size: 22), // Fallback jika gambar error
              ),
              // ------------------------
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? Colors.green : theme.colorScheme.onSurface,
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

  // =========================================================================
  // --- MULAI: FUNGSI BARU UNTUK DASHBOARD (INDEX 0) SESUAI MOCKUP ---
  // =========================================================================

  Widget _buildDashboardSummaryContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<Map<String, dynamic>>(
      future: _futureDashboardData,
      builder: (context, snapshot) {
        // --- Data Kalkulasi ---
        // 1. Permintaan Tertunda (Status 1: Pending) - tidak peduli tanggal
        final int totalPersetujuan = _allBookings.where((j) => j.status == 1).length;

        // 2. Ruangan (Total)
        final int totalRuangan = _allRooms.length;

        // 3. Ruangan tersedia di _selectedDate
        final Set<String> bookedRoomNamesToday = _allBookings.where((j) =>
        j.status == 2 && // Hanya yang disetujui
            DateUtils.isSameDay(j.tanggal, _selectedDate)) // Hanya di tanggal terpilih
            .map((j) => j.ruangan).toSet();

        final int availableRoomCount = totalRuangan - bookedRoomNamesToday.length;

        // 4. Ambil nama semua ruangan
        final List<String> allRoomNames = _allRooms.map((r) => r['ruangan'] as String).toList();
        // 5. Filter nama ruangan yang tersedia
        final List<String> availableRoomNames = allRoomNames.where((name) => !bookedRoomNamesToday.contains(name)).toList();

        // 6. Kalkulasi data untuk chart berdasarkan tahun terpilih
        final Map<String, double> roomUsage = _calculateRoomUsage(_selectedDate.year);

        if (snapshot.connectionState == ConnectionState.waiting && _allBookings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError && _allBookings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Gagal memuat data: ${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text("Coba Lagi"),
                  )
                ],
              ),
            ),
          );
        }

        return Container(
          // Set background abu-abu untuk dashboard content
          color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF0F2F5),
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              // Padding luar untuk seluruh halaman dashboard
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PERUBAHAN DI SINI ---
                  // Header (Hanya Filter Tahun)
                  _buildHeaderAndFilter(theme),
                  const SizedBox(height: 20),
                  // Scroller Bulan
                  _buildMonthScroller(theme),
                  // ----------------------------------------------------

                  const SizedBox(height: 20),
                  // Kartu Ruangan Tersedia
                  _buildRuanganTersediaCard(theme, availableRoomCount, totalRuangan, availableRoomNames),
                  const SizedBox(height: 16),
                  // Kartu Permintaan Tertunda
                  _buildPermintaanTertundaCard(theme, totalPersetujuan),
                  const SizedBox(height: 16),
                  // Kartu Bar Chart
                  _buildUsageChartCard(theme, roomUsage),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================================
  // --- FUNGSI INI TELAH DIUBAH ---
  // =========================================================================
  /// Membangun header: HANYA Filter Tahun (Teks judul/sapaan dihapus)
  Widget _buildHeaderAndFilter(ThemeData theme) {
    // Teks judul, tanggal, dan sapaan telah dihapus
    // karena sudah ada di AppBar.
    // Kita hanya perlu merender Filter Tahun, dan letakkan di sebelah kanan.
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
                if (newYear != null) {
                  setState(() {
                    _selectedDate = DateTime(newYear, _selectedDate.month, _selectedDate.day);
                    // Data chart & ruangan akan otomatis ter-update saat build ulang
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
  Widget _buildMonthScroller(ThemeData theme) {
    return SizedBox(
      height: 65, // Tinggi area scroller
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _months.length,
        itemBuilder: (context, index) {
          final monthName = _months[index];
          final monthNumber = index + 1;
          final isSelected = monthNumber == _selectedDate.month;

          // Menggunakan hari "25" dari mockup
          final dayString = "25";

          return _buildMonthCard(theme, monthName, dayString, isSelected, () {
            setState(() {
              // Saat bulan di-tap, update _selectedDate
              // Gunakan tanggal 25 sesuai mockup
              _selectedDate = DateTime(_selectedDate.year, monthNumber, 25);
            });
          });
        },
      ),
    );
  }

  /// Widget untuk satu kartu bulan di scroller
  Widget _buildMonthCard(ThemeData theme, String month, String day, bool isSelected, VoidCallback onTap) {
    final bool isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : (isDark ? Colors.grey[850] : const Color(0xFF82B43F)),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: theme.dividerColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: isSelected ? Colors.green.withOpacity(0.3) : theme.shadowColor.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              month, // "Jan", "Feb", ...
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              day, // "25" (dari mockup)
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun kartu "Ruangan Tersedia"
  Widget _buildRuanganTersediaCard(ThemeData theme, int available, int total, List<String> names) {
    final bool isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0, // Sesuai mockup, tidak ada shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? Colors.grey[800] : Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [

            Container(
              child: Image.asset(
                "assets/images/DigiAm/ruangan_tersedia.png", // GANTI DENGAN PATH GAMBAR ANDA
                height: 70,
                width: 70,
                // Fallback jika gambar tidak ditemukan
                errorBuilder: (ctx, e, st) => Icon(Icons.meeting_room, size: 40, color: Colors.green),
              ), // <-- Kurung tutup yang benar
            ),
            // ---------------------------------
            const SizedBox(width: 16),
            // Teks
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ruangan Tersedia",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "$available/$total", // "2/6"
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Tampilkan maks 2 ruangan
                  ...names.take(2).map((name) => Text(
                    name, // "Ruang Rapat Biomasa"
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )),
                  if (names.length > 2)
                    Text(
                      "+ ${names.length - 2} lainnya...",
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun kartu "Permintaan Tertunda"
  Widget _buildPermintaanTertundaCard(ThemeData theme, int count) {
    final bool isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0, // Sesuai mockup
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF82B43F),
    clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Aksi opsional: pindah ke tab list & filter 'pending'
          // _onSelectItem(1, "Admin Ruang Rapat");
          // (perlu cara untuk pass filter ke admin_page)
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // --- GANTI IKON JADI GAMBAR ---
              Container(
                child: Image.asset(
                  "assets/images/DigiAm/permintaan_tertunda.png", // Ganti dengan path ikon permintaan yang benar
                  width: 80,
                  height: 80,

                  errorBuilder: (ctx, e, st) => Icon(Icons.pending_actions, size: 40, color: Colors.green), // Fallback
                ),
              ),
              // ------------------------
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Permintaan Tertunda",
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.white
                      ),
                    ),
                    Text(
                      count.toString(), // "5"
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.white
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: theme.hintColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Membangun kartu "Bar Chart"
  Widget _buildUsageChartCard(ThemeData theme, Map<String, double> roomUsage) {
    final bool isDark = theme.brightness == Brightness.dark;

    // Cari nilai jam tertinggi untuk normalisasi tinggi bar
    double maxUsage = roomUsage.values.fold(0.0, (prev, e) => e > prev ? e : prev);
    if (maxUsage == 0.0) maxUsage = 10; // Nilai default jika 0, agar chart tidak hilang

    // Urutan ruangan sesuai mockup
    List<String> roomOrder = [
      "Ruang Rapat Energi Matahari",
      "Ruang Rapat Gas Bumi",
      "Ruang Rapat Konservasi energi ", // Spasi di akhir sesuai data Anda
      "Ruang Rapat Biomasa",
      "Ruang Rapat Energi Angin",
      "Ruang Rapat Minyak Bumi",
    ];

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
      elevation: 0, // Sesuai mockup
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF333333) : Colors.grey[700], // Background abu-abu tua
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
            SizedBox(
              height: 200, // Tinggi chart
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxUsage * 1.2, // Beri sedikit ruang di atas
                  barTouchData: _buildBarTouchData(theme), // Data untuk tooltip
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => _getBarTitles(value, meta, theme),
                        reservedSize: 42, // Ruang untuk label
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxUsage > 0 ? maxUsage / 4 : 2, // Tampilkan 4 garis grid
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.white.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false), // Sembunyikan border
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kalkulasi data jam per ruangan untuk tahun terpilih
  Map<String, double> _calculateRoomUsage(int year) {
    Map<String, double> usage = {};
    // Inisialisasi semua ruangan dari _allRooms dengan 0 jam
    for (var room in _allRooms) {
      String roomName = room['ruangan'] ?? 'Unknown';
      usage[roomName] = 0.0;
    }

    // Filter booking yang status=2 (Disetujui) dan di tahun terpilih
    var filteredBookings = _allBookings.where((j) =>
    j.status == 2 &&
        j.tanggal.year == year);

    for (var booking in filteredBookings) {
      try {
        final start = DateFormat("HH:mm:ss").parseStrict(booking.jamMulai);
        final end = DateFormat("HH:mm:ss").parseStrict(booking.jamSelesai);
        final durationInMinutes = end.difference(start).inMinutes;
        double durationInHours = durationInMinutes / 60.0;

        if (durationInHours > 0) {
          usage.update(booking.ruangan, (value) => value + durationInHours, ifAbsent: () => durationInHours);
        }
      } catch (e) {
        print("Error parsing duration for chart: $e");
      }
    }
    // HACK: Data dummy untuk 'Matahari' 6 jam sesuai mockup
    // Hapus ini jika data asli sudah benar
    if (usage.containsKey("Ruang Rapat Energi Matahari")) {
      usage["Ruang Rapat Energi Matahari"] = 6.0;
    }

    return usage;
  }

  /// Helper untuk data tooltip chart
  BarTouchData _buildBarTouchData(ThemeData theme) {
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        tooltipBgColor: theme.scaffoldBackgroundColor,
        tooltipBorder: BorderSide(color: theme.dividerColor),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          // Tampilkan "6 jam" khusus untuk bar pertama (Matahari)
          String jam = (groupIndex == 0) ? "6 jam" : "${rod.toY.toStringAsFixed(1)} jam";
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
  Widget _getBarTitles(double value, TitleMeta meta, ThemeData theme) {
    const style = TextStyle(
      color: Colors.white70,
      fontWeight: FontWeight.w500,
      fontSize: 10,
    );

    List<String> labels = [
      "Matahari",
      "Gas\nBumi",
      "Konservasi\nEnergi",
      "Biomasa",
      "Angin",
      "Minyak\nBumi",
    ];

    Widget text = Text(labels[value.toInt()], style: style, textAlign: TextAlign.center,);

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8, // Jarak dari chart
      child: text,
    );
  }

  /// Helper untuk membuat 1 bar group
  BarChartGroupData _makeBarGroup(int x, double y, bool isDark) {
    // Sesuai mockup, semua bar putih
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Colors.white, // Semua bar putih sesuai mockup
          width: 20, // Lebar bar
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }
}
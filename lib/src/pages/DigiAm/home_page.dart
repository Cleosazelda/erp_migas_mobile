import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'jadwal_table.dart';
import 'tambah_jadwal_page.dart';
import '../../../services/jadwal_api_service.dart';
import '../../../src/models/jadwal_model.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../home_page.dart';

class DigiAmHomePage extends StatefulWidget {
  final String firstName;
  final String lastName;

  const DigiAmHomePage({
    super.key,
    required this.firstName,
    required this.lastName,
  });

  @override
  State<DigiAmHomePage> createState() => _DigiAmHomePageState();
}

class _DigiAmHomePageState extends State<DigiAmHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();
  late Future<List<JadwalRapat>> _futureJadwal;

  // --- TAMBAHAN UNTUK SEARCH ---
  List<JadwalRapat> _allBookings = []; // Menyimpan semua data dari API
  List<JadwalRapat> _filteredBookings = []; // Data yang sudah difilter (oleh user & search)
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedFilterChip;
  // --- AKHIR TAMBAHAN ---

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    initializeDateFormatting('id_ID', null).then((_) {
      if (mounted) {
        _loadJadwalAndInitializeFilter(); // Memuat data dan menerapkan filter awal
      }
    });
    // Tambahkan listener untuk search controller
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged); // Hapus listener
    _searchController.dispose(); // Hapus controller
    super.dispose();
  }

  // --- FUNGSI BARU: Memuat data dan filter ---
  void _loadJadwalAndInitializeFilter() {
    if (!mounted) return;
    setState(() {
      _futureJadwal = JadwalApiService.getAllJadwal().then((bookings) {
        if (mounted) {
          _allBookings = bookings; // Simpan data lengkap
          _applyFilters(); // Terapkan filter (awal)
        }
        return bookings; // Kembalikan untuk FutureBuilder
      }).catchError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Gagal memuat data: ${error.toString()}"),
            backgroundColor: Colors.red,
          ));
        }
        throw error; // Biarkan FutureBuilder menangani error
      });
    });
  }

  // --- MODIFIKASI: _reloadData ---
  void _reloadData() {
    // Muat ulang data dan filter
    _loadJadwalAndInitializeFilter();
  }

  // --- FUNGSI BARU: Listener perubahan search ---
  void _onSearchChanged() {
    if (_searchQuery != _searchController.text) {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
          _applyFilters(); // Terapkan filter setiap kali teks berubah
        });
      }
    }
  }

  // --- FUNGSI BARU: Menerapkan filter (user & search) ---
  void _applyFilters() {
    if (!mounted) return;

    final String currentUser = "${widget.firstName} ${widget.lastName}";

    // 1. Filter berdasarkan PIC (user saat ini)
    List<JadwalRapat> tempFiltered = _allBookings
        .where((jadwal) => jadwal.pic == currentUser)
        .toList();

    // 2. Filter berdasarkan search query
    if (_searchQuery.isNotEmpty) {
      String queryLower = _searchQuery.toLowerCase();
      tempFiltered = tempFiltered.where((jadwal) {
        // Cari di agenda, ruangan, divisi, atau perusahaan
        return (jadwal.agenda.toLowerCase().contains(queryLower)) ||
            (jadwal.ruangan.toLowerCase().contains(queryLower)) ||
            (jadwal.divisi.toLowerCase().contains(queryLower)) ||
            (jadwal.perusahaan.toLowerCase().contains(queryLower));
      }).toList();
    }

    // 3. Filter berdasarkan chip yang dipilih (status/ruangan)
    if (_selectedFilterChip != null) {
      switch (_selectedFilterChip) {
        case 'Pending':
          tempFiltered = tempFiltered.where((j) => j.status == 1).toList();
          break;
        case 'Disetujui':
          tempFiltered = tempFiltered.where((j) => j.status == 2).toList();
          break;
        case 'Ditolak':
          tempFiltered = tempFiltered.where((j) => j.status == 3).toList();
          break;
        case 'Energi Matahari':
          tempFiltered =
              tempFiltered.where((j) => j.ruangan == 'Ruang Rapat Energi Matahari').toList();
          break;
        case 'Gas Bumi':
          tempFiltered = tempFiltered.where((j) => j.ruangan == 'Ruang Rapat Gas Bumi').toList();
          break;
        case 'Konservasi Energi':
          tempFiltered = tempFiltered
              .where((j) => j.ruangan == 'Ruang Rapat Konservasi energi ')
              .toList();
          break;
        case 'Biomasa':
          tempFiltered = tempFiltered.where((j) => j.ruangan == 'Ruang Rapat Biomasa').toList();
          break;
        case 'Energi Angin':
          tempFiltered = tempFiltered.where((j) => j.ruangan == 'Ruang Rapat Energi Angin').toList();
          break;
        case 'Minyak Bumi':
          tempFiltered = tempFiltered.where((j) => j.ruangan == 'Ruang Rapat Minyak Bumi').toList();
          break;
      }
    }

    // 4. Urutkan (misalnya, terbaru dulu)
    tempFiltered.sort((a, b) => b.tanggal.compareTo(a.tanggal));

    setState(() {
      _filteredBookings = tempFiltered;
    });
  }


  void _onDateChanged(DateTime newDate) {
    setState(() {
      selectedDate = newDate;
      // Note: Filter di _buildRuangRapatTab akan otomatis terupdate
    });
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: Colors.green,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _onDateChanged(picked);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Builder(builder: (context) => _buildAppBar(context)),
      ),
      drawer: _buildDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRuangRapatTab(),
          _buildListPeminjamanTab(), // Tab ini sekarang punya search
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openTambahJadwal,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    // ... (Fungsi _buildAppBar tidak berubah)
    final fullName = "${widget.firstName} ${widget.lastName}";
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      title: Row(
        children: [
          Image.asset("assets/images/logo.png", height: 30),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Manajemen Aset", style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
              Text("Welcome $fullName!", style: TextStyle(fontSize: 12, color: theme.hintColor)),
            ],
          ),
        ],
      ),
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
          onPressed: _reloadData,
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.green,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.green,
        tabs: const [ Tab(text: "Ruang Rapat"), Tab(text: "List Peminjaman") ],
      ),
    );
  }

  Drawer _buildDrawer() {
    // ... (Fungsi _buildDrawer tidak berubah)
    final fullName = "${widget.firstName} ${widget.lastName}";
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text("Selamat Datang"),
            accountEmail: Text(fullName),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.grey, size: 40),
            ),
            decoration: const BoxDecoration(color: Colors.green),
          ),
          _drawerItem(
            Icons.apps_sharp,
            "Layanan Umum",
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
          _drawerItem(
            Icons.meeting_room,
            "Ruang Rapat",
            isSelected: true,
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(0);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRuangRapatTab() {
    // ... (Fungsi _buildRuangRapatTab tidak berubah)
    //     (Dia sudah menggunakan _futureJadwal dan `selectedDate`)
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: FutureBuilder<List<JadwalRapat>>(
              future: _futureJadwal,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                final semuaJadwal = snapshot.data ?? [];

                final jadwalTampil = semuaJadwal.where((jadwal) {
                  return jadwal.status == 2 && DateUtils.isSameDay(jadwal.tanggal, selectedDate);
                }).toList();

                if (jadwalTampil.isEmpty) {
                  return Center(
                    child: Text(
                      "Tidak ada jadwal disetujui untuk tanggal ini.",
                      style: TextStyle(color: Theme.of(context).hintColor, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return JadwalTable(jadwalList: jadwalTampil);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    // ... (Fungsi _buildDateSelector tidak berubah)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? Colors.grey[900] : Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _dateButton("< Prev", () => _onDateChanged(selectedDate.subtract(const Duration(days: 1))))),
              const SizedBox(width: 10),
              Expanded(child: _dateButton("Today", () => _onDateChanged(DateTime.now()))),
              const SizedBox(width: 10),
              Expanded(child: _dateButton("Next >", () => _onDateChanged(selectedDate.add(const Duration(days: 1))))),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            readOnly: true,
            onTap: _pickDate,
            controller: TextEditingController(text: _formatDate(selectedDate)),
            decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: const Icon(Icons.calendar_today)
            ),
          ),
        ],
      ),
    );
  }

  void _openTambahJadwal() async {
    // ... (Fungsi _openTambahJadwal tidak berubah)
    final result = await showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: TambahJadwalPage(namaPengguna: "${widget.firstName} ${widget.lastName}"),
      ),
    );
    if (result == true) {
      _reloadData();
    }
  }

  ListTile _drawerItem(IconData icon, String title, {bool isSelected = false, VoidCallback? onTap}) {
    // ... (Fungsi _drawerItem tidak berubah)
    final theme = Theme.of(context);
    final color = isSelected ? Colors.green : theme.colorScheme.onSurface;

    return ListTile(
      title: Text(title, style: TextStyle(color: color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      leading: Icon(icon, color: isSelected ? Colors.green : Colors.grey.shade600),
      tileColor: isSelected ? Colors.green.shade50 : null,
      onTap: onTap,
    );
  }

  ElevatedButton _dateButton(String label, VoidCallback onPressed) {
    // ... (Fungsi _dateButton tidak berubah)
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label),
    );
  }

  // --- MODIFIKASI BESAR: _buildListPeminjamanTab ---
  Widget _buildListPeminjamanTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
          children: [
      // --- Search Bar (diambil dari admin_page) ---
      Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Cari agenda, ruangan, divisi...',
                    hintStyle: TextStyle(color: theme.hintColor.withOpacity(0.7), fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: theme.hintColor, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? Colors.grey[700]?.withOpacity(0.5) : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: theme.hintColor, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur filter lanjutan belum diimplementasikan.')),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.filter_list,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(label: 'Pending', value: 'Pending', theme: theme),
                _buildFilterChip(label: 'Disetujui', value: 'Disetujui', theme: theme),
                _buildFilterChip(label: 'Ditolak', value: 'Ditolak', theme: theme),
                _buildFilterChip(label: 'Energi Matahari', value: 'Energi Matahari', theme: theme),
                _buildFilterChip(label: 'Gas Bumi', value: 'Gas Bumi', theme: theme),
                _buildFilterChip(label: 'Konservasi Energi', value: 'Konservasi Energi', theme: theme),
                _buildFilterChip(label: 'Biomasa', value: 'Biomasa', theme: theme),
                _buildFilterChip(label: 'Energi Angin', value: 'Energi Angin', theme: theme),
                _buildFilterChip(label: 'Minyak Bumi', value: 'Minyak Bumi', theme: theme),
              ],
            ),
          ),
        ],
                ),

              ),

          Divider(height: 1, thickness: 1, color: theme.dividerColor.withOpacity(0.1)),

          // --- List Peminjaman (Sekarang menggunakan _filteredBookings) ---
          Expanded(
            child: FutureBuilder<List<JadwalRapat>>(
                future: _futureJadwal, // Tetap gunakan future untuk loading/error
                builder: (context, snapshot) {
                  // Tampilkan loading HANYA saat data awal sedang dimuat
                  if (snapshot.connectionState == ConnectionState.waiting && _allBookings.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Tampilkan error HANYA jika data awal gagal dimuat
                  if (snapshot.hasError && _allBookings.isEmpty) {
                    return Center(child: Text("Gagal memuat data peminjaman: ${snapshot.error}"));
                  }

                  // Jika data sudah ada (dari snapshot atau state), cek list yg sudah difilter
                  if (_filteredBookings.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? "Tidak ada jadwal yang cocok."
                            : "Anda belum memiliki riwayat peminjaman.",
                        style: TextStyle(color: theme.hintColor, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  // Tampilkan list berdasarkan _filteredBookings
                  return RefreshIndicator(
                    onRefresh: () async => _reloadData(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredBookings.length, // Gunakan list yg sudah difilter
                      itemBuilder: (context, index) {
                        final jadwal = _filteredBookings[index]; // Gunakan list yg sudah difilter
                        return _meetingCard(jadwal);
                      },
                    ),
                  );
                }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required String value, required ThemeData theme}) {
    final bool isSelected = _selectedFilterChip == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: FilterChip(
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withOpacity(0.8),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _selectedFilterChip = selected ? value : null;
            _applyFilters();
          });
        },
        selectedColor: theme.colorScheme.primary.withOpacity(0.8),
        checkmarkColor: theme.colorScheme.onPrimary,
        backgroundColor: theme.chipTheme.backgroundColor ?? theme.cardColor,
        side: isSelected ? BorderSide.none : BorderSide(color: theme.dividerColor.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        visualDensity: const VisualDensity(horizontal: 0.0, vertical: -2),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
      ),
    );
  }

  Widget _meetingCard(JadwalRapat jadwal) {
    // ... (Fungsi _meetingCard tidak berubah)
    final time = "${jadwal.jamMulai.substring(0, 5)} - ${jadwal.jamSelesai.substring(0, 5)}";
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    jadwal.ruangan,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: jadwal.status == 2 ? Colors.green : (jadwal.status == 1 ? Colors.orange : Colors.red),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                      jadwal.status == 2 ? 'DISETUJUI' : (jadwal.status == 1 ? 'PENDING' : 'DITOLAK'),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: theme.hintColor),
                const SizedBox(width: 8),
                Text("${DateFormat('dd/MM/yyyy').format(jadwal.tanggal)} | $time", style: TextStyle(color: theme.hintColor, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            Text(jadwal.agenda, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text("${jadwal.jumlahPeserta} Org", style: TextStyle(color: theme.hintColor, fontSize: 14)),
            const SizedBox(height: 4),
            Text("Peminjam: ${jadwal.pic}", style: TextStyle(color: theme.hintColor, fontSize: 14)),
            Text(jadwal.divisi, style: TextStyle(color: theme.hintColor, fontSize: 14)),
            Text(jadwal.perusahaan, style: TextStyle(color: theme.hintColor, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
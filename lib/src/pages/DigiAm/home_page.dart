import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'jadwal_table.dart';
import 'tambah_jadwal_page.dart';
import '../../../services/jadwal_api_service.dart';
import '../../../src/models/jadwal_model.dart';
import 'package:intl/date_symbol_data_local.dart';


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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _futureJadwal = JadwalApiService.getAllJadwal();
    initializeDateFormatting('id_ID', null);
  }

  void _reloadData() {
    setState(() {
      _futureJadwal = JadwalApiService.getAllJadwal();
    });
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      selectedDate = newDate;
    });
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      // --- PENYESUAIAN TEMA ---
      // Builder untuk menyesuaikan tema DatePicker
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: Colors.green, // Header background
              onPrimary: Colors.white, // Header text
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
          _buildListPeminjamanTab(),
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
    final fullName = "${widget.firstName} ${widget.lastName}";
    // --- PENYESUAIAN TEMA ---
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
      // --- PENYESUAIAN TEMA ---
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
          _drawerItem(Icons.apps_sharp, "Layanan Umum"),
          _drawerItem(Icons.meeting_room, "Ruang Rapat", isSelected: true),
        ],
      ),
    );
  }

  Widget _buildRuangRapatTab() {
    return Container(
      // --- PENYESUAIAN TEMA ---
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

                return JadwalTable(jadwalList: jadwalTampil);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    // --- PENYESUAIAN TEMA ---
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

  ListTile _drawerItem(IconData icon, String title, {bool isSelected = false}) {
    // --- PENYESUAIAN TEMA ---
    final theme = Theme.of(context);
    final color = isSelected ? Colors.green : theme.colorScheme.onSurface;

    return ListTile(
      title: Text(title, style: TextStyle(color: color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      leading: Icon(icon, color: isSelected ? Colors.green : Colors.grey.shade600),
      tileColor: isSelected ? Colors.green.shade50 : null,
      onTap: () {},
    );
  }

  ElevatedButton _dateButton(String label, VoidCallback onPressed) {
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

  Widget _buildListPeminjamanTab() {
    final String currentUser = "${widget.firstName} ${widget.lastName}";

    return FutureBuilder<List<JadwalRapat>>(
        future: _futureJadwal,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Gagal memuat data peminjaman."));
          }

          final semuaJadwal = snapshot.data!;
          final jadwalMilikUser = semuaJadwal.where((jadwal) => jadwal.pic == currentUser).toList();

          if (jadwalMilikUser.isEmpty) {
            return const Center(child: Text("Anda belum memiliki riwayat peminjaman."));
          }

          return Container(
            // --- PENYESUAIAN TEMA ---
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jadwalMilikUser.length,
              itemBuilder: (context, index) {
                final jadwal = jadwalMilikUser[index];
                return _meetingCard(jadwal);
              },
            ),
          );
        }
    );
  }

  Widget _meetingCard(JadwalRapat jadwal) {
    final time = "${jadwal.jamMulai.substring(0, 5)} - ${jadwal.jamSelesai.substring(0, 5)}";
    // --- PENYESUAIAN TEMA ---
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      // Card color diatur oleh tema utama, jadi tidak perlu diubah
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
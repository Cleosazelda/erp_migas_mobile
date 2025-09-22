import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'jadwal_table.dart';
import 'tambah_jadwal_page.dart';

class DigiAmHomePage extends StatefulWidget {
  const DigiAmHomePage({super.key});

  @override
  State<DigiAmHomePage> createState() => _DigiAmHomePageState();
}

class _DigiAmHomePageState extends State<DigiAmHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();

  // "Database" dummy yang berisi SEMUA jadwal.
  final List<Map<String, dynamic>> _allBookings = [
    // Data untuk tanggal 3 September 2025
    {
      'room': 'RR Matahari', 'date': DateTime(2025, 9, 3), 'start': "09:30", 'end': "11:30",
      'title': 'Koordinasi Tim Center of Investment - Pembahasan Potensi Investasi dan Proyek IT, Tambang, Gas',
      'participants': 20, 'company': 'MUJ - Strategi dan Pengembangan Bisnis', 'pic': 'Khoiru Arfan', 'status': 'DISETUJUI'
    },
    {
      'room': 'RR Matahari', 'date': DateTime(2025, 9, 3), 'start': "14:00", 'end': "15:30",
      'title': 'Rapat Evaluasi Kinerja', 'participants': 10, 'company': 'MUJ - HR', 'pic': 'Citra Lestari', 'status': 'DISETUJUI'
    },
    // Data untuk tanggal 4 September 2025
    {
      'room': 'RR Minyak Bumi', 'date': DateTime(2025, 9, 4), 'start': "10:00", 'end': "11:00",
      'title': 'Presentasi Project Alpha', 'participants': 8, 'company': 'ENM - Operasi', 'pic': 'Rian Hidayat', 'status': 'DISETUJUI'
    },
    {
      'room': 'RR Angin', 'date': DateTime(2025, 9, 4), 'start': "08:00", 'end': "10:00",
      'title': 'Meeting Pagi Tim Operasional', 'participants': 12, 'company': 'MUJ - Operasi', 'pic': 'Budi Santoso', 'status': 'DISETUJUI'
    },
  ];

  // State untuk menampung jadwal yang SUDAH DIFILTER berdasarkan tanggal.
  List<Map<String, dynamic>> _bookingsForSelectedDate = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    selectedDate = DateTime(2025, 9, 3);
    // Saat halaman pertama kali dimuat, langsung filter dan tampilkan jadwal untuk tanggal awal.
    _loadScheduleForDate(selectedDate);
  }

  // Fungsi untuk memfilter jadwal dari database berdasarkan tanggal yang dipilih.
  void _loadScheduleForDate(DateTime date) {
    setState(() {
      _bookingsForSelectedDate = _allBookings.where((booking) {
        final bookingDate = booking['date'] as DateTime;
        return bookingDate.year == date.year &&
            bookingDate.month == date.month &&
            bookingDate.day == date.day;
      }).toList();
    });
  }

  // Fungsi ini akan dipanggil setiap kali tanggal berubah.
  void _onDateChanged(DateTime newDate) {
    setState(() {
      selectedDate = newDate;
    });
    _loadScheduleForDate(newDate); // Panggil filter setiap tanggal berubah
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      _onDateChanged(picked);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, dd MMMM', 'id_ID').format(date);
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
    return AppBar(
      title: Row(
        children: [
          Image.asset("assets/images/logo.png", height: 30),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Manajemen Aset", style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
              Text("Welcome User!", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.green,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.green,
        tabs: const [ Tab(text: "Ruang Rapat"), Tab(text: "List Peminjaman") ],
      ),
    );
  }

  Widget _buildRuangRapatTab() {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          _buildDateSelector(),
          // Kirim data yang sudah difilter ke JadwalTable
          Expanded(child: JadwalTable(bookings: _bookingsForSelectedDate)),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      color: Colors.white,
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
          DropdownButtonFormField<String>(
            value: _formatDate(selectedDate),
            onTap: _pickDate,
            items: [ DropdownMenuItem(value: _formatDate(selectedDate), child: Text(_formatDate(selectedDate), style: const TextStyle(fontSize: 16))) ],
            onChanged: (value) {},
            decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))
            ),
          ),
        ],
      ),
    );
  }

  void _openTambahJadwal() {
    showDialog(
      context: context,
      builder: (context) => const Dialog(
        insetPadding: EdgeInsets.all(16),
        child: TambahJadwalPage(),
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text("Selamat Datang"),
            accountEmail: Text("User"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.grey, size: 40),
            ),
            decoration: BoxDecoration(
              color: Colors.green,
            ),
          ),
          _drawerItem(Icons.apps_sharp, "Layanan Umum"),
          _drawerItem(Icons.meeting_room, "Ruang Rapat", isSelected: true),
        ],
      ),
    );
  }

  ListTile _drawerItem(IconData icon, String title, {bool isSelected = false}) {
    return ListTile(
      title: Text(title, style: TextStyle(color: isSelected ? Colors.green : Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
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
    return Container(
      color: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allBookings.length,
        itemBuilder: (context, index) {
          final meeting = _allBookings[index];
          return _meetingCard(meeting);
        },
      ),
    );
  }

  Widget _meetingCard(Map<String, dynamic> meeting) {
    final date = meeting['date'] as DateTime;
    final time = "${meeting['start']} - ${meeting['end']}";

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
                Text( meeting['room'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green) ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: meeting['status'] == 'DISETUJUI' ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text( meeting['status'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold) ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text( "${DateFormat('dd/MM/yyyy').format(date)} | $time", style: TextStyle(color: Colors.grey.shade600, fontSize: 14) ),
              ],
            ),
            const SizedBox(height: 12),
            Text(meeting['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(meeting['company'], style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 4),
            Row(

              children: [
                Text("PIC: ${meeting['pic']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                const SizedBox(width: 16),
                Text("Peserta: ${meeting['participants']} orang", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
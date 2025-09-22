import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../login_page.dart';

// CustomCard Widget
class CustomCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData? icon;

  const CustomCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Container(
        width: 160,
        height: 100,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (icon != null)
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color),
              ),
            if (icon != null) const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  // Data dari API
  List<Map<String, dynamic>> users = [];
  List<String> divisiList = [];
  Map<String, dynamic> dashboardStats = {};

  bool isLoading = true;

  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController jabatanController = TextEditingController();
  final TextEditingController divisiController = TextEditingController();
  String? selectedDivisi;

  late TabController _tabController;
  int currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        currentTabIndex = _tabController.index;
      });
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    namaController.dispose();
    emailController.dispose();
    passwordController.dispose();
    jabatanController.dispose();
    divisiController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);

      final results = await Future.wait([
        ApiService.getUsers(),
        ApiService.getDivisions(),
        ApiService.getDashboardStats(),
      ]);

      setState(() {
        users = results[0] as List<Map<String, dynamic>>;
        divisiList = results[1] as List<String>;
        dashboardStats = results[2] as Map<String, dynamic>;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError("Gagal memuat data: $e");
    }
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
        await ApiService.logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          _showError("Gagal logout: $e");
        }
      }
    }
  }

  Future<void> addUser() async {
    if (namaController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        selectedDivisi == null ||
        jabatanController.text.isEmpty) {
      _showError("Semua field harus diisi");
      return;
    }

    try {
      final response = await ApiService.addUser(
        nama: namaController.text,
        email: emailController.text,
        password: passwordController.text,
        jabatan: jabatanController.text,
        divisi: selectedDivisi!,
      );

      if (response['status'] == 'success') {
        _showSuccess("User berhasil ditambahkan");
        _clearUserForm();
        Navigator.pop(context);
        _loadData(); // Reload data
      } else {
        _showError(response['message'] ?? "Gagal menambah user");
      }
    } catch (e) {
      _showError("Error: $e");
    }
  }

  Future<void> addDivisi() async {
    if (divisiController.text.isEmpty) {
      _showError("Nama divisi harus diisi");
      return;
    }

    try {
      final response = await ApiService.addDivision(divisiController.text);

      if (response['status'] == 'success') {
        _showSuccess("Divisi berhasil ditambahkan");
        divisiController.clear();
        Navigator.pop(context);
        _loadData(); // Reload data
      } else {
        _showError(response['message'] ?? "Gagal menambah divisi");
      }
    } catch (e) {
      _showError("Error: $e");
    }
  }

  Future<void> deleteUser(int userId, String nama) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus user "$nama"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        final response = await ApiService.deleteUser(userId);
        if (response['status'] == 'success') {
          _showSuccess("User berhasil dihapus");
          _loadData();
        } else {
          _showError(response['message'] ?? "Gagal menghapus user");
        }
      } catch (e) {
        _showError("Error: $e");
      }
    }
  }

  void _clearUserForm() {
    namaController.clear();
    emailController.clear();
    passwordController.clear();
    jabatanController.clear();
    selectedDivisi = null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void showAddDialog() {
    if (currentTabIndex == 0) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Tambah User"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: namaController,
                  decoration: const InputDecoration(labelText: "Nama"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedDivisi,
                  hint: const Text("Pilih Divisi"),
                  onChanged: (val) {
                    setState(() {
                      selectedDivisi = val;
                    });
                  },
                  items: divisiList
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: jabatanController,
                  decoration: const InputDecoration(labelText: "Jabatan"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearUserForm();
                Navigator.pop(context);
              },
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: addUser,
              child: const Text("Simpan", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Tambah Divisi"),
          content: TextField(
            controller: divisiController,
            decoration: const InputDecoration(labelText: "Nama Divisi"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                divisiController.clear();
                Navigator.pop(context);
              },
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: addDivisi,
              child: const Text("Simpan", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    int totalUser = dashboardStats['totalUsers'] ?? users.length;
    int totalDivisi = dashboardStats['totalDivisions'] ?? divisiList.length;

    Map<String, int> divisiCount = {};
    for (var d in divisiList) {
      divisiCount[d] = users.where((u) => u["divisi"] == d).length;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Admin Dashboard", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Pengguna"),
            Tab(text: "Divisi"),
          ],
          labelColor: Colors.black,
          indicatorColor: Colors.blueAccent,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Scrollable Card Atas
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CustomCard(
                    title: "Karyawan",
                    value: totalUser.toString(),
                    color: Colors.redAccent,
                    icon: Icons.people,
                  ),
                  const SizedBox(width: 16),
                  CustomCard(
                    title: "Divisi",
                    value: totalDivisi.toString(),
                    color: Colors.blueGrey,
                    icon: Icons.apartment,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card utama untuk TabView
            Expanded(
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Judul + tombol
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currentTabIndex == 0 ? "Data Pengguna" : "Data Divisi",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              currentTabIndex == 0 ? Colors.blue : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: showAddDialog,
                            child: Text(currentTabIndex == 0 ? "+ INPUT" : "+ TAMBAH DIVISI"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // TabView
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Tab Pengguna
                            users.isEmpty
                                ? const Center(child: Text("Tidak ada data user"))
                                : ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (_, index) {
                                final user = users[index];
                                return Card(
                                  color: Colors.white,
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                      Colors.blueAccent.withOpacity(0.2),
                                      child: const Icon(Icons.person,
                                          color: Colors.blueAccent),
                                    ),
                                    title: Text(user["nama"] ?? "Unknown"),
                                    subtitle: Text(
                                        "${user["jabatan"] ?? "-"} - ${user["divisi"] ?? "-"}"),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'delete') {
                                          deleteUser(
                                            user['id'] ?? 0,
                                            user['nama'] ?? 'Unknown',
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Hapus'),
                                        ),
                                      ],
                                      icon: const Icon(Icons.more_vert),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Tab Divisi
                            divisiList.isEmpty
                                ? const Center(child: Text("Tidak ada data divisi"))
                                : ListView(
                              children: divisiCount.entries.map((e) {
                                return Card(
                                  color: Colors.grey[50],
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    title: Text(e.key),
                                    subtitle: Text("${e.value} karyawan"),
                                    trailing: Text(
                                      e.value.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
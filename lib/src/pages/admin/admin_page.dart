import 'package:flutter/material.dart';

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
  // Dummy data user
  List<Map<String, dynamic>> users = [
    {"nama": "Andi", "email": "andi@muj.co.id", "divisi": "Finance", "jabatan": "Staff"},
    {"nama": "Budi", "email": "budi@muj.co.id", "divisi": "IT", "jabatan": "Manager"},
    {"nama": "Citra", "email": "citra@muj.co.id", "divisi": "HR", "jabatan": "Staff"},
    {"nama": "Dewi", "email": "dewi@muj.co.id", "divisi": "Operasional", "jabatan": "Staff"},
    {"nama": "Eka", "email": "eka@muj.co.id", "divisi": "Finance", "jabatan": "Staff"},
  ];

  List<String> divisiList = ["Finance", "IT", "HR", "Operasional"];

  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
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
  }

  void addUser() {
    if (namaController.text.isEmpty ||
        emailController.text.isEmpty ||
        selectedDivisi == null ||
        jabatanController.text.isEmpty) return;

    setState(() {
      users.add({
        "nama": namaController.text,
        "email": emailController.text,
        "divisi": selectedDivisi!,
        "jabatan": jabatanController.text,
      });
    });

    namaController.clear();
    emailController.clear();
    jabatanController.clear();
    selectedDivisi = null;
    Navigator.pop(context);
  }

  void addDivisi() {
    if (divisiController.text.isEmpty) return;

    setState(() {
      divisiList.add(divisiController.text);
    });

    divisiController.clear();
    Navigator.pop(context);
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
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
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
                TextField(
                  controller: jabatanController,
                  decoration: const InputDecoration(labelText: "Jabatan"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: addUser,
              child: const Text("Simpan"),
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: addDivisi,
              child: const Text("Simpan"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalUser = users.length;
    int totalDivisi = divisiList.length;

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
                            ListView.builder(
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
                                    title: Text(user["nama"]),
                                    subtitle:
                                    Text("${user["jabatan"]} - ${user["divisi"]}"),
                                    trailing:
                                    const Icon(Icons.arrow_forward_ios, size: 16),
                                  ),
                                );
                              },
                            ),

                            // Tab Divisi
                            ListView(
                              children: divisiCount.entries.map((e) {
                                return Card(
                                  color: Colors.grey[50],
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    title: Text(e.key),
                                    trailing: Text(e.value.toString()),
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

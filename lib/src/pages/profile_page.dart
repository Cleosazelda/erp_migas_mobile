import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;

  final TextEditingController firstNameController = TextEditingController(text: "Hadi");
  final TextEditingController lastNameController = TextEditingController(text: "Ramdani");
  final TextEditingController emailController = TextEditingController(text: "hadiramdani2@gmail.com");
  final TextEditingController jabatanController = TextEditingController(text: "Staff IT");
  final TextEditingController divisiController = TextEditingController(text: "Teknologi Informasi");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // UI lainnya tidak perlu diubah, hanya datanya yang statis
            if (!isEditing) ...[
              Text(
                "${firstNameController.text} ${lastNameController.text}",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(emailController.text, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 30),
              _buildInfoCard(context, icon: Icons.badge, title: "Jabatan", subtitle: jabatanController.text),
              const SizedBox(height: 12),
              _buildInfoCard(context, icon: Icons.business, title: "Divisi", subtitle: divisiController.text),
            ] else ...[
              const SizedBox(height: 20),
              _buildEditField("Nama Depan", firstNameController),
              const SizedBox(height: 16),
              _buildEditField("Nama Belakang", lastNameController),
              const SizedBox(height: 16),
              _buildEditField("Email", emailController),
              const SizedBox(height: 16),
              _buildEditField("Jabatan", jabatanController, isEnabled: false),
              const SizedBox(height: 16),
              _buildEditField("Divisi", divisiController, isEnabled: false),
              const SizedBox(height: 30),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => setState(() => isEditing = false), child: const Text("Batal"))),
                const SizedBox(width: 16),
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () { /* Logika update profile */ },
                  child: const Text("Simpan"),
                )),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {bool isEnabled = true}) { return TextFormField(); }
  Widget _buildInfoCard(BuildContext context, {required IconData icon, required String title, required String subtitle}) { return Card(); }
}
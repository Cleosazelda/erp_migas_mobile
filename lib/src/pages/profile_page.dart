import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _imageFile;
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  bool isEditing = false;

  // UPDATE: Pisahkan controller untuk first name dan last name
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController jabatanController = TextEditingController();
  final TextEditingController divisiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    jabatanController.dispose();
    divisiController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      if (!mounted) return;
      setState(() => isLoading = true);
      final profile = await ApiService.getProfile();

      if (mounted && profile['status'] == 'success') {
        setState(() {
          userProfile = profile['user'];
          firstNameController.text = userProfile!['first_name'] ?? '';
          lastNameController.text = userProfile!['last_name'] ?? '';
          emailController.text = userProfile!['email'] ?? '';

          jabatanController.text = userProfile!['jabatan'] ?? 'Data tidak tersedia';
          divisiController.text = userProfile!['divisi'] ?? 'Data tidak tersedia';
        });
      } else {
        _showError("Gagal memuat profil: ${profile['message']}");
      }
    } catch (e) {
      _showError("Gagal memuat profil: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    try {
      setState(() => isLoading = true);
      final response = await ApiService.updateProfile(
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        email: emailController.text,
      );

      if (mounted) {
        if (response['success'] == true) {
          await _loadProfile();
          setState(() => isEditing = false);
          _showSuccess("Profil berhasil diperbarui");
        } else {
          _showError(response['message'] ?? "Gagal memperbarui profil");
        }
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (!isEditing && userProfile != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => isEditing = true),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userProfile == null
          ? const Center(child: Text("Gagal memuat profil."))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Widget foto profil
            Center(child: Stack(children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: _imageFile != null ? FileImage(_imageFile!) : const AssetImage("assets/images/logo.png") as ImageProvider,
              ),
              if (isEditing) Positioned(bottom: 0, right: 0, child: InkWell(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2)),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                ),
              )),
            ])),
            const SizedBox(height: 20),
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
                Expanded(child: OutlinedButton(
                  onPressed: () {
                    setState(() => isEditing = false);
                    _loadProfile();
                  },
                  child: const Text("Batal"),
                )),
                const SizedBox(width: 16),
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: _updateProfile,
                  child: const Text("Simpan"),
                )),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {bool isEnabled = true}) {
    return TextField(
      controller: controller,
      enabled: isEnabled,
      decoration: InputDecoration(
        labelText: label,
        filled: !isEnabled,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          )),
        ],
      ),
    );
  }
}
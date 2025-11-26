import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/jadwal_api_service.dart';

class TambahJadwalPage extends StatefulWidget {
  final String namaPengguna;
  const TambahJadwalPage({super.key, required this.namaPengguna});

  @override
  State<TambahJadwalPage> createState() => _TambahJadwalPageState();
}

class _TambahJadwalPageState extends State<TambahJadwalPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController namaController;
  final tanggalController = TextEditingController();
  final agendaController = TextEditingController();
  final catatanController = TextEditingController();
  final pesertaController = TextEditingController(text: "1");

  bool isLoading = false;
  bool isDropdownLoading = true;

  // List Data Dropdown
  List<Map<String, dynamic>> perusahaanList = [];
  List<Map<String, dynamic>> divisiList = [];
  List<Map<String, dynamic>> ruanganList = [];

  // Value Terpilih (Tipe int? agar sesuai logika dropdown sebelumnya)
  int? selectedPerusahaanId;
  int? selectedDivisiId;
  int? selectedRuanganId;

  String? jamMulai, jamSelesai, menitMulai, menitSelesai;
  final jamList = List.generate(12, (i) => (i + 8).toString().padLeft(2, '0'));
  final menitList = ["00", "15", "30", "45"];

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(text: widget.namaPengguna);
    tanggalController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    setState(() => isDropdownLoading = true);
    try {
      // 1. Ambil semua data yang dibutuhkan (List & Profile)
      final results = await Future.wait([
        JadwalApiService.getPerusahaanList(),    // index 0
        JadwalApiService.getDivisiList(),        // index 1
        JadwalApiService.getRuanganList(),       // index 2
        JadwalApiService.getUserProfileDivisi(), // index 3 (Profile User)
      ]);

      if (mounted) {
        setState(() {
          perusahaanList = results[0] as List<Map<String, dynamic>>;
          divisiList = results[1] as List<Map<String, dynamic>>;
          ruanganList = results[2] as List<Map<String, dynamic>>;

          final userProfile = results[3] as Map<String, dynamic>;

          // 2. OTOMATIS SET VALUE DARI PROFILE
          // Cek apakah data profile ada
          if (userProfile.isNotEmpty) {
            // Mapping: 'branch_id' (String "0") -> Int 0
            if (userProfile['branch_id'] != null) {
              selectedPerusahaanId = int.tryParse(userProfile['branch_id'].toString());
            }

            // Mapping: 'organization_id' (Int 166758) -> Int
            if (userProfile['organization_id'] != null) {
              selectedDivisiId = int.tryParse(userProfile['organization_id'].toString());
            }

            // --- LOGIKA TAMBAHAN (SAFETY) ---
            // Kalau list divisi/perusahaan kosong (misal API list error),
            // kita suntikkan manual data user ke list biar dropdown ga error "value not in items"
            // dan tampilannya tetap bener (ada teks-nya).

            // Cek Perusahaan di List
            bool companyExists = perusahaanList.any((p) => p['id'] == selectedPerusahaanId);
            if (!companyExists && selectedPerusahaanId != null) {
              perusahaanList.add({
                'id': selectedPerusahaanId,
                'callsign': userProfile['alias'] ?? 'Perusahaan Saya'
              });
            }

            // Cek Divisi di List
            bool divisionExists = divisiList.any((d) => d['id'] == selectedDivisiId);
            if (!divisionExists && selectedDivisiId != null) {
              divisiList.add({
                'id': selectedDivisiId,
                'divisi': userProfile['organization_name'] ?? 'Divisi Saya'
              });
            }
          }

          isDropdownLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) setState(() => isDropdownLoading = false);
    }
  }

  Future<void> _simpanJadwal() async {
    if (_formKey.currentState!.validate() &&
        selectedPerusahaanId != null &&
        selectedDivisiId != null &&
        selectedRuanganId != null &&
        jamMulai != null &&
        jamSelesai != null) {

      setState(() => isLoading = true);
      try {
        final data = {
          "agenda": agendaController.text,
          "perusahaan_id": selectedPerusahaanId,
          "divisi": selectedDivisiId,
          "ruangan": selectedRuanganId,
          "tanggal": tanggalController.text,
          "jam_mulai": "$jamMulai:$menitMulai",
          "jam_selesai": "$jamSelesai:$menitSelesai",
          "jml_peserta": int.tryParse(pesertaController.text) ?? 1,
          "keterangan": catatanController.text,
          "status": 1,
          "user": widget.namaPengguna
        };

        await JadwalApiService.addJadwal(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Berhasil disimpan"), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi semua data"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey.shade100,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(theme),
              Expanded(
                child: isDropdownLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(namaController, "Nama Pengguna (PIC)", readOnly: true, filled: true),
                      const SizedBox(height: 16),
                      _buildTanggalField(theme),
                      const SizedBox(height: 16),

                      // --- DROPDOWN PERUSAHAAN (Tampilan Tetap Dropdown) ---
                      _buildDropdown(
                        label: "Perusahaan",
                        hint: "Pilih Perusahaan",
                        items: perusahaanList,
                        idKey: 'id',
                        nameKey: 'callsign',
                        value: selectedPerusahaanId,
                        onChanged: (v) => setState(() => selectedPerusahaanId = v),
                      ),
                      const SizedBox(height: 16),

                      // --- DROPDOWN DIVISI (Tampilan Tetap Dropdown) ---
                      _buildDropdown(
                        label: "Divisi",
                        hint: "Pilih Divisi",
                        items: divisiList,
                        idKey: 'id',
                        nameKey: 'divisi',
                        value: selectedDivisiId,
                        onChanged: (v) => setState(() => selectedDivisiId = v),
                      ),
                      const SizedBox(height: 16),

                      // --- DROPDOWN RUANGAN ---
                      _buildDropdown(
                        label: "Ruangan",
                        hint: "Pilih Ruangan",
                        items: ruanganList,
                        idKey: 'id', // atau 'ruangan_id' sesuai API ruangan
                        nameKey: 'ruangan',
                        value: selectedRuanganId,
                        onChanged: (v) => setState(() => selectedRuanganId = v),
                      ),

                      const SizedBox(height: 16),
                      _buildJamMenit("Jam Mulai", jamMulai, menitMulai, (v) => setState(() => jamMulai = v), (v) => setState(() => menitMulai = v), theme, isDark),
                      const SizedBox(height: 16),
                      _buildJamMenit("Jam Selesai", jamSelesai, menitSelesai, (v) => setState(() => jamSelesai = v), (v) => setState(() => menitSelesai = v), theme, isDark),
                      const SizedBox(height: 16),
                      _buildTextField(pesertaController, "Jumlah Peserta", keyboard: TextInputType.number),
                      const SizedBox(height: 16),
                      _buildTextField(agendaController, "Agenda Rapat", maxLines: 3),
                      const SizedBox(height: 16),
                      _buildTextField(catatanController, "Catatan Tambahan (Opsional)", maxLines: 3, isRequired: false),
                    ],
                  ),
                ),
              ),
              _buildBottomButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets (Sama seperti sebelumnya) ---

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Tambah Jadwal", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    // Cek apakah value ada di items, jika tidak null-kan agar tidak error
    final isValidValue = value != null && items.any((i) => i[idKey] == value);

    return DropdownButtonFormField<int>(
      value: isValidValue ? value : null,
      hint: Text(hint),
      isExpanded: true,
      items: items.map((item) {
        return DropdownMenuItem<int>(
          value: item[idKey] as int,
          child: Text(item[nameKey].toString(), overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged, // User masih bisa ganti (sesuai request "tampilan sama")
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: (v) => v == null ? 'Wajib diisi' : null,
    );
  }

  Widget _buildTextField(TextEditingController c, String label, {bool readOnly = false, bool filled = false, int maxLines = 1, TextInputType keyboard = TextInputType.text, bool isRequired = true}) {
    return TextFormField(
      controller: c,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        filled: filled,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (v) => isRequired && (v == null || v.isEmpty) ? 'Wajib diisi' : null,
    );
  }

  Widget _buildTanggalField(ThemeData theme) {
    return TextFormField(
      controller: tanggalController,
      readOnly: true,
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
        );
        if (d != null) tanggalController.text = DateFormat('yyyy-MM-dd').format(d);
      },
      decoration: InputDecoration(
        labelText: "Tanggal",
        suffixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildJamMenit(String label, String? jam, String? menit, ValueChanged<String?> onJam, ValueChanged<String?> onMenit, ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: jam,
            items: jamList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onJam,
            decoration: InputDecoration(labelText: "$label", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: menit,
            items: menitList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onMenit,
            decoration: InputDecoration(labelText: "Menit", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.cardColor,
      child: Row(
        children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Batal"))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: isLoading ? null : _simpanJadwal,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Simpan"),
          )),
        ],
      ),
    );
  }
}
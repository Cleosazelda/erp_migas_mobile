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
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Form(
        key: _formKey,
        child: isDropdownLoading
            ? const Center(child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(),
        ))
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant?.withOpacity(0.4) ??
                        colorScheme.outline.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Jadwal Rapat',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildLabeledField(
                label: "Nama Pengguna (PIC)",
                child: _buildTextField(
                  namaController,
                  hint: "Nama Pengguna (PIC)",
                  readOnly: true,
                ),
              ),
              const SizedBox(height: 12),
              _buildLabeledField(
                label: "Agenda Rapat",
                child: _buildTextField(
                  agendaController,
                  hint: "Tuliskan agenda rapat",
                ),
              ),
              const SizedBox(height: 12),
              _buildLabeledField(
                label: "Tanggal",
                child: _buildTanggalField(theme),
              ),
              const SizedBox(height: 12),
              _buildLabeledField(
                label: "Perusahaan",
                child: _buildDropdown(
                  hint: "Pilih Perusahaan",
                  items: perusahaanList,
                  idKey: 'id',
                  nameKey: 'callsign',
                  value: selectedPerusahaanId,
                  onChanged: (v) => setState(() => selectedPerusahaanId = v),
                ),
              ),
              const SizedBox(height: 12),
              _buildLabeledField(
                label: "Divisi",
                child: _buildDropdown(
                  hint: "Pilih Divisi",
                  items: divisiList,
                  idKey: 'id',
                  nameKey: 'divisi',
                  value: selectedDivisiId,
                  onChanged: (v) => setState(() => selectedDivisiId = v),
                ),
              ),
              const SizedBox(height: 12),
              _buildLabeledField(
                label: "Ruangan",
                child: _buildDropdown(
                  hint: "Pilih Ruangan",
                  items: ruanganList,
                  idKey: 'id',
                  nameKey: 'ruangan',
                  value: selectedRuanganId,
                  onChanged: (v) => setState(() => selectedRuanganId = v),
                ),
              ),
              const SizedBox(height: 12),
              _buildJamMenit(
                label: "Jam Mulai",
                jam: jamMulai,
                menit: menitMulai,
                onJam: (v) => setState(() => jamMulai = v),
                onMenit: (v) => setState(() => menitMulai = v),
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildJamMenit(
                label: "Jam Selesai",
                jam: jamSelesai,
                menit: menitSelesai,
                onJam: (v) => setState(() => jamSelesai = v),
                onMenit: (v) => setState(() => menitSelesai = v),
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildLabeledField(
                label: "Jumlah Peserta",
                child: _buildTextField(
                  pesertaController,
                  hint: "Masukkan jumlah peserta",
                  keyboard: TextInputType.number,
                ),
              ),
              const SizedBox(height: 12),
              _buildLabeledField(
                label: "Catatan Tambahan (Opsional)",
                child: _buildTextField(
                  catatanController,
                  hint: "Tambahkan catatan bila perlu",
                  maxLines: 3,
                  isRequired: false,
                ),
              ),
              const SizedBox(height: 20),
              _buildBottomButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
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
      items: items
          .map((item) => DropdownMenuItem<int>(
        value: item[idKey] as int,
        child: Text(item[nameKey].toString(),
            overflow: TextOverflow.ellipsis),
      ))
          .toList(),
      onChanged: onChanged,
      decoration: _inputDecoration(hint).copyWith(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
      ),
      validator: (v) => v == null ? 'Wajib diisi' : null,
    );
  }

  Widget _buildTextField(
      TextEditingController c, {
        required String hint,
        bool readOnly = false,
        int maxLines = 1,
        TextInputType keyboard = TextInputType.text,
        bool isRequired = true,
      }) {
      return TextFormField(
      controller: c,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: _inputDecoration(hint),
      validator: (v) => isRequired && (v == null || v.isEmpty)
          ? 'Wajib diisi'
          : null,
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
      decoration: _inputDecoration("Pilih tanggal").copyWith(
        suffixIcon: const Icon(Icons.calendar_today_outlined),
      ),
    );
  }

  Widget _buildJamMenit({
    required String label,
    required String? jam,
    required String? menit,
    required ValueChanged<String?> onJam,
    required ValueChanged<String?> onMenit,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: jam,
                items: jamList
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onJam,
                decoration: _inputDecoration("Jam"),
                validator: (v) => v == null ? 'Wajib diisi' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: menit,
                items: menitList
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onMenit,
                decoration: _inputDecoration("Menit"),
                validator: (v) => v == null ? 'Wajib diisi' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomButtons(ThemeData theme) {    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text("Batal"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : _simpanJadwal,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: isLoading
                ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary),
              ),
            )
                : const Text("Simpan"),
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledField({
    required String label,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
          theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.outline.withOpacity(isDark ? 0.4 : 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.outline.withOpacity(isDark ? 0.4 : 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
      ),
    );
  }
}
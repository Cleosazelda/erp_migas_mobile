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

  // Variabel untuk menyimpan ID yang dipilih
  int? selectedPerusahaanId, selectedDivisiId, selectedRuanganId;
  // Variabel untuk menyimpan jam & menit
  String? jamMulai, jamSelesai, menitMulai, menitSelesai;

  // Data dropdown menggunakan Map<id, nama>
  final Map<int, String> perusahaanMap = {1: "PT Migas Utama Jabar", 2: "PT MUJ ONWJ", 3: "PT ENM", 4: "PT MUJI"};
  final Map<int, String> divisiMap = {1: "Sekretaris Perusahaan", 2: "Satuan Pengawas Internal", 3: "Manajemen Aset"};
  final Map<int, String> ruanganMap = {1: "Ruang Rapat Biomasa", 2: "Ruang Rapat Energi Angin", 3: "Ruang Rapat Gas Bumi", 4: "Ruang Rapat Energi Matahari", 5: "Ruang Rapat Minyak Bumi"};

  final jamList = List.generate(12, (i) => (i + 8).toString().padLeft(2, '0'));
  final menitList = ["00", "15", "30", "45"];

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(text: widget.namaPengguna);
    tanggalController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    namaController.dispose();
    tanggalController.dispose();
    agendaController.dispose();
    catatanController.dispose();
    pesertaController.dispose();
    super.dispose();
  }

  Future<void> _simpanJadwal() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        final data = {
          "agenda": agendaController.text,
          "perusahaan_id": selectedPerusahaanId, // Mengirim ID
          "divisi": selectedDivisiId,             // Mengirim ID
          "ruangan": selectedRuanganId,           // Mengirim ID
          "tanggal": tanggalController.text,
          "jam_mulai": "$jamMulai:$menitMulai",
          "jam_selesai": "$jamSelesai:$menitSelesai",
          "jml_peserta": int.tryParse(pesertaController.text) ?? 1,
          "keterangan": catatanController.text.isNotEmpty ? catatanController.text : null,
          "status": 1 // Status default saat membuat (misal: 1 untuk 'PENDING')
        };

        await JadwalApiService.addJadwal(data);
        if(mounted) {
          _showSuccess("Jadwal berhasil ditambahkan!");
          Navigator.pop(context, true);
        }
      } catch (e) {
        if(mounted) _showError("Terjadi kesalahan: $e");
      } finally {
        if(mounted) setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildFormContent(),
                ),
              ),
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Tambah Jadwal Ruang Rapat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(namaController, "Nama Pengguna", readOnly: true, filled: true),
        const SizedBox(height: 12),
        _buildTanggalField(),
        const SizedBox(height: 12),
        _buildDropdown("Perusahaan", "Pilih Perusahaan", perusahaanMap, selectedPerusahaanId, (v) => setState(() => selectedPerusahaanId = v)),
        const SizedBox(height: 12),
        _buildDropdown("Divisi", "Pilih Divisi", divisiMap, selectedDivisiId, (v) => setState(() => selectedDivisiId = v)),
        const SizedBox(height: 12),
        _buildDropdown("Ruangan", "Pilih Ruangan", ruanganMap, selectedRuanganId, (v) => setState(() => selectedRuanganId = v)),
        const SizedBox(height: 12),
        _buildJamMenit("Jam Mulai", jamMulai, menitMulai, (v) => setState(() => jamMulai = v), (v) => setState(() => menitMulai = v)),
        const SizedBox(height: 12),
        _buildJamMenit("Jam Selesai", jamSelesai, menitSelesai, (v) => setState(() => jamSelesai = v), (v) => setState(() => menitSelesai = v)),
        const SizedBox(height: 12),
        _buildTextField(pesertaController, "Jml Peserta", keyboard: TextInputType.number),
        const SizedBox(height: 12),
        _buildTextField(agendaController, "Agenda Rapat", maxLines: 3),
        const SizedBox(height: 12),
        _buildTextField(catatanController, "Catatan (Opsional)", maxLines: 3, isRequired: false),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text("Tutup"))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: isLoading ? null : _simpanJadwal,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Simpan"),
          )),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  TextFormField _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType keyboard = TextInputType.text, bool readOnly = false, bool filled = false, bool isRequired = true}) {
    return TextFormField(
        controller: controller, maxLines: maxLines, keyboardType: keyboard, readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label, filled: filled, fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          alignLabelWithHint: maxLines > 1,
        ),
        validator: (v) {
          if (isRequired && (v == null || v.isEmpty)) { return 'Wajib diisi'; }
          return null;
        }
    );
  }

  TextFormField _buildTanggalField() {
    return TextFormField(
      controller: tanggalController,
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (date != null) {
          tanggalController.text = DateFormat('yyyy-MM-dd').format(date);
        }
      },
      decoration: InputDecoration(labelText: "Tanggal", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), suffixIcon: const Icon(Icons.calendar_today)),
      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
    );
  }

  DropdownButtonFormField<int> _buildDropdown(String label, String hint, Map<int, String> items, int? value, ValueChanged<int?> onChanged) {
    return DropdownButtonFormField<int>(
      value: value,
      items: items.entries.map((entry) => DropdownMenuItem<int>(value: entry.key, child: Text(entry.value))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
      validator: (v) => v == null ? 'Wajib diisi' : null,
    );
  }

  Widget _buildJamMenit(String label, String? jam, String? menit, ValueChanged<String?> onJamChanged, ValueChanged<String?> onMenitChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 4),
      Row(children: [
        Expanded(child: DropdownButtonFormField<String>(
          value: jam, items: jamList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onJamChanged,
          decoration: InputDecoration(labelText: "Jam", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), validator: (v) => v == null ? 'Wajib' : null,
        )),
        const SizedBox(width: 8),
        Expanded(child: DropdownButtonFormField<String>(
          value: menit, items: menitList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onMenitChanged,
          decoration: InputDecoration(labelText: "Menit", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), validator: (v) => v == null ? 'Wajib' : null,
        )),
      ]),
    ]);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }
}
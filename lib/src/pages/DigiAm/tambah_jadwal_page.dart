import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/jadwal_api_service.dart';

class TambahJadwalPage extends StatefulWidget {
  final String namaPengguna;

  const TambahJadwalPage({
    super.key,
    required this.namaPengguna,
  });

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

  List<Map<String, dynamic>> perusahaanList = [];
  List<Map<String, dynamic>> divisiList = [];
  List<Map<String, dynamic>> ruanganList = [];

  int? selectedPerusahaanId;
  int? selectedDivisiId;
  int? selectedRuanganId;
  String? jamMulai, jamSelesai, menitMulai, menitSelesai;

  final jamList = List.generate(12, (i) => "${(i + 8).toString().padLeft(2, '0')}");
  final menitList = ["00", "15", "30", "45"];

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(text: widget.namaPengguna);
    tanggalController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      final results = await Future.wait([
        JadwalApiService.getPerusahaanList(),
        JadwalApiService.getDivisiList(),
        JadwalApiService.getRuanganList(),
      ]);
      if (mounted) {
        setState(() {
          perusahaanList = results[0];
          divisiList = results[1];
          ruanganList = results[2];
          isDropdownLoading = false;
        });
      }
    } catch (e) {
      if(mounted) {
        _showError("Gagal memuat data form: $e");
        Navigator.pop(context);
      }
    }
  }

  Future<void> _simpanJadwal() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        final data = {
          "agenda": agendaController.text,
          "perusahaan_id": selectedPerusahaanId,
          "divisi_id": selectedDivisiId,
          "user": namaController.text,
          "ruangan_id": selectedRuanganId,
          "tanggal": tanggalController.text,
          "jam_mulai": "$jamMulai:$menitMulai:00",
          "jam_selesai": "$jamSelesai:$menitSelesai:00",
          "jml_peserta": int.tryParse(pesertaController.text) ?? 1,
          "keterangan": catatanController.text,
        };
        final success = await JadwalApiService.addJadwal(data);
        if(mounted) {
          if(success) {
            _showSuccess("Jadwal berhasil ditambahkan!");
            Navigator.pop(context, true);
          } else {
            _showError("Gagal menyimpan jadwal.");
          }
        }
      } catch (e) {
        if(mounted) _showError("Terjadi kesalahan: $e");
      } finally {
        if(mounted) setState(() => isLoading = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: isDropdownLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildFormContent(),
                ),
              ),
              if (!isDropdownLoading) _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, 1))],
      ),
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
        _buildDropdownPerusahaan(),
        const SizedBox(height: 12),
        _buildJamMenit("Jam Mulai", jamMulai, menitMulai, (v) => setState(() => jamMulai = v), (v) => setState(() => menitMulai = v)),
        const SizedBox(height: 12),
        _buildDropdownDivisi(),
        const SizedBox(height: 12),
        _buildJamMenit("Jam Selesai", jamSelesai, menitSelesai, (v) => setState(() => jamSelesai = v), (v) => setState(() => menitSelesai = v)),
        const SizedBox(height: 12),
        _buildDropdownRuangan(),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, -1))],
      ),
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

  DropdownButtonFormField<int> _buildDropdownPerusahaan() {
    return DropdownButtonFormField<int>(
      value: selectedPerusahaanId,
      items: perusahaanList.map((item) => DropdownMenuItem(value: item['id'] as int, child: Text(item['callsign'] as String))).toList(),
      onChanged: (v) => setState(() => selectedPerusahaanId = v),
      decoration: const InputDecoration(labelText: "Perusahaan", border: OutlineInputBorder()),
      validator: (v) => v == null ? 'Wajib diisi' : null,
    );
  }

  DropdownButtonFormField<int> _buildDropdownDivisi() {
    return DropdownButtonFormField<int>(
      value: selectedDivisiId,
      items: divisiList.map((item) => DropdownMenuItem(value: item['id'] as int, child: Text(item['divisi'] as String))).toList(),
      onChanged: (v) => setState(() => selectedDivisiId = v),
      decoration: const InputDecoration(labelText: "Divisi", border: OutlineInputBorder()),
      validator: (v) => v == null ? 'Wajib diisi' : null,
    );
  }

  DropdownButtonFormField<int> _buildDropdownRuangan() {
    return DropdownButtonFormField<int>(
      value: selectedRuanganId,
      items: ruanganList.map((item) => DropdownMenuItem(value: item['id'] as int, child: Text(item['ruangan'] as String))).toList(),
      onChanged: (v) => setState(() => selectedRuanganId = v),
      decoration: const InputDecoration(labelText: "Ruangan", border: OutlineInputBorder()),
      validator: (v) => v == null ? 'Wajib diisi' : null,
    );
  }

  Widget _buildJamMenit(
      String label, String? jam, String? menit,
      ValueChanged<String?> onJamChanged, ValueChanged<String?> onMenitChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 4),
      Row(children: [
        Expanded(child: DropdownButtonFormField<String>(
          value: jam, items: jamList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onJamChanged,
          decoration: const InputDecoration(labelText: "Jam", border: OutlineInputBorder()), validator: (v) => v == null ? 'Wajib' : null,
        )),
        const SizedBox(width: 8),
        Expanded(child: DropdownButtonFormField<String>(
          value: menit, items: menitList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onMenitChanged,
          decoration: const InputDecoration(labelText: "Menit", border: OutlineInputBorder()), validator: (v) => v == null ? 'Wajib' : null,
        )),
      ]),
    ]);
  }

  TextFormField _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType keyboard = TextInputType.text, bool readOnly = false, bool filled = false, bool isRequired = true}) {
    return TextFormField(
        controller: controller, maxLines: maxLines, keyboardType: keyboard, readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label, filled: filled, fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          alignLabelWithHint: maxLines > 1,
        ),
        validator: (v) {
          if (isRequired && (v == null || v.isEmpty)) {
            return 'Wajib diisi';
          }
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
      decoration: const InputDecoration(labelText: "Tanggal", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }
}
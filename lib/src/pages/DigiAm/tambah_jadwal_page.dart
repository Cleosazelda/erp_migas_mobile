import 'package:flutter/material.dart';

class TambahJadwalPage extends StatefulWidget {
  const TambahJadwalPage({super.key});

  @override
  State<TambahJadwalPage> createState() => _TambahJadwalPageState();
}

class _TambahJadwalPageState extends State<TambahJadwalPage> {
  // Controllers
  final namaController = TextEditingController(text: "Hadi Ramdani");
  final tanggalController = TextEditingController(text: "03/09/2025");
  final agendaController = TextEditingController();
  final catatanController = TextEditingController();
  final pesertaController = TextEditingController(text: "1");

  // Dropdown values
  String? perusahaan, divisi, ruangan, jamMulai, jamSelesai, menitMulai, menitSelesai;

  // Dropdown data
  final perusahaanList = ["MUJ", "Pertamina", "ENM"];
  final divisiList = ["IT", "HR", "Finance", "Operasi"];
  final ruanganList = ["RR Matahari", "RR Bulan", "RR Bintang"];
  final jamList = List.generate(12, (i) => "${(i + 8).toString().padLeft(2, '0')}");
  final menitList = ["00", "15", "30", "45"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
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
          const Text(
            "Tambah Jadwal Ruang Rapat",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(namaController, "Nama", readOnly: true, filled: true),
        const SizedBox(height: 12),
        _buildTanggalField(),
        const SizedBox(height: 12),
        _buildDropdown("Perusahaan", "Pilih Perusahaan", perusahaanList, perusahaan, (v) => setState(() => perusahaan = v)),
        const SizedBox(height: 12),
        _buildJamMenit("Jam Mulai", jamMulai, menitMulai, (v) => setState(() => jamMulai = v), (v) => setState(() => menitMulai = v)),
        const SizedBox(height: 12),
        _buildDropdown("Divisi", "Pilih Divisi", divisiList, divisi, (v) => setState(() => divisi = v)),
        const SizedBox(height: 12),
        _buildJamMenit("Jam Selesai", jamSelesai, menitSelesai, (v) => setState(() => jamSelesai = v), (v) => setState(() => menitSelesai = v)),
        const SizedBox(height: 12),
        _buildDropdown("Ruangan", "Pilih Ruangan", ruanganList, ruangan, (v) => setState(() => ruangan = v)),
        const SizedBox(height: 12),
        _buildTextField(pesertaController, "Jml Peserta", keyboard: TextInputType.number),
        const SizedBox(height: 12),
        _buildTextField(agendaController, "Agenda Rapat", maxLines: 3),
        const SizedBox(height: 12),
        _buildTextField(catatanController, "Catatan", maxLines: 3),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, -1))],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                "Tutup",
                style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () { /* Logika Simpan */ },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                "Simpan",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  TextFormField _buildTextField(
      TextEditingController controller,
      String label, {
        int maxLines = 1,
        TextInputType keyboard = TextInputType.text,
        bool readOnly = false,
        bool filled = false,
      }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        filled: filled,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }

  DropdownButtonFormField<String> _buildDropdown(
      String label,
      String hint,
      List<String> list,
      String? value,
      ValueChanged<String?> onChanged,
      ) {
    return DropdownButtonFormField<String>(
      value: value,
      items: list.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      hint: Text(hint),
    );
  }

  Widget _buildJamMenit(
      String label,
      String? jam,
      String? menit,
      ValueChanged<String?> onJamChanged,
      ValueChanged<String?> onMenitChanged,
      ) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 4),
      Row(children: [
        Expanded(child: _buildDropdown("Jam", "Jam", jamList, jam, onJamChanged)),
        const SizedBox(width: 8),
        Expanded(child: _buildDropdown("Menit", "Menit", menitList, menit, onMenitChanged)),
      ]),
    ]);
  }

  Widget _buildTanggalField() {
    return TextFormField(
      controller: tanggalController,
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) {
          tanggalController.text =
          "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
        }
      },
      decoration: InputDecoration(
        labelText: "Tanggal",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
    );
  }
}

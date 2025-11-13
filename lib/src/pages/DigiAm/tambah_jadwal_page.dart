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
  String? dropdownError; // Untuk menampilkan error load dropdown

  List<Map<String, dynamic>> perusahaanList = [];
  List<Map<String, dynamic>> divisiList = [];
  List<Map<String, dynamic>> ruanganList = [];

  // Gunakan tipe data yang konsisten (int?) untuk ID terpilih
  int? selectedPerusahaanId;
  int? selectedDivisiId;
  int? selectedRuanganId;
  String? jamMulai, jamSelesai, menitMulai, menitSelesai;

  // Jam 08:00 sampai 19:45
  final jamList = List.generate(12, (i) => (i + 8).toString().padLeft(2, '0'));
  final menitList = ["00", "15", "30", "45"];

  bool _isMeetingRoomDetail(dynamic detail) {
    return detail == 2 || detail == '2' || detail == 4 || detail == '4';
  }

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(text: widget.namaPengguna);
    tanggalController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    setState(() {
      isDropdownLoading = true;
      dropdownError = null; // Reset error
    });
    try {
      // Mengambil data secara paralel
      final results = await Future.wait([
        JadwalApiService.getPerusahaanList(),
        JadwalApiService.getDivisiList(),
        JadwalApiService.getRuanganList(),
      ]);

      // Sedikit delay untuk memastikan state terupdate setelah Future selesai
      await Future.delayed(Duration.zero);

      if (mounted) {
        setState(() {
          perusahaanList = results[0];
          divisiList = results[1];
          final rawRooms = List<Map<String, dynamic>>.from(results[2]);
          // Form tambah jadwal menampilkan ruangan meeting (detail 2 dan 4)
          // agar hanya ruangan meeting yang valid yang muncul di dropdown.
          final filteredRooms = rawRooms
              .where((room) => _isMeetingRoomDetail(room['detail']))
              .toList();
          ruanganList = filteredRooms.isNotEmpty ? filteredRooms : rawRooms;
          isDropdownLoading = false;
        });
        print("Perusahaan: $perusahaanList");
        print("Divisi: $divisiList");
        print("Ruangan: $ruanganList");
      }
    } catch (e) {
      print("Error loading dropdown: $e"); // Log error
      if (mounted) {
        setState(() {
          isDropdownLoading = false;
          // Tampilkan pesan error yang lebih informatif
          dropdownError = "Gagal memuat data form: ${e.toString().replaceFirst("Exception: ", "")}";
        });
        _showError(dropdownError!); // Tampilkan juga di snackbar
        // Pertimbangkan untuk tidak langsung menutup halaman, biarkan user coba lagi
        // Navigator.pop(context);
      }
    }
  }

  Future<void> _simpanJadwal() async {
    // Validasi tambahan untuk dropdown dan waktu
    if (_formKey.currentState!.validate() &&
        selectedPerusahaanId != null &&
        selectedDivisiId != null &&
        selectedRuanganId != null &&
        jamMulai != null && menitMulai != null &&
        jamSelesai != null && menitSelesai != null)
    {
      // Validasi Logika Waktu
      final waktuMulai = int.parse(jamMulai!) * 60 + int.parse(menitMulai!);
      final waktuSelesai = int.parse(jamSelesai!) * 60 + int.parse(menitSelesai!);

      if (waktuSelesai <= waktuMulai) {
        _showError("Jam selesai harus setelah jam mulai.");
        return;
      }


      setState(() => isLoading = true);
      try {
        final data = {
          "agenda": agendaController.text,
          "perusahaan_id": selectedPerusahaanId, // Kirim sebagai int
          "divisi": selectedDivisiId,          // Kirim ID divisi sebagai int
          "user": widget.namaPengguna,        // Ini mungkin tidak diperlukan oleh API POST, tapi kita include dulu
          "ruangan": selectedRuanganId,        // Kirim sebagai int
          "tanggal": tanggalController.text,
          "jam_mulai": "$jamMulai:$menitMulai",   // Format HH:mm
          "jam_selesai": "$jamSelesai:$menitSelesai", // Format HH:mm
          "jml_peserta": int.tryParse(pesertaController.text) ?? 1,
          "keterangan": catatanController.text.isNotEmpty ? catatanController.text : null,
          "status": 1 // Status 1 untuk pengajuan baru
        };

        final response = await JadwalApiService.addJadwal(data);
        if (mounted) {
          // Cek respons dari API jika ada pesan sukses spesifik
          _showSuccess(response['message'] ?? "Jadwal berhasil ditambahkan!");
          Navigator.pop(context, true); // Kirim true untuk reload data di halaman sebelumnya
        }
      } catch (e) {
        if (mounted) {
          _showError("Gagal menyimpan: ${e.toString().replaceFirst("Exception: ", "")}");
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    } else {
      // Tampilkan pesan jika ada field yang belum diisi
      _showError("Harap lengkapi semua field yang wajib diisi.");
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
    // --- PENYESUAIAN TEMA ---
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // --- PENYESUAIAN TEMA ---
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey.shade100,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: isDropdownLoading
                    ? const Center(child: CircularProgressIndicator())
                    : dropdownError != null
                    ? Center(
                    child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: Colors.red, size: 40),
                              SizedBox(height: 10),
                              Text(dropdownError!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _loadDropdownData,
                                child: Text("Coba Lagi"),
                              )
                            ]
                        )
                    )
                )
                    : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildFormContent(),
                ),
              ),
              // Hanya tampilkan tombol jika tidak loading dan tidak ada error dropdown
              if (!isDropdownLoading && dropdownError == null) _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      // --- PENYESUAIAN TEMA --- (Optional: beri sedikit background berbeda)
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2, offset: Offset(0,1))
          ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Tambah Jadwal Ruang Rapat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          IconButton(
            onPressed: () => Navigator.pop(context),
            // --- PENYESUAIAN TEMA ---
            icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
            tooltip: "Tutup",
          ),
        ],
      ),
    );
  }


  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(namaController, "Nama Pengguna (PIC)", readOnly: true, filled: true),
        const SizedBox(height: 16),
        _buildTanggalField(),
        const SizedBox(height: 16),
        // --- PERBAIKAN DROPDOWN ---
        // Pastikan 'id' dan 'callsign' adalah key yang benar dari API /perusahaan
        _buildDropdown<int>(
            label: "Perusahaan",
            hint: "Pilih Perusahaan",
            items: perusahaanList,
            idKey: 'id', // Sesuaikan jika key ID dari API berbeda
            nameKey: 'callsign', // Sesuaikan jika key nama dari API berbeda
            value: selectedPerusahaanId,
            onChanged: (v) => setState(() => selectedPerusahaanId = v)
        ),
        const SizedBox(height: 16),
        // --- PERBAIKAN DROPDOWN ---
        // Pastikan 'id' dan 'divisi' adalah key yang benar dari API /divisi
        _buildDropdown<int>(
            label: "Divisi",
            hint: "Pilih Divisi",
            items: divisiList,
            idKey: 'id', // Sesuaikan jika key ID dari API berbeda (mungkin 'organization_id'?)
            nameKey: 'divisi', // Sesuaikan jika key nama dari API berbeda (mungkin 'organization_name'?)
            value: selectedDivisiId,
            onChanged: (v) => setState(() => selectedDivisiId = v)
        ),
        const SizedBox(height: 16),
        // --- PERBAIKAN DROPDOWN ---
        // Pastikan 'id' dan 'ruangan' adalah key yang benar dari API /ruangan
        _buildDropdown<int>(
            label: "Ruangan",
            hint: "Pilih Ruangan",
            items: ruanganList,
            idKey: 'id', // Sesuaikan jika key ID dari API berbeda
            nameKey: 'ruangan', // Sesuaikan jika key nama dari API berbeda
            value: selectedRuanganId,
            onChanged: (v) => setState(() => selectedRuanganId = v)
        ),
        const SizedBox(height: 16),
        _buildJamMenit("Jam Mulai", jamMulai, menitMulai, (v) => setState(() => jamMulai = v), (v) => setState(() => menitMulai = v)),
        const SizedBox(height: 16),
        _buildJamMenit("Jam Selesai", jamSelesai, menitSelesai, (v) => setState(() => jamSelesai = v), (v) => setState(() => menitSelesai = v)),
        const SizedBox(height: 16),
        _buildTextField(pesertaController, "Jumlah Peserta", keyboard: TextInputType.number),
        const SizedBox(height: 16),
        _buildTextField(agendaController, "Agenda Rapat", maxLines: 3),
        const SizedBox(height: 16),
        _buildTextField(catatanController, "Catatan Tambahan (Opsional)", maxLines: 3, isRequired: false),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      // --- PENYESUAIAN TEMA --- (Beri background agar kontras)
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                // --- PENYESUAIAN TEMA ---
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
              // --- PENYESUAIAN TEMA ---
              child: Text("Batal", style: TextStyle(color: Theme.of(context).colorScheme.primary))
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: isLoading ? null : _simpanJadwal,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Tetap hijau untuk aksi utama
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14)
            ),
            child: isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Simpan Jadwal"),
          )),
        ],
      ),
    );
  }

// --- PERBAIKAN DROPDOWN --- (Gunakan Generics <T> untuk tipe value)
  DropdownButtonFormField<T> _buildDropdown<T>({
    required String label,
    required String hint,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required T? value,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator, // Tambahkan validator opsional
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(hint), // Tambahkan hint
      isExpanded: true, // Agar teks panjang tidak terpotong
      items: items.map((item) {
        // Pastikan value sesuai dengan tipe T (int dalam kasus ini)
        T itemValue;
        if (item[idKey] is T) {
          itemValue = item[idKey];
        } else if (T == int && item[idKey] is String) {
          // Coba konversi String ke int jika T adalah int
          itemValue = int.tryParse(item[idKey].toString()) as T? ?? item[idKey]; // Fallback ke nilai asli jika parse gagal
        } else if (T == int && item[idKey] is num) {
          itemValue = (item[idKey] as num).toInt() as T; // Konversi num ke int
        }
        else {
          // Fallback jika tipe tidak cocok atau T bukan int
          itemValue = item[idKey];
        }
        return DropdownMenuItem<T>(
          value: itemValue,
          child: Text(
            item[nameKey]?.toString() ?? 'N/A', // Tampilkan 'N/A' jika nama null
            overflow: TextOverflow.ellipsis, // Atasi teks panjang
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15), // Sesuaikan padding
      ),
      validator: validator ?? (v) => v == null ? 'Wajib diisi' : null, // Validator default
    );
  }


  Widget _buildJamMenit(
      String label, String? jam, String? menit,
      ValueChanged<String?> onJamChanged, ValueChanged<String?> onMenitChanged) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- PENYESUAIAN TEMA ---
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
          const SizedBox(height: 4),
          Row(
              children: [
                Expanded(
                    child: DropdownButtonFormField<String>(
                      value: jam,
                      items: jamList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: onJamChanged,
                      decoration: InputDecoration(
                        labelText: "Jam",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      ),
                      validator: (v) => v == null ? 'Wajib' : null,
                    )
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: DropdownButtonFormField<String>(
                      value: menit,
                      items: menitList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: onMenitChanged,
                      decoration: InputDecoration(
                        labelText: "Menit",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      ),
                      validator: (v) => v == null ? 'Wajib' : null,
                    )
                ),
              ]
          ),
        ]
    );
  }

  TextFormField _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType keyboard = TextInputType.text, bool readOnly = false, bool filled = false, bool isRequired = true}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        readOnly: readOnly,
        // --- PENYESUAIAN TEMA ---
        style: TextStyle(color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          // --- PENYESUAIAN TEMA ---
          labelStyle: TextStyle(color: theme.hintColor),
          filled: filled,
          // --- PENYESUAIAN TEMA ---
          fillColor: filled ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            // --- PENYESUAIAN TEMA ---
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          enabledBorder: OutlineInputBorder( // Border saat tidak fokus
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder( // Border saat fokus
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
          ),
          alignLabelWithHint: maxLines > 1,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15), // Padding konsisten
        ),
        validator: (v) {
          if (isRequired && (v == null || v.trim().isEmpty)) { // Trim untuk cek spasi
            return 'Wajib diisi';
          }
          if (label == "Jumlah Peserta") { // Validasi angka untuk peserta
            if (int.tryParse(v!) == null || int.parse(v) <= 0) {
              return 'Masukkan angka valid (> 0)';
            }
          }
          return null;
        }
    );
  }

  TextFormField _buildTanggalField() {
    final theme = Theme.of(context);
    return TextFormField(
      controller: tanggalController,
      readOnly: true,
      // --- PENYESUAIAN TEMA ---
      style: TextStyle(color: theme.colorScheme.onSurface),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(tanggalController.text) ?? DateTime.now(), // Gunakan tanggal terpilih jika ada
          firstDate: DateTime.now().subtract(const Duration(days: 30)), // Batasi tanggal awal
          lastDate: DateTime.now().add(const Duration(days: 365)), // Batasi tanggal akhir
          // --- PENYESUAIAN TEMA ---
          builder: (context, child) {
            return Theme(
              data: theme.copyWith(
                colorScheme: theme.colorScheme.copyWith(
                  primary: Colors.green, // Warna header
                  onPrimary: Colors.white, // Teks di header
                  onSurface: theme.colorScheme.onSurface, // Teks tanggal
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green, // Warna tombol OK/Cancel
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          tanggalController.text = DateFormat('yyyy-MM-dd').format(date);
        }
      },
      decoration: InputDecoration(
        labelText: "Tanggal Rapat",
        // --- PENYESUAIAN TEMA ---
        labelStyle: TextStyle(color: theme.hintColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          // --- PENYESUAIAN TEMA ---
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        // --- PENYESUAIAN TEMA ---
        suffixIcon: Icon(Icons.calendar_today, color: theme.hintColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
    );
  }

  // --- Fungsi Helper untuk Snackbar ---
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating, // Floating agar tidak menutupi tombol
    ));
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }
}
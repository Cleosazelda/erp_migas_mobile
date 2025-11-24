// lib/src/pages/admin/DigiAm/admin_page.dart

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- PERBAIKAN IMPORT SESUAI STRUKTUR FOLDER ---
import '../../../../services/jadwal_api_service.dart';
import '../../../models/jadwal_model.dart';
import '../../../../services/api_service.dart';
import '../../login_page.dart'; // (Tidak terpakai tapi path-nya benar)
import '../../DigiAm/tambah_jadwal_page.dart';
import '../../DigiAm/jadwal_table.dart';
// ---------------------------------------------


class AdminPage extends StatefulWidget {
  final String firstName;
  final String lastName;

  const AdminPage({super.key, required this.firstName, required this.lastName});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  Future<List<JadwalRapat>> _futureJadwal = Future.value([]);
  bool _isProcessingAction = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<JadwalRapat> _allBookings = [];
  List<JadwalRapat> _filteredBookings = [];
  String? _selectedFilterChip;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    initializeDateFormatting('id_ID', null).then((_) {
      if (mounted) {
        _loadJadwalAndInitializeFilter();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJadwalAndInitializeFilter() async {
    if (!mounted) return;
    setState(() {
      _futureJadwal = JadwalApiService.getAllJadwal().then((bookings) {
        if (mounted) {
          _allBookings = bookings;
          _sortBookings(_allBookings);
          _applyFilters();
        }
        return _allBookings;
      }).catchError((error) {
        print("Error initial load: $error");
        if (mounted) {
          _showSnackBar("Gagal memuat data awal: ${error.toString().replaceFirst('Exception: ', '')}", isError: true);
          setState(() {
            _allBookings = [];
            _filteredBookings = [];
          });
        }
        throw error;
      });
    });
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    try {
      final bookings = await JadwalApiService.getAllJadwal();
      if (mounted) {
        setState(() {
          _allBookings = bookings;
          _sortBookings(_allBookings);
          _applyFilters();
          _futureJadwal = Future.value(_allBookings);
        });
      }
    } catch (error) {
      print("Error during refresh: $error");
      if (mounted) {
        _showSnackBar("Gagal menyegarkan data: ${error.toString().replaceFirst('Exception: ', '')}", isError: true);
      }
    }
  }

  void _onSearchChanged() {
    if (_searchQuery != _searchController.text) {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
          _applyFilters();
        });
      }
    }
  }

  void _sortBookings(List<JadwalRapat> bookings) {
    bookings.sort((a, b) {
      int dateComparison = b.tanggal.compareTo(a.tanggal);
      if (dateComparison != 0) {
        return dateComparison;
      } else {
        try {
          final timeAInt = int.tryParse(a.jamMulai.replaceAll(':', ''));
          final timeBInt = int.tryParse(b.jamMulai.replaceAll(':', ''));
          if (timeAInt != null && timeBInt != null) {
            return timeAInt.compareTo(timeBInt);
          } else if (timeAInt != null) { return -1; }
          else if (timeBInt != null) { return 1; }
          return 0;
        } catch (e) {
          print("Error sorting times during secondary sort: $e");
          return 0;
        }
      }
    });
  }

  void _applyFilters() {
    if (!mounted) return;

    List<JadwalRapat> tempFiltered = List.from(_allBookings);

    if (_searchQuery.isNotEmpty) {
      String queryLower = _searchQuery.toLowerCase();
      tempFiltered = tempFiltered.where((jadwal) {
        return (jadwal.agenda.toLowerCase().contains(queryLower)) ||
            (jadwal.ruangan.toLowerCase().contains(queryLower)) ||
            (jadwal.pic.toLowerCase().contains(queryLower)) ||
            (jadwal.divisi.toLowerCase().contains(queryLower)) ||
            (jadwal.perusahaan.toLowerCase().contains(queryLower));
      }).toList();
    }

    if (_selectedFilterChip != null) {
      switch (_selectedFilterChip) {
        case 'Tanggal': break;
        case 'Pending':
          tempFiltered = tempFiltered.where((j) => j.status == 1).toList();
          break;
        case 'Disetujui':
          tempFiltered = tempFiltered.where((j) => j.status == 2).toList();
          break;
        case 'Ditolak':
          tempFiltered = tempFiltered.where((j) => j.status == 3).toList();
          break;
        case 'Energi Matahari':
          tempFiltered = tempFiltered.where((j) => j.ruangan == 'Ruang Rapat Energi Matahari').toList();
          break;
        case 'Gas Bumi':
          tempFiltered = tempFiltered.where((j) => j.ruangan == 'Ruang Rapat Gas Bumi').toList();
          break;
        case 'Konservasi Energi':
          tempFiltered = tempFiltered.where((j) => j.ruangan == 'Ruang Rapat Konservasi energi ').toList();
          break;
        case 'Biomasa':
          tempFiltered = tempFiltered.where((j) => j.ruangan == 'Ruang Rapat Biomasa').toList();
          break;
        case 'Energi Angin':
          tempFiltered = tempFiltered.where((j) => j.ruangan == 'Ruang Rapat Energi Angin').toList();
          break;
        case 'Minyak Bumi':
          tempFiltered = tempFiltered.where((j) => j.ruangan == 'Ruang Rapat Minyak Bumi').toList();
          break;
      }
    }

    setState(() {
      _filteredBookings = tempFiltered;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    if (ScaffoldMessenger.maybeOf(context) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      print("Snackbar Warning: ScaffoldMessenger context not found. Message: $message");
    }
  }

  Future<void> _updateBookingStatus(JadwalRapat jadwal, int newStatus) async {
    if (_isProcessingAction) return;
    if (!mounted) return;
    setState(() => _isProcessingAction = true);
    final url = Uri.parse("${ApiService.baseUrl}/ruang-rapat/${jadwal.id}/status");
    final body = jsonEncode({"status": newStatus});
    final headers = ApiService.headers;
    if (!headers.containsKey('Authorization')) {
      _showSnackBar("Error: Token otorisasi tidak ditemukan.", isError: true);
      if (mounted) setState(() => _isProcessingAction = false);
      return;
    }
    headers['Content-Type'] = 'application/json';
    try {
      final response = await http.patch(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (response.statusCode == 200) {
        _showSnackBar("Status '${jadwal.agenda}' diperbarui.");
        await _refreshData();
      } else {
        String errorMessage = "Gagal update (Code: ${response.statusCode})";
        try { errorMessage += ": ${jsonDecode(response.body)['message'] ?? response.body}"; } catch (_) { errorMessage += ": ${response.body}"; }
        _showSnackBar(errorMessage, isError: true);
      }
    } on TimeoutException { if (mounted) _showSnackBar("Timeout saat update status.", isError: true); }
    catch (e) { if (mounted) _showSnackBar("Error saat update status: ${e.toString()}", isError: true); }
    finally { if (mounted) setState(() => _isProcessingAction = false); }
  }

  Future<void> _deleteBooking(JadwalRapat jadwal) async {
    if (_isProcessingAction) return;
    if (!mounted) return;
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: Text("Yakin ingin menghapus jadwal '${jadwal.agenda}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmDelete != true) return;
    setState(() => _isProcessingAction = true);
    final url = Uri.parse("${ApiService.baseUrl}/ruang-rapat/${jadwal.id}");
    final headers = ApiService.headers;
    if (!headers.containsKey('Authorization')) {
      _showSnackBar("Error: Token otorisasi tidak ditemukan.", isError: true);
      if (mounted) setState(() => _isProcessingAction = false);
      return;
    }
    try {
      final response = await http.delete(url, headers: headers)
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSnackBar("Jadwal '${jadwal.agenda}' dihapus.");
        await _refreshData();
      } else {
        String errorMessage = "Gagal hapus (Code: ${response.statusCode})";
        try { errorMessage += ": ${jsonDecode(response.body)['message'] ?? response.body}"; } catch (_) { errorMessage += ": ${response.body}"; }
        _showSnackBar(errorMessage, isError: true);
      }
    } on TimeoutException { if (mounted) _showSnackBar("Timeout saat menghapus.", isError: true); }
    catch (e) { if (mounted) _showSnackBar("Error saat menghapus: ${e.toString()}", isError: true); }
    finally { if (mounted) setState(() => _isProcessingAction = false); }
  }

  Future<void> _showConfirmationDialog(JadwalRapat jadwal, String actionType) async {
    if (_isProcessingAction) return;
    if (!mounted) return;
    String title = actionType == 'approve' ? 'Konfirmasi Setujui' : 'Konfirmasi Tolak';
    String content = actionType == 'approve'
        ? 'Yakin ingin menyetujui jadwal "${jadwal.agenda}"?'
        : 'Yakin ingin menolak jadwal "${jadwal.agenda}"?';
    String confirmButtonText = actionType == 'approve' ? 'Setujui' : 'Tolak';
    Color confirmButtonColor = actionType == 'approve' ? Colors.green : Colors.orange;
    final bool? confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(context).pop(false)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: confirmButtonColor),
                child: Text(confirmButtonText, style: const TextStyle(color: Colors.white)),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        }
    );
    if (confirmed == true && mounted) {
      int newStatus = (actionType == 'approve') ? 2 : 3;
      _updateBookingStatus(jadwal, newStatus);
    }
  }

  void _handleAction(String action, JadwalRapat jadwal) {
    if (_isProcessingAction) { _showSnackBar("Harap tunggu...", isError: true); return; }
    switch (action) {
      case 'approve': case 'reject': _showConfirmationDialog(jadwal, action); break;
      case 'delete': _deleteBooking(jadwal); break;
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        builder: (context, child) {
          final theme = Theme.of(context);
          return Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                primary: Colors.green,
                onPrimary: Colors.white,
                onSurface: theme.colorScheme.onSurface,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
              ),
            ),
            child: child!,
          );
        }
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
        _applyFilters();
      });
    }
  }

  String _formatDate(DateTime date) { return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // HAPUS Scaffold, AppBar, dan FAB.
    // Widget ini sekarang HANYA mengembalikan konten utamanya.
    return Column(
      children: [
        // Tab Bar
        Container(
          color: theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.green,
            unselectedLabelColor: theme.hintColor,
            indicatorColor: Colors.green,
            tabs: const [
              Tab(text: "Ruang Rapat"),
              Tab(text: "Daftar Peminjaman"),
            ],
          ),
        ),
        // Konten Tab
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRuangRapatTab(theme), // Tab 1: Visual Schedule
              _buildListPeminjamanTabNewStyle(theme), // Tab 2: New Style List with Search/Filter
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildRuangRapatTab(ThemeData theme) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildDateSelector(theme),
          Expanded(
            child: FutureBuilder<List<JadwalRapat>>(
              future: _futureJadwal,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _allBookings.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError && _allBookings.isEmpty) {
                  return Center( child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
                      const SizedBox(height: 10),
                      Text("Gagal memuat jadwal visual: ${snapshot.error.toString().replaceFirst('Exception: ', '')}", textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      ElevatedButton(onPressed: _loadJadwalAndInitializeFilter, child: const Text("Coba Lagi"))
                    ],),
                  ),);
                }

                final displayedJadwal = _allBookings.where((jadwal) =>
                jadwal.status == 2 && DateUtils.isSameDay(jadwal.tanggal, _selectedDate)
                ).toList();

                if (displayedJadwal.isEmpty && snapshot.connectionState == ConnectionState.done ) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "Tidak ada jadwal rapat yang disetujui untuk\n${_formatDate(_selectedDate)}.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Theme.of(context).hintColor),
                      ),
                    ),
                  );
                }

                return JadwalTable(jadwalList: displayedJadwal);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: isDark ? Colors.grey[900] : Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _dateButton("< Sebelumnya", () {
                if (mounted) setState(() {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  _applyFilters();
                });
              })),
              const SizedBox(width: 10),
              Expanded(child: _dateButton("Hari Ini", () {
                if (mounted) setState(() {
                  _selectedDate = DateTime.now();
                  _applyFilters();
                });
              })),
              const SizedBox(width: 10),
              Expanded(child: _dateButton("Berikutnya >", () {
                if (mounted) setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                  _applyFilters();
                });
              })),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            readOnly: true,
            onTap: _pickDate,
            controller: TextEditingController(text: _formatDate(_selectedDate)),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: Icon(Icons.calendar_today, color: theme.hintColor),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
            ),
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  ElevatedButton _dateButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label),
    );
  }


  Widget _buildListPeminjamanTabNewStyle(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: isDark ? Colors.grey[850] : Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Cari agenda, PIC, ruangan...',
                          hintStyle: TextStyle(color: theme.hintColor.withOpacity(0.7), fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: theme.hintColor, size: 20),
                          isDense: true,
                          filled: true,
                          fillColor: isDark? Colors.grey[700]?.withOpacity(0.5) : Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.clear, color: theme.hintColor, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () { _searchController.clear(); },
                          )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                  ],
                ),
                const SizedBox(height: 10),

                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip(label: 'Diproses', value: 'Diproses', theme: theme),
                      _buildFilterChip(label: 'Disetujui', value: 'Disetujui', theme: theme),
                      _buildFilterChip(label: 'Ditolak', value: 'Ditolak', theme: theme),
                      _buildFilterChip(label: 'Energi Matahari', value: 'Energi Matahari', theme: theme),
                      _buildFilterChip(label: 'Gas Bumi', value: 'Gas Bumi', theme: theme),
                      _buildFilterChip(label: 'Konservasi Energi', value: 'Konservasi Energi', theme: theme),
                      _buildFilterChip(label: 'Biomasa', value: 'Biomasa', theme: theme),
                      _buildFilterChip(label: 'Energi Angin', value: 'Energi Angin', theme: theme),
                      _buildFilterChip(label: 'Minyak Bumi', value: 'Minyak Bumi', theme: theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: theme.dividerColor.withOpacity(0.1)),

          Expanded(
            child: FutureBuilder<List<JadwalRapat>>(
              future: _futureJadwal,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _allBookings.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError && _allBookings.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 40),
                          const SizedBox(height: 10),
                          Text("Gagal memuat Daftar peminjaman: ${snapshot.error.toString().replaceFirst('Exception: ', '')}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 10),
                          ElevatedButton(onPressed: _loadJadwalAndInitializeFilter, child: const Text("Coba Lagi"))
                        ],
                      ),
                    ),
                  );
                }

                if (_filteredBookings.isEmpty) {
                  return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          _searchQuery.isNotEmpty || _selectedFilterChip != null
                              ? "Tidak ada jadwal yang cocok."
                              : "Tidak ada data peminjaman.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.hintColor, fontSize: 16),
                        ),
                      )
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: _filteredBookings.length,
                    itemBuilder: (context, index) {
                      final jadwal = _filteredBookings[index];
                      return _buildBookingListItem(jadwal, theme);
                    },
                    separatorBuilder: (context, index) => Divider(
                      height: 1, thickness: 0.5, color: theme.dividerColor.withOpacity(0.3),
                      indent: 16, endIndent: 16,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required String value, required ThemeData theme}) {
    final bool isSelected = _selectedFilterChip == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: FilterChip(
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withOpacity(0.8),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            if (selected) {
              _selectedFilterChip = value;
              if (value == 'Ruangan') {
                _showSnackBar("Filter Ruangan belum diimplementasikan.", isError: true);
                _selectedFilterChip = null;
              } else if (value == 'Status') {
                _showSnackBar("Filter Status belum diimplementasikan.", isError: true);
                _selectedFilterChip = null;
              }
            } else {
              _selectedFilterChip = null;
            }
            _applyFilters();
          });
        },
        selectedColor: theme.colorScheme.primary.withOpacity(0.8),
        checkmarkColor: theme.colorScheme.onPrimary,
        backgroundColor: theme.chipTheme.backgroundColor ?? theme.cardColor,
        side: isSelected ? BorderSide.none : BorderSide(color: theme.dividerColor.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        visualDensity: const VisualDensity(horizontal: 0.0, vertical: -2),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
      ),
    );
  }


  Widget _buildBookingListItem(JadwalRapat jadwal, ThemeData theme) {
    Color statusColor;
    String statusText;
    switch (jadwal.status) {
      case 1: statusColor = Colors.orange; statusText = 'PENDING'; break;
      case 2: statusColor = Colors.green; statusText = 'DISETUJUI'; break;
      case 3: statusColor = Colors.red; statusText = 'DITOLAK'; break;
      default: statusColor = Colors.grey; statusText = '???';
    }
    final timeRange = _formatTimeRange(jadwal.jamMulai, jadwal.jamSelesai);
    final durationString = _calculateDuration(jadwal.jamMulai, jadwal.jamSelesai);
    final bool isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Material(
        color: isDark ? Colors.grey[900] : Colors.white,
        elevation: isDark ? 0 : 2,
        borderRadius: BorderRadius.circular(12),
        shadowColor: theme.shadowColor.withOpacity(0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${jadwal.agenda}",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(isDark ? 0.25 : 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: statusColor.withOpacity(0.5), width: 0.6),
                                ),
                                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(isDark ? 0.22 : 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.people_alt_outlined, size: 14, color: theme.colorScheme.primary),
                                    const SizedBox(width: 6),
                                    Text("${jadwal.jumlahPeserta} peserta", style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: theme.hintColor),
                      tooltip: "Opsi",
                      enabled: !_isProcessingAction,
                      onSelected: (String action) => _handleAction(action, jadwal),
                      itemBuilder: (BuildContext context) {
                        List<PopupMenuEntry<String>> items = [];
                        if (jadwal.status != 2) {
                          items.add(_buildPopupMenuItem('approve', Icons.check_circle_outline, 'Setujui', Colors.green));
                        }
                        if (jadwal.status != 3) {
                          items.add(_buildPopupMenuItem('reject', Icons.cancel_outlined, 'Tolak', Colors.orange));
                        }

                        if (jadwal.status != 2 && jadwal.status != 3) {
                          items.add(const PopupMenuDivider());
                        } else if (items.isNotEmpty) {
                          items.add(const PopupMenuDivider());
                        }

                        items.add(_buildPopupMenuItem('delete', Icons.delete_outline, 'Hapus', Colors.red));
                        return items;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDetailRowList(null,
                    "Tanggal Peminjaman : ${DateFormat('dd-MM-yyyy - HH:mm', 'id_ID').format(jadwal.tanggal)}", theme),
                _buildDetailRowList(null,
                    "Waktu : $timeRange ($durationString)", theme),
                _buildDetailRowList(null,
                    "Keterangan : ${jadwal.ruangan}", theme),
                _buildDetailRowList(null,
                    "PIC : ${jadwal.pic}", theme),
                _buildDetailRowList(null,
                    jadwal.divisi, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _calculateDuration(String startTime, String endTime) {
    try {
      final start = DateFormat("HH:mm:ss").parseStrict(startTime);
      final end = DateFormat("HH:mm:ss").parseStrict(endTime);
      final duration = end.difference(start);
      if (duration.isNegative) return "Invalid";
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      List<String> parts = [];
      if (hours > 0) parts.add("$hours jam");
      if (minutes > 0) parts.add("$minutes mnt");
      return parts.isEmpty ? "0 mnt" : parts.join(" ");
    } catch (e) {
      print("Error calculating duration ($startTime - $endTime): $e");
      return "-";
    }
  }

  Widget _buildDetailRowList(IconData? icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 13),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, IconData icon, String title, Color color) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
    );
  }

  String _formatTimeRange(String startTime, String endTime) {
    if (startTime.length < 5 || endTime.length < 5) {
      print("Warning: Invalid time format received '$startTime' - '$endTime'");
      return "$startTime - $endTime";
    }
    try {
      String start = startTime.substring(0, 5);
      String end = endTime.substring(0, 5);
      return "$start - $end";
    } catch (e) {
      print("Error formatting time range ($startTime - $endTime): $e");
      return "$startTime - $endTime";
    }
  }

} // Penutup Class _AdminPageState
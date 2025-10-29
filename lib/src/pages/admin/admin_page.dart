// lib/src/pages/admin/admin_page.dart

import 'dart:convert'; // Needed for jsonEncode
import 'dart:async'; // Needed for Future and TimeoutException
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Needed for http calls
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import for Indonesian locale

// Import services, models, and other pages
// PASTIKAN PATH IMPORT INI SUDAH BENAR SESUAI STRUKTUR FOLDER PROYEK KAMU
import '../../../services/jadwal_api_service.dart'; // Service to get schedule data
import '../../../src/models/jadwal_model.dart'; // Model for schedule data
import '../../../services/api_service.dart'; // For logout function and BASE URL/HEADERS
import '../login_page.dart'; // To navigate on logout
import '../DigiAm/tambah_jadwal_page.dart'; // To navigate to add schedule page
import '../DigiAm/jadwal_table.dart'; // Import JadwalTable visualizer

class AdminPage extends StatefulWidget {
  final String firstName;
  final String lastName;

  const AdminPage({super.key, required this.firstName, required this.lastName});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

// Add SingleTickerProviderStateMixin for TabController animation
class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // _selectedDate is now only relevant for the "Ruang Rapat" tab's visualizer
  DateTime _selectedDate = DateTime.now();
  // Use Future for initial load state management in FutureBuilder
  // Initialize with a completed future containing an empty list to avoid late initialization errors
  Future<List<JadwalRapat>> _futureJadwal = Future.value([]);
  bool _isProcessingAction = false; // Flag to indicate if an API call is in progress

  // --- State for Search and Filter ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<JadwalRapat> _allBookings = []; // Stores all fetched bookings (Source of truth)
  List<JadwalRapat> _filteredBookings = []; // Stores the list to be displayed after filtering

  // Placeholder filter criteria (can be expanded with more complex logic)
  String? _selectedFilterChip; // Stores the label of the active quick filter chip
  // Add state variables for specific filter types if needed later
  // DateTime? _selectedFilterDate; // Example if using advanced date filter
  // String? _selectedFilterRoomName; // Example if using advanced room filter
  // int? _selectedFilterStatus; // Example if using advanced status filter

  @override
  void initState() {
    super.initState();
    // Initialize the TabController with 2 tabs
    _tabController = TabController(length: 2, vsync: this);
    // Add listener to update search query and trigger filtering
    _searchController.addListener(_onSearchChanged);
    // Ensure Indonesian date formatting is initialized, then load initial data
    initializeDateFormatting('id_ID', null).then((_) {
      if (mounted) { // Check if the widget is still in the tree
        _loadJadwalAndInitializeFilter(); // Load data and apply initial empty filter
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose(); // Clean up the TabController
    _searchController.removeListener(_onSearchChanged); // Clean up listener
    _searchController.dispose(); // Clean up controller
    super.dispose();
  }

  // --- Load Data and Initialize Filter State ---
  // Sets the _futureJadwal for FutureBuilder and populates _allBookings
  Future<void> _loadJadwalAndInitializeFilter() async {
    if (!mounted) return;
    setState(() {
      // Set the future for the FutureBuilder to show loading/error state
      _futureJadwal = JadwalApiService.getAllJadwal().then((bookings) {
        if (mounted) {
          _allBookings = bookings; // Store the complete list
          _sortBookings(_allBookings); // Sort the complete list
          _applyFilters(); // Apply initial filters (search, date, room)
        }
        return _allBookings; // Return the fetched list for FutureBuilder
      }).catchError((error) {
        print("Error initial load: $error");
        if (mounted) {
          _showSnackBar("Gagal memuat data awal: ${error.toString().replaceFirst('Exception: ', '')}", isError: true);
          // Ensure lists are empty on error
          setState(() {
            _allBookings = [];
            _filteredBookings = [];
          });
        }
        // Return empty list on error for FutureBuilder
        throw error; // Rethrow error so FutureBuilder shows error state
      });
    });
  }

  // --- Refresh Data (called by pull-to-refresh and manual refresh button) ---
  Future<void> _refreshData() async {
    if (!mounted) return;
    // Fetch new data
    try {
      final bookings = await JadwalApiService.getAllJadwal();
      if (mounted) {
        setState(() {
          _allBookings = bookings; // Update the full list
          _sortBookings(_allBookings); // Resort the updated list
          _applyFilters(); // Re-apply current filters and search
          // Update the Future for the FutureBuilder to resolve quickly with new data
          _futureJadwal = Future.value(_allBookings);
        });
      }
    } catch (error) {
      print("Error during refresh: $error");
      if (mounted) {
        _showSnackBar("Gagal menyegarkan data: ${error.toString().replaceFirst('Exception: ', '')}", isError: true);
        // Don't change the future, let it hold the old data or error state
      }
    }
  }


  // --- Listener for Search Input Changes ---
  void _onSearchChanged() {
    // Avoid unnecessary rebuilds if the text hasn't changed
    if (_searchQuery != _searchController.text) {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text; // Update the search query state
          _applyFilters(); // Re-apply all filters whenever search query changes
        });
      }
    }
  }

  // --- Sort Function (Separated for clarity) ---
  void _sortBookings(List<JadwalRapat> bookings) {
    // Sort by date descending (newest first), then by start time ascending
    bookings.sort((a, b) {
      int dateComparison = b.tanggal.compareTo(a.tanggal); // Newest date first
      if (dateComparison != 0) {
        return dateComparison;
      } else {
        // If dates are the same, sort by start time ascending
        try {
          // Safely parse time strings
          final timeAInt = int.tryParse(a.jamMulai.replaceAll(':', ''));
          final timeBInt = int.tryParse(b.jamMulai.replaceAll(':', ''));
          if (timeAInt != null && timeBInt != null) {
            return timeAInt.compareTo(timeBInt);
          } else if (timeAInt != null) { return -1; } // Valid before invalid
          else if (timeBInt != null) { return 1; } // Invalid after valid
          return 0; // Keep original order if both parsing fails
        } catch (e) {
          print("Error sorting times during secondary sort: $e");
          return 0; // Keep original order on error
        }
      }
    });
  }


  // --- Apply All Filters (Search, Quick Chips) ---
  void _applyFilters() {
    if (!mounted) return;

    // Start with the full, sorted list
    List<JadwalRapat> tempFiltered = List.from(_allBookings);

    // 1. Apply Search Query Filter
    if (_searchQuery.isNotEmpty) {
      String queryLower = _searchQuery.toLowerCase();
      tempFiltered = tempFiltered.where((jadwal) {
        // Check against relevant fields (agenda, room, PIC, division, company)
        // Added null checks for safety
        return (jadwal.agenda.toLowerCase().contains(queryLower)) ||
            (jadwal.ruangan.toLowerCase().contains(queryLower)) ||
            (jadwal.pic.toLowerCase().contains(queryLower)) ||
            (jadwal.divisi.toLowerCase().contains(queryLower)) ||
            (jadwal.perusahaan.toLowerCase().contains(queryLower));
      }).toList();
    }

    // 2. Apply Quick Filter Chip Logic (Expandable)
    if (_selectedFilterChip != null) {
      // This logic handles the example chips provided
      switch (_selectedFilterChip) {
      // Category chips - currently placeholders, don't filter directly
        case 'Tanggal': break;
      // Specific filter chips
        case 'Pending':
          tempFiltered = tempFiltered.where((j) => j.status == 1).toList();
          break;
        case 'Disetujui':
          tempFiltered = tempFiltered.where((j) => j.status == 2).toList();
          break;
        case 'Ditolak':
          tempFiltered = tempFiltered.where((j) => j.status == 3).toList();
          break;
      // Add cases for specific room names matching chip labels
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
      // Add more room cases or other filter logic here...
      }
    }

    // Update the state with the final filtered list that the UI will display
    setState(() {
      _filteredBookings = tempFiltered;
    });
  }

  // --- Show Snackbar Helper ---
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    // Ensure context is still valid before showing Snackbar
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

  // --- Logout Function ---
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      await ApiService.logout();
      if (mounted) {
        // Ensure context is valid before navigation
        // Use Navigator.pushNamedAndRemoveUntil if using named routes, otherwise this is fine
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
      }
    }
  }

  // --- Navigate to Add Schedule Page ---
  void _openTambahJadwal() async {
    final result = await showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: TambahJadwalPage(namaPengguna: "${widget.firstName} ${widget.lastName}"),
      ),
    );
    if (result == true && mounted) _loadJadwalAndInitializeFilter(); // Refresh data after adding
  }

  // --- API Call: Update Booking Status ---
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
    headers['Content-Type'] = 'application/json'; // Ensure Content-Type
    try {
      final response = await http.patch(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (response.statusCode == 200) {
        _showSnackBar("Status '${jadwal.agenda}' diperbarui.");
        await _refreshData(); // Refresh data on success using the refresh function
      } else {
        String errorMessage = "Gagal update (Code: ${response.statusCode})";
        try { errorMessage += ": ${jsonDecode(response.body)['message'] ?? response.body}"; } catch (_) { errorMessage += ": ${response.body}"; }
        _showSnackBar(errorMessage, isError: true);
      }
    } on TimeoutException { if (mounted) _showSnackBar("Timeout saat update status.", isError: true); }
    catch (e) { if (mounted) _showSnackBar("Error saat update status: ${e.toString()}", isError: true); }
    finally { if (mounted) setState(() => _isProcessingAction = false); }
  }

  // --- API Call: Delete Booking ---
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
        await _refreshData(); // Refresh data on success using the refresh function
      } else {
        String errorMessage = "Gagal hapus (Code: ${response.statusCode})";
        try { errorMessage += ": ${jsonDecode(response.body)['message'] ?? response.body}"; } catch (_) { errorMessage += ": ${response.body}"; }
        _showSnackBar(errorMessage, isError: true);
      }
    } on TimeoutException { if (mounted) _showSnackBar("Timeout saat menghapus.", isError: true); }
    catch (e) { if (mounted) _showSnackBar("Error saat menghapus: ${e.toString()}", isError: true); }
    finally { if (mounted) setState(() => _isProcessingAction = false); }
  }

  // --- Show Confirmation Dialog for Status Change ---
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

  // --- Handle Action Selection from Popup Menu ---
  void _handleAction(String action, JadwalRapat jadwal) {
    if (_isProcessingAction) { _showSnackBar("Harap tunggu...", isError: true); return; }
    switch (action) {
      case 'approve': case 'reject': _showConfirmationDialog(jadwal, action); break;
      case 'delete': _deleteBooking(jadwal); break;
    }
  }

  // --- Date Picker Logic (Only for Ruang Rapat tab now) ---
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
                primary: Colors.green, // Header background color
                onPrimary: Colors.white, // Header text color
                onSurface: theme.colorScheme.onSurface, // Date text color
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green, // OK/Cancel button text color
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
        _applyFilters(); // Re-apply filters for list tab as well
      });
    }
  }

  // Format date for display
  String _formatDate(DateTime date) { return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date); }

  // --- Build Method: Constructs the UI ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String fullName = "${widget.firstName} ${widget.lastName}";
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset("assets/images/logo.png", height: 30),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Admin - Ruang Rapat", style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                Text("Welcome, $fullName!", style: TextStyle(fontSize: 12, color: theme.hintColor)),
              ],
            ),
          ],
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Refresh Data",
              onPressed: _isProcessingAction ? null : _refreshData // Use _refreshData
          ),
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Logout",
              onPressed: _isProcessingAction ? null : _logout
          ),
        ],
        bottom: TabBar( // TabBar remains in AppBar
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: theme.hintColor,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: "Ruang Rapat"),
            Tab(text: "List Peminjaman"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRuangRapatTab(theme), // Tab 1: Visual Schedule
          _buildListPeminjamanTabNewStyle(theme), // Tab 2: New Style List with Search/Filter
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isProcessingAction ? null : _openTambahJadwal,
        backgroundColor: _isProcessingAction ? Colors.grey : Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Tambah Jadwal Baru',
      ),
    );
  }

  // --- Widget Builder for "Ruang Rapat" Tab Content ---
  // (Shows visual schedule table for APPROVED bookings on _selectedDate)
  Widget _buildRuangRapatTab(ThemeData theme) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildDateSelector(theme), // Date selector specific to this tab
          Expanded(
            child: FutureBuilder<List<JadwalRapat>>(
              future: _futureJadwal, // Uses the shared future
              builder: (context, snapshot) {
                // Handle Loading state based on _allBookings being empty
                if (snapshot.connectionState == ConnectionState.waiting && _allBookings.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Handle Error state ONLY if _allBookings is still empty
                if (snapshot.hasError && _allBookings.isEmpty) {
                  return Center( child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
                      const SizedBox(height: 10),
                      Text("Gagal memuat jadwal visual: ${snapshot.error.toString().replaceFirst('Exception: ', '')}", textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      ElevatedButton(onPressed: _loadJadwalAndInitializeFilter, child: const Text("Coba Lagi")) // Use initial load
                    ],),
                  ),);
                }
                // Filter data: Only show APPROVED schedules (status 2) for the selected date
                // Use _allBookings as the source, filtered locally
                final displayedJadwal = _allBookings.where((jadwal) =>
                jadwal.status == 2 && DateUtils.isSameDay(jadwal.tanggal, _selectedDate)
                ).toList();

                // Handle no schedule for this specific date after loading completes
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

                return JadwalTable(jadwalList: displayedJadwal); // Display visual table
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Builder for Date Selector UI (Used only by Ruang Rapat Tab) ---
  Widget _buildDateSelector(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: isDark ? Colors.grey[900] : Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row( // Prev/Today/Next Buttons
            children: [
              Expanded(child: _dateButton("< Prev", () {
                if (mounted) setState(() {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  _applyFilters(); // Re-apply filters for list tab
                });
              })),
              const SizedBox(width: 10),
              Expanded(child: _dateButton("Today", () {
                if (mounted) setState(() {
                  _selectedDate = DateTime.now();
                  _applyFilters(); // Re-apply filters for list tab
                });
              })),
              const SizedBox(width: 10),
              Expanded(child: _dateButton("Next >", () {
                if (mounted) setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                  _applyFilters(); // Re-apply filters for list tab
                });
              })),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField( // Date display/picker field
            readOnly: true,
            onTap: _pickDate, // Opens date picker, which handles state update
            controller: TextEditingController(text: _formatDate(_selectedDate)), // Shows formatted date
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

  // --- Helper for Date Navigation Buttons ---
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


  // --- Widget Builder for "List Peminjaman" Tab (New Style with Search/Filter Bar) ---
  Widget _buildListPeminjamanTabNewStyle(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: theme.scaffoldBackgroundColor, // Use theme background
      child: Column( // Use Column to stack Search/Filter Bar and List
        children: [
          // --- Search and Filter Bar ---
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), // Adjusted padding
            color: isDark ? Colors.grey[850] : Colors.white, // Background for the filter area
            child: Column(
              children: [
                // --- Search Bar Row ---
                Row(
                  children: [
                    // Search Field
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
                            borderRadius: BorderRadius.circular(20.0), // Rounded border
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          // Clear button ('x')
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.clear, color: theme.hintColor, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () { _searchController.clear(); }, // Clears text and triggers listener
                          )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filter Icon Button
                    InkWell( // Use InkWell for better tap area & ripple
                      onTap: () {
                        // TODO: Implement advanced filter dialog/bottom sheet
                        _showSnackBar("Fitur filter lanjutan belum diimplementasikan.");
                        // Example: Show a bottom sheet
                        // showModalBottomSheet(context: context, builder: (_) => _buildFilterBottomSheet());
                      },
                      borderRadius: BorderRadius.circular(20), // Match icon button shape
                      child: Padding(
                        padding: const EdgeInsets.all(8.0), // Padding inside tap area
                        child: Icon(
                          Icons.filter_list,
                          color: theme.colorScheme.primary, // Use primary color
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10), // Space before quick filter chips

                // --- Quick Filter Chips ---
                SizedBox(
                  height: 32, // Constrained height for the chip row
                  child: ListView( // Horizontal scrollable list for chips
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip(label: 'Pending', value: 'Pending', theme: theme),
                      _buildFilterChip(label: 'Disetujui', value: 'Disetujui', theme: theme),
                      _buildFilterChip(label: 'Ditolak', value: 'Ditolak', theme: theme),
                      _buildFilterChip(label: 'Energi Matahari', value: 'Energi Matahari', theme: theme),
                      _buildFilterChip(label: 'Gas Bumi', value: 'Gas Bumi', theme: theme),
                      _buildFilterChip(label: 'Konservasi Energi', value: 'Konservasi Energi', theme: theme),
                      _buildFilterChip(label: 'Biomasa', value: 'Biomasa', theme: theme),
                      _buildFilterChip(label: 'Energi Angin', value: 'Energi Angin', theme: theme),
                      _buildFilterChip(label: 'Minyak Bumi', value: 'Minyak Bumi', theme: theme),// Example room
                      // Add more chips dynamically based on available rooms/statuses if needed
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: theme.dividerColor.withOpacity(0.1)), // Subtle divider

          // --- Filtered List Display ---
          Expanded(
            child: FutureBuilder<List<JadwalRapat>>(
              // FutureBuilder handles initial load state and errors based on _futureJadwal
              future: _futureJadwal,
              builder: (context, snapshot) {
                // Initial Loading State
                if (snapshot.connectionState == ConnectionState.waiting && _allBookings.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Initial Error State
                if (snapshot.hasError && _allBookings.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column( // Error display with retry button
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 40),
                          const SizedBox(height: 10),
                          Text("Gagal memuat list peminjaman: ${snapshot.error.toString().replaceFirst('Exception: ', '')}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 10),
                          ElevatedButton(onPressed: _loadJadwalAndInitializeFilter, child: const Text("Coba Lagi")) // Use initial load here
                        ],
                      ),
                    ),
                  );
                }

                // --- Display List based on _filteredBookings state ---

                // No Results State (after filtering or if initial list is empty)
                // Use _filteredBookings here as it reflects the current filtered state AFTER initial load
                if (_filteredBookings.isEmpty) {
                  return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          _searchQuery.isNotEmpty || _selectedFilterChip != null
                              ? "Tidak ada jadwal yang cocok." // Message when filters/search active
                              : "Tidak ada data peminjaman.", // Message when list is truly empty after load
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.hintColor, fontSize: 16),
                        ),
                      )
                  );
                }

                // Display the Filtered List
                return RefreshIndicator(
                  onRefresh: _refreshData, // Use _refreshData for pull-to-refresh
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8.0), // Padding for the list
                    itemCount: _filteredBookings.length, // Use the filtered list length
                    itemBuilder: (context, index) {
                      final jadwal = _filteredBookings[index]; // Get item from filtered list
                      // Build the list item widget
                      return _buildBookingListItem(jadwal, theme);
                    },
                    // Divider between items
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

  // --- Helper for Building Filter Chips ---
  Widget _buildFilterChip({required String label, required String value, required ThemeData theme}) {
    final bool isSelected = _selectedFilterChip == value; // Check if this chip is the active filter
    return Padding(
      padding: const EdgeInsets.only(right: 6.0), // Space between chips
      child: FilterChip(
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12, // Slightly smaller font for chips
          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withOpacity(0.8),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, // Bold when selected
        ),
        selected: isSelected, // Set the visual selected state
        onSelected: (bool selected) {
          // Handle chip selection/deselection logic
          setState(() {
            if (selected) {
              _selectedFilterChip = value; // Set this chip as the active filter
              // --- Placeholder Logic for complex filters ---
            if (value == 'Ruangan') {
                // TODO: Open room selection dialog/bottomsheet
                _showSnackBar("Filter Ruangan belum diimplementasikan.", isError: true);
                _selectedFilterChip = null; // Reset selection
              } else if (value == 'Status') {
                // TODO: Open status selection dialog/bottomsheet
                _showSnackBar("Filter Status belum diimplementasikan.", isError: true);
                _selectedFilterChip = null; // Reset selection
              }
              // For specific value chips (like 'Pending', 'Biomasa'),
              // the _selectedFilterChip state itself drives the filter in _applyFilters.
            } else {
              // If a chip is deselected, clear the active filter chip
              _selectedFilterChip = null;
              // Optionally reset specific filter variables if needed
              // _selectedFilterDate = null;
              // _selectedFilterStatus = null;
              // _selectedFilterRoomName = null;
            }
            _applyFilters(); // Re-apply filters based on the new state
          });
        },
        selectedColor: theme.colorScheme.primary.withOpacity(0.8), // Color when the chip is selected
        checkmarkColor: theme.colorScheme.onPrimary, // Color of the checkmark (if shown)
        backgroundColor: theme.chipTheme.backgroundColor ?? theme.cardColor, // Background when not selected
        side: isSelected ? BorderSide.none : BorderSide(color: theme.dividerColor.withOpacity(0.5)), // Border when not selected
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)), // More rounded shape for chips
        visualDensity: const VisualDensity(horizontal: 0.0, vertical: -2), // Make chip vertically smaller
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0), // Adjust Internal padding
      ),
    );
  }


  // --- Widget Builder for each item in the "List Peminjaman" tab ---
  Widget _buildBookingListItem(JadwalRapat jadwal, ThemeData theme) {
    Color statusColor;
    String statusText;
    // Determine status text and color based on jadwal.status
    switch (jadwal.status) {
      case 1: statusColor = Colors.orange; statusText = 'PENDING'; break;
      case 2: statusColor = Colors.green; statusText = 'DISETUJUI'; break;
      case 3: statusColor = Colors.red; statusText = 'DITOLAK'; break;
      default: statusColor = Colors.grey; statusText = '???'; // Handle unknown status
    }
    // Format time range and calculate duration using helper functions
    final timeRange = _formatTimeRange(jadwal.jamMulai, jadwal.jamSelesai);
    final durationString = _calculateDuration(jadwal.jamMulai, jadwal.jamSelesai);
    final bool isDark = theme.brightness == Brightness.dark; // Check theme brightness

    // Use InkWell for tap feedback, though no action is currently assigned
    return InkWell(
      // onTap: () { /* Optional: Navigate to detail view or trigger edit? */ },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // Padding for each list item
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Align content to the top
          children: [
            // Left Column: Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align text left
                children: [
                  // Agenda and Participant Count
                  Text(
                    "${jadwal.agenda} (${jadwal.jumlahPeserta} Org)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      // Badge background: semi-transparent status color
                        color: statusColor.withOpacity(isDark ? 0.3 : 0.15),
                        borderRadius: BorderRadius.circular(10), // Rounded corners
                        // Subtle border matching the status color
                        border: Border.all(color: statusColor.withOpacity(0.5), width: 0.5)
                    ),
                    child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),),
                  ),
                  const SizedBox(height: 8),
                  // Other Details using helper function
                  _buildDetailRowList(null, // No icon version
                      "Tanggal Peminjaman : ${DateFormat('dd-MM-yyyy - HH:mm', 'id_ID').format(jadwal.tanggal)}", theme),
                  _buildDetailRowList(null,
                      "Waktu : $timeRange ($durationString)", theme),
                  _buildDetailRowList(null,
                      "Keterangan : ${jadwal.ruangan}", theme), // Room shown as Keterangan
                  _buildDetailRowList(null,
                      "PIC : ${jadwal.pic}", theme),
                  _buildDetailRowList(null,
                      jadwal.divisi, theme), // Division
                ],
              ),
            ),
            // Right side: Action Menu Button (...)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: theme.hintColor), // Three dots icon
              tooltip: "Opsi", // Accessibility tooltip
              enabled: !_isProcessingAction, // Disable button while an action is running
              onSelected: (String action) => _handleAction(action, jadwal), // Callback on selection
              // Logic to show/hide menu items based on status
              itemBuilder: (BuildContext context) {
                List<PopupMenuEntry<String>> items = [];
                // Show 'Setujui' only if status allows approval (e.g., Pending or maybe Ditolak)
                if (jadwal.status != 2) { // Show if NOT already Approved
                  items.add(_buildPopupMenuItem('approve', Icons.check_circle_outline, 'Setujui', Colors.green));
                }
                // Show 'Tolak' only if status allows rejection (e.g., Pending or maybe Disetujui)
                if (jadwal.status != 3) { // Show if NOT already Rejected
                  items.add(_buildPopupMenuItem('reject', Icons.cancel_outlined, 'Tolak', Colors.orange));
                }
                // Add divider if there were status change options AND delete will be added
                // Corrected logic: Add divider only if both approve/reject options would be shown
                if (jadwal.status != 2 && jadwal.status != 3) {
                  items.add(const PopupMenuDivider());
                } else if (items.isNotEmpty) { // Add divider if at least one status option is shown before delete
                  items.add(const PopupMenuDivider());
                }

                // Always show 'Hapus' (or add conditions if needed)
                items.add(_buildPopupMenuItem('delete', Icons.delete_outline, 'Hapus', Colors.red));
                return items;
              },
            ),
          ],
        ),
      ),
    );
  }


  // Helper to calculate duration string
  String _calculateDuration(String startTime, String endTime) {
    try {
      // Ensure parsing handles potential variations if needed, otherwise stick to HH:mm:ss
      final start = DateFormat("HH:mm:ss").parseStrict(startTime);
      final end = DateFormat("HH:mm:ss").parseStrict(endTime);
      final duration = end.difference(start);
      if (duration.isNegative) return "Invalid"; // Return specific text for invalid duration
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      List<String> parts = [];
      if (hours > 0) parts.add("$hours jam");
      if (minutes > 0) parts.add("$minutes mnt");
      return parts.isEmpty ? "0 mnt" : parts.join(" ");
    } catch (e) {
      print("Error calculating duration ($startTime - $endTime): $e");
      return "-"; // Placeholder on error
    }
  }

  // --- Helper for Building Detail Rows in List Item (No Icon) ---
  Widget _buildDetailRowList(IconData? icon, String text, ThemeData theme) {
    // Icon parameter is kept for potential future use, but not displayed now
    return Padding(
      padding: const EdgeInsets.only(top: 4.0), // Vertical spacing for detail lines
      child: Text(
        text,
        // Style adjusted to look similar to the reference image
        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 13),
        // overflow: TextOverflow.ellipsis, // Consider removing ellipsis if wrapping is okay
        // maxLines: 2, // Allow wrapping up to 2 lines if needed
      ),
    );
  }

  // --- Helper for Building Popup Menu Items ---
  PopupMenuItem<String> _buildPopupMenuItem(String value, IconData icon, String title, Color color) {
    // Creates a standard menu item with an icon, text, and associated value
    return PopupMenuItem<String>(
      value: value, // The value returned when this item is selected
      height: 40, // Make items a bit shorter
      child: Row( // Use Row for better control over spacing
        children: [
          Icon(icon, color: color, size: 20), // Icon size
          const SizedBox(width: 12), // Space between icon and text
          Text(title), // Text label
        ],
      ),
    );
  }

  // --- Helper to Format Time Range (HH:mm - HH:mm) ---
  String _formatTimeRange(String startTime, String endTime) {
    // Basic check for minimum expected length "HH:mm"
    if (startTime.length < 5 || endTime.length < 5) {
      // Log a warning if the format seems incorrect
      print("Warning: Invalid time format received '$startTime' - '$endTime'");
      // Return the original strings as a fallback
      return "$startTime - $endTime";
    }
    try {
      // Extract the first 5 characters (HH:mm part) from both strings
      String start = startTime.substring(0, 5);
      String end = endTime.substring(0, 5);
      // Combine them with a separator
      return "$start - $end";
    } catch (e) {
      // Log any error during substring operation
      print("Error formatting time range ($startTime - $endTime): $e");
      // Return original strings as a fallback on error
      return "$startTime - $endTime";
    }
  }

} // End of _AdminPageState class
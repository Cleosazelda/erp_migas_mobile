import 'dart:convert'; // Needed for jsonEncode
import 'dart:async'; // Needed for Future and TimeoutException
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Needed for http calls
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import for Indonesian locale

// Import services, models, and other pages
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
  late Future<List<JadwalRapat>> _futureJadwal;
  bool _isProcessingAction = false; // Flag to indicate if an API call is in progress

  // Room list and selection are no longer needed for the List Peminjaman tab state
  // List<Map<String, dynamic>> _ruanganList = [];
  // int? _selectedRuanganId;
  // bool _isLoadingRooms = false;

  @override
  void initState() {
    super.initState();
    // Initialize the TabController with 2 tabs
    _tabController = TabController(length: 2, vsync: this);
    // Ensure Indonesian date formatting is initialized, then load initial data
    initializeDateFormatting('id_ID', null).then((_) {
      if (mounted) { // Check if the widget is still in the tree
        _loadJadwal(); // Load schedule data
        // _loadRuanganList(); // No longer needed
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose(); // Clean up the TabController
    super.dispose();
  }

  // --- Load/Reload Schedule Data ---
  void _loadJadwal() {
    if (!mounted) return; // Don't call setState if widget is disposed
    setState(() {
      // Fetch ALL schedules (all statuses) using the API service
      _futureJadwal = JadwalApiService.getAllJadwal();
    });
  }

  // --- Show Snackbar Helper ---
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return; // Check mount status
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green, // Use red for errors, green for success
        behavior: SnackBarBehavior.floating, // Make snackbar float above bottom elements
      ),
    );
  }

  // --- Logout Function ---
  Future<void> _logout() async {
    // Show confirmation dialog before proceeding
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

    // If user confirmed logout
    if (shouldLogout == true) {
      await ApiService.logout(); // Call the service to clear the token
      if (mounted) {
        // Navigate back to the LoginPage and remove all previous routes from the stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
        );
      }
    }
  }

  // --- Navigate to Add Schedule Page ---
  void _openTambahJadwal() async {
    // Show the TambahJadwalPage within a Dialog for a modal presentation
    final result = await showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16), // Add padding around the dialog
        // Pass the current user's name to the add page
        child: TambahJadwalPage(namaPengguna: "${widget.firstName} ${widget.lastName}"),
      ),
    );
    // If the dialog returns true (indicating a successful save), reload the schedule list
    if (result == true && mounted) {
      _loadJadwal();
    }
  }

  // --- API Call: Update Booking Status ---
  Future<void> _updateBookingStatus(JadwalRapat jadwal, int newStatus) async {
    if (_isProcessingAction) return; // Prevent concurrent calls
    if (!mounted) return;

    setState(() => _isProcessingAction = true); // Set flag to disable UI elements

    // Construct the API endpoint URL dynamically using jadwal.id
    final url = Uri.parse("${ApiService.baseUrl}/ruang-rapat/${jadwal.id}/status");
    // Prepare the request body as JSON, containing the new status
    final body = jsonEncode({"status": newStatus});
    // Get headers (which should include the Authorization token from ApiService)
    final headers = ApiService.headers;

    // *** Crucial Check: Ensure Authorization header is present ***
    if (!headers.containsKey('Authorization')) {
      _showSnackBar("Error: Token otorisasi tidak ditemukan. Silakan login ulang.", isError: true);
      if (mounted) setState(() => _isProcessingAction = false); // Reset flag
      return; // Stop execution if no token
    }
    // Add Content-Type header explicitly if not already present in ApiService.headers
    headers['Content-Type'] = 'application/json';


    print('Updating Status for ID: ${jadwal.id}'); // Debug print
    print('URL: $url'); // Debug print
    print('Headers: $headers'); // Debug print (Ensure Authorization is there)
    print('Body: $body'); // Debug print
    print('Method: PATCH'); // Logging the method being used

    try {
      // Make the PATCH request to update the status
      final response = await http.patch( // <-- Use http.patch
        url,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 20)); // Set a timeout duration

      if (!mounted) return; // Check mount status again after await

      print('Update Status Response Code: ${response.statusCode}'); // Debug print
      print('Update Status Response Body: ${response.body}'); // Debug print


      // Check response status code for success (200 OK is typical for PATCH updates)
      if (response.statusCode == 200) {
        _showSnackBar("Status untuk '${jadwal.agenda}' berhasil diperbarui.");
        _loadJadwal(); // Refresh the list to reflect the change
      } else {
        // Handle API error
        String errorMessage = "Gagal update status (Code: ${response.statusCode})";
        try {
          // Attempt to parse a more specific error message from the response body
          final errorData = jsonDecode(response.body);
          errorMessage += ": ${errorData?['message'] ?? response.body}";
        } catch (_) {
          // Fallback if the response body is not JSON or lacks a 'message' field
          errorMessage += ": ${response.body}";
        }
        _showSnackBar(errorMessage, isError: true);
      }
    } on TimeoutException {
      // Handle network timeout
      if (mounted) _showSnackBar("Koneksi timeout saat update status. Periksa jaringan Anda.", isError: true);
    } catch (e) {
      // Handle any other exceptions during the API call
      if (mounted) _showSnackBar("Terjadi kesalahan saat update status: ${e.toString()}", isError: true);
    } finally {
      // IMPORTANT: Always reset the processing flag in the finally block
      if (mounted) {
        setState(() => _isProcessingAction = false);
      }
    }
  }

  // --- API Call: Delete Booking ---
  Future<void> _deleteBooking(JadwalRapat jadwal) async {
    if (_isProcessingAction) return; // Prevent concurrent calls
    if (!mounted) return;

    // Show confirmation dialog before deleting
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: Text("Anda yakin ingin menghapus jadwal '${jadwal.agenda}'? Tindakan ini tidak dapat dibatalkan."),
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

    // If user cancels, stop the function
    if (confirmDelete != true) return;

    setState(() => _isProcessingAction = true); // Set flag

    // Construct the API URL for the DELETE request
    final url = Uri.parse("${ApiService.baseUrl}/ruang-rapat/${jadwal.id}");
    // Get headers (including Authorization token)
    final headers = ApiService.headers;

    // Ensure token exists
    if (!headers.containsKey('Authorization')) {
      _showSnackBar("Error: Token otorisasi tidak ditemukan.", isError: true);
      if (mounted) setState(() => _isProcessingAction = false);
      return;
    }

    print('Deleting Booking ID: ${jadwal.id}'); // Debug print
    print('URL: $url'); // Debug print
    print('Headers: $headers'); // Debug print


    try {
      // Make the DELETE request
      final response = await http.delete(url, headers: headers)
          .timeout(const Duration(seconds: 20)); // Set timeout

      if (!mounted) return; // Check mount status after await

      print('Delete Response Code: ${response.statusCode}'); // Debug print
      print('Delete Response Body: ${response.body}'); // Debug print


      // Check for success status codes (200 OK or 204 No Content are common for DELETE)
      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSnackBar("Jadwal '${jadwal.agenda}' berhasil dihapus.");
        _loadJadwal(); // Refresh the list
      } else {
        // Handle API error
        String errorMessage = "Gagal menghapus (Code: ${response.statusCode})";
        try {
          final errorData = jsonDecode(response.body);
          errorMessage += ": ${errorData?['message'] ?? response.body}";
        } catch (_) {
          errorMessage += ": ${response.body}";
        }
        _showSnackBar(errorMessage, isError: true);
      }
    } on TimeoutException {
      // Handle network timeout
      if (mounted) _showSnackBar("Koneksi timeout saat menghapus.", isError: true);
    } catch (e) {
      // Handle any other exceptions
      if (mounted) _showSnackBar("Terjadi kesalahan saat menghapus: ${e.toString()}", isError: true);
    } finally {
      // IMPORTANT: Always reset the processing flag
      if (mounted) {
        setState(() => _isProcessingAction = false);
      }
    }
  }

  // --- Show Confirmation Dialog for Status Change ---
  Future<void> _showConfirmationDialog(JadwalRapat jadwal, String actionType) async {
    if (_isProcessingAction) return; // Don't show dialog if already processing
    if (!mounted) return;

    // Determine texts based on action
    String title = actionType == 'approve' ? 'Konfirmasi Setujui' : 'Konfirmasi Tolak';
    String content = actionType == 'approve'
        ? 'Anda yakin ingin menyetujui jadwal "${jadwal.agenda}"?'
        : 'Anda yakin ingin menolak jadwal "${jadwal.agenda}"?';
    String confirmButtonText = actionType == 'approve' ? 'Setujui' : 'Tolak';
    Color confirmButtonColor = actionType == 'approve' ? Colors.green : Colors.orange;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must choose an action
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop(false); // Return false if cancelled
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: confirmButtonColor),
              child: Text(confirmButtonText, style: const TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(true); // Return true if confirmed
              },
            ),
          ],
        );
      },
    );

    // If user confirmed in the dialog
    if (confirmed == true && mounted) {
      // Determine the new status code based on the action
      int newStatus = (actionType == 'approve') ? 2 : 3;
      // Call the API function to update the status
      _updateBookingStatus(jadwal, newStatus);
    }
  }

  // --- Handle Action Selection from Popup Menu ---
  void _handleAction(String action, JadwalRapat jadwal) {
    if (_isProcessingAction) {
      _showSnackBar("Harap tunggu proses sebelumnya selesai.", isError: true);
      return;
    }
    // Show confirmation dialog for approve and reject actions
    switch (action) {
      case 'approve':
      case 'reject':
        _showConfirmationDialog(jadwal, action); // Call confirmation dialog first
        break;
      case 'delete':
        _deleteBooking(jadwal); // Delete uses its own confirmation dialog
        break;
    }
  }


  // --- Date Picker Logic (Only for Ruang Rapat tab now) ---
  void _pickDate() async {
    final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate, // Start picker at the currently selected date
        firstDate: DateTime(2020), // Earliest selectable date
        lastDate: DateTime(2030), // Latest selectable date
        builder: (context, child) {
          // Apply custom theme to the date picker dialog
          final theme = Theme.of(context);
          return Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                primary: Colors.green, // Header background color
                onPrimary: Colors.white, // Header text color
                onSurface: theme.colorScheme.onSurface, // Date text color in the calendar
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
    // If a date was picked and it's different from the current one, update the state
    // This only affects the "Ruang Rapat" tab's filter now
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Format date for display using Indonesian locale (e.g., "Senin, 27 Oktober 2025")
  String _formatDate(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
  }

  // --- Build Method: Constructs the UI ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get current theme data
    final String fullName = "${widget.firstName} ${widget.lastName}"; // Combine names
    final isDark = theme.brightness == Brightness.dark; // Check if dark mode is active

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Use theme's background color
      // Configure the AppBar
      appBar: AppBar(
        // Title section with logo, title, and welcome message
        title: Row(
          children: [
            Image.asset("assets/images/logo.png", height: 30), // App logo
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
        // Style AppBar based on theme
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 1, // Add a subtle shadow
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface), // Color for drawer icon
        actionsIconTheme: IconThemeData(color: theme.colorScheme.onSurface), // Color for action icons
        // Action buttons on the right
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Refresh Data",
              // Disable button if an action is processing
              onPressed: _isProcessingAction ? null : _loadJadwal),
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Logout",
              // Disable button if an action is processing
              onPressed: _isProcessingAction ? null : _logout),
        ],
        // TabBar added below the main AppBar content
        bottom: TabBar(
          controller: _tabController, // Link to the TabController
          labelColor: Colors.green, // Color for the selected tab's text
          unselectedLabelColor: theme.hintColor, // Color for inactive tabs' text
          indicatorColor: Colors.green, // Color of the underline indicator
          tabs: const [
            Tab(text: "Ruang Rapat"), // First tab label
            Tab(text: "List Peminjaman"), // Second tab label (Updated Name)
          ],
        ),
      ),
      // TabBarView holds the content for each tab
      body: TabBarView(
        controller: _tabController, // Link to the TabController
        children: [
          _buildRuangRapatTab(theme), // Widget builder for the first tab
          _buildListPeminjamanTabNew(theme), // Widget builder for the second tab (the new list view)
        ],
      ),
      // Floating Action Button for adding new schedules
      floatingActionButton: FloatingActionButton(
        onPressed: _isProcessingAction ? null : _openTambahJadwal, // Disable if processing
        backgroundColor: _isProcessingAction ? Colors.grey : Colors.green, // Visual feedback when disabled
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Tambah Jadwal Baru',
      ),
    );
  }

  // --- Widget Builder for "Ruang Rapat" Tab Content ---
  // (Shows visual schedule table for APPROVED bookings on _selectedDate)
  Widget _buildRuangRapatTab(ThemeData theme) {
    return Container(
      color: theme.scaffoldBackgroundColor, // Use theme background color
      child: Column(
        children: [
          // Date selector widget specific to this tab
          _buildDateSelector(theme),
          // Expanded FutureBuilder to display the schedule table
          Expanded(
            child: FutureBuilder<List<JadwalRapat>>(
              future: _futureJadwal,
              builder: (context, snapshot) {
                // Show loading indicator
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Show error message with retry button
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column( // Display error and retry button
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
                          const SizedBox(height: 10),
                          Text("Gagal memuat jadwal visual: ${snapshot.error}", textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          ElevatedButton(onPressed: _loadJadwal, child: const Text("Coba Lagi"))
                        ],
                      ),
                    ),
                  );
                }
                // Process and display data if loaded successfully
                final allJadwal = snapshot.data ?? [];

                // Filter data: Only show APPROVED schedules (status 2) for the selected date
                final displayedJadwal = allJadwal.where((jadwal) {
                  // Check if status is 2 and the date matches _selectedDate (ignoring time)
                  return jadwal.status == 2 && DateUtils.isSameDay(jadwal.tanggal, _selectedDate);
                }).toList();

                // Use the JadwalTable widget (imported from DigiAm folder)
                return JadwalTable(jadwalList: displayedJadwal);
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
      // Background color matches AppBar for consistency
      color: isDark ? Colors.grey[900] : Colors.white,
      padding: const EdgeInsets.all(16), // Padding around the selectors
      child: Column(
        children: [
          // Row for Prev/Today/Next buttons
          Row(
            children: [
              Expanded(child: _dateButton("< Prev", () {
                // Go to previous day, update state
                if (mounted) setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
              })),
              const SizedBox(width: 10), // Spacing between buttons
              Expanded(child: _dateButton("Today", () {
                // Go to today's date, update state
                if (mounted) setState(() => _selectedDate = DateTime.now());
              })),
              const SizedBox(width: 10),
              Expanded(child: _dateButton("Next >", () {
                // Go to next day, update state
                if (mounted) setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
              })),
            ],
          ),
          const SizedBox(height: 16), // Space between buttons and date field
          // TextFormField acting as a button to open the date picker
          TextFormField(
            readOnly: true, // Not directly editable
            onTap: _pickDate, // Call date picker function on tap
            // Controller displays the formatted selected date
            controller: TextEditingController(text: _formatDate(_selectedDate)),
            // Styling for the date field
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: Icon(Icons.calendar_today, color: theme.hintColor), // Calendar icon
              // Border styling based on theme
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
              ),
            ),
            // Text color matches theme
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  // --- Helper for Date Navigation Buttons ---
  ElevatedButton _dateButton(String label, VoidCallback onPressed) {
    // Standard green button for date navigation
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

  // --- Widget Builder for "List Peminjaman" Tab Content (Vertical List Style) ---
  Widget _buildListPeminjamanTabNew(ThemeData theme) {
    return Container(
      color: theme.scaffoldBackgroundColor, // Use theme background
      child: FutureBuilder<List<JadwalRapat>>(
        future: _futureJadwal, // Fetch all schedules
        builder: (context, snapshot) {
          // Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Error State
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 40),
                    const SizedBox(height: 10),
                    Text("Gagal memuat list: ${snapshot.error}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: _loadJadwal, child: const Text("Coba Lagi"))
                  ],
                ),
              ),
            );
          }
          // No Data State
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Tidak ada data peminjaman."));
          }

          // Data Loaded Successfully
          final allJadwal = snapshot.data!;

          // Sort by date descending (newest first), then by start time ascending
          allJadwal.sort((a, b) {
            int dateComparison = b.tanggal.compareTo(a.tanggal); // Newest date first
            if (dateComparison != 0) {
              return dateComparison;
            } else {
              // If dates are the same, sort by start time ascending
              try {
                final timeA = int.parse(a.jamMulai.replaceAll(':', ''));
                final timeB = int.parse(b.jamMulai.replaceAll(':', ''));
                return timeA.compareTo(timeB);
              } catch (e) {
                print("Error sorting times during secondary sort: $e");
                return 0;
              }
            }
          });


          // Build the list using RefreshIndicator and ListView.separated
          return RefreshIndicator(
            onRefresh: () async => _loadJadwal(), // Enable pull-to-refresh
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8.0), // Padding above/below list
              itemCount: allJadwal.length, // Total number of items
              itemBuilder: (context, index) {
                final jadwal = allJadwal[index];
                // Use the list item builder for each booking
                return _buildBookingListItem(jadwal, theme);
              },
              // Add dividers between list items
              separatorBuilder: (context, index) => Divider(
                height: 1, // Minimal height for the divider line
                thickness: 0.5, // Make the line thin
                color: theme.dividerColor.withOpacity(0.3), // Subtle divider color
                indent: 16, // Indent from the left edge
                endIndent: 16, // Indent from the right edge
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Widget Builder for each item in the "List Peminjaman" tab (Vertical List Style) ---
  Widget _buildBookingListItem(JadwalRapat jadwal, ThemeData theme) {
    Color statusColor;
    String statusText;
    // Determine status text and color
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

    // Use InkWell for potential future tap interactions on the whole row
    return InkWell(
      // onTap: () { /* Optional: Navigate to detail view or trigger edit? */ },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // Padding for each list item
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
          children: [
            // Left side: Booking Details (takes most space)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                children: [
                  // Agenda (Title) and Participant Count
                  Text(
                    "${jadwal.agenda} (${jadwal.jumlahPeserta} Org)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    maxLines: 2, // Allow up to 2 lines for agenda
                    overflow: TextOverflow.ellipsis, // Add '...' if longer
                  ),
                  const SizedBox(height: 6), // Space below agenda
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
                  const SizedBox(height: 8), // Space below status
                  // Additional Details (like the reference image)
                  _buildDetailRowList(null, // No icon shown in reference image for this line
                      "Tanggal Peminjaman : ${DateFormat('dd-MM-yyyy - HH:mm', 'id_ID').format(jadwal.tanggal)}", theme), // Combined Date and Submission Time?
                  _buildDetailRowList(null, // No icon
                      "Waktu : $timeRange ($durationString)", theme), // Include calculated duration
                  _buildDetailRowList(null, // No icon
                      "Keterangan : ${jadwal.ruangan}", theme), // Show Room name as Keterangan
                  _buildDetailRowList(null, // No icon
                      "PIC : ${jadwal.pic}", theme), // Show PIC
                  _buildDetailRowList(null, // No icon
                      jadwal.divisi, theme), // Show Division

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

                // Show 'Setujui' only if status is NOT 'Disetujui' (i.e., Pending or Ditolak)
                if (jadwal.status != 2) {
                  items.add(_buildPopupMenuItem('approve', Icons.check_circle_outline, 'Setujui', Colors.green));
                }
                // Show 'Tolak' only if status is NOT 'Ditolak' (i.e., Pending or Disetujui)
                if (jadwal.status != 3) {
                  items.add(_buildPopupMenuItem('reject', Icons.cancel_outlined, 'Tolak', Colors.orange));
                }
                // Add divider if both status change options and delete option will be present
                if (items.isNotEmpty) {
                  items.add(const PopupMenuDivider());
                }
                // Always show 'Hapus'
                items.add(_buildPopupMenuItem('delete', Icons.delete_outline, 'Hapus', Colors.red));

                return items; // Return the constructed list of menu items
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper to calculate duration string (e.g., "2 jam", "30 mnt", "1 jam 15 mnt")
  String _calculateDuration(String startTime, String endTime) {
    try {
      // Assuming format is HH:mm:ss, parse them relative to a common date
      final start = DateFormat("HH:mm:ss").parse(startTime);
      final end = DateFormat("HH:mm:ss").parse(endTime);
      // Calculate the difference
      final duration = end.difference(start);

      // Handle cases where end time might be on the next day (or invalid negative duration)
      if (duration.isNegative) return "Durasi tidak valid"; // More descriptive error

      final hours = duration.inHours; // Get total hours
      final minutes = duration.inMinutes % 60; // Get remaining minutes

      // Build the duration string
      List<String> parts = [];
      if (hours > 0) {
        parts.add("$hours jam"); // Add hours part if > 0
      }
      if (minutes > 0) {
        parts.add("$minutes mnt"); // Add minutes part if > 0
      }
      // If duration is exactly 0 or less than a minute, show "0 mnt"
      return parts.isEmpty ? "0 mnt" : parts.join(" "); // Join with space if both parts exist
    } catch (e) {
      // Log error if time parsing fails
      print("Error calculating duration ($startTime - $endTime): $e");
      return "-"; // Return placeholder on error
    }
  }


  // --- Helper for Building Detail Rows in the List Item --- (No Icon version, adjusted style)
  Widget _buildDetailRowList(IconData? icon, String text, ThemeData theme) {
    // Icon parameter is kept for potential future use, but not displayed now
    return Padding(
      padding: const EdgeInsets.only(top: 4.0), // Vertical spacing for detail lines
      child: Text(
        text,
        // Style adjusted to look similar to the reference image
        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 13),
        // Allow text wrapping
        // overflow: TextOverflow.ellipsis, // Remove ellipsis to allow wrapping
        // maxLines: 2, // Allow up to 2 lines if needed
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
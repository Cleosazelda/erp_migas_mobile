import 'dart:convert';
import 'dart:math';

class MockApiService {
  static const bool USE_MOCK = false; // Set false when backend ready
  static String? _token;

  // Mock data
  static List<Map<String, dynamic>> _mockUsers = [
    {
      "id": 1,
      "nama": "Andi Pratama",
      "email": "andi@muj.co.id",
      "jabatan": "Staff Finance",
      "divisi": "Finance",
      "role": "user"
    },
    {
      "id": 2,
      "nama": "Budi Santoso",
      "email": "budi@muj.co.id",
      "jabatan": "Manager IT",
      "divisi": "IT",
      "role": "admin"
    },
    {
      "id": 3,
      "nama": "Hadi",
      "email": "hadiramdani2@gmail.com",
      "jabatan": "Staff PBJ & IT",
      "divisi": "PBJ & IT",
      "role": "user"
    },
    {
      "id": 4,
      "nama": "Dedy Kurniawan",
      "email": "dedy@muj.co.id",
      "jabatan": "Staff Operasional",
      "divisi": "Operasional",
      "role": "user"
    },
    {
      "id": 5,
      "nama": "Eka Sari",
      "email": "eka@muj.co.id",
      "jabatan": "Staff Finance",
      "divisi": "Finance",
      "role": "user"
    },
  ];

  static List<String> _mockDivisions = [
    "Finance",
    "IT",
    "HR",
    "Operasional"
  ];

  static Map<String, dynamic>? _currentUser;

  // Setter untuk menyimpan token setelah login
  static void setToken(String token) {
    _token = token;
  }

  // Simulate network delay
  static Future<void> _simulateNetworkDelay() async {
    await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(1000)));
  }

  // Login - POST /login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    await _simulateNetworkDelay();

    // Mock login validation
    if (email.isEmpty || password.isEmpty) {
      throw Exception("Email dan password harus diisi");
    }

    // Find user by email
    Map<String, dynamic>? user;
    try {
      user = _mockUsers.firstWhere((u) => u['email'] == email);
    } catch (e) {
      return {
        "status": "error",
        "message": "Email atau password salah"
      };
    }

    // Simple password check (in real app, this would be hashed)
    if (password != "password123") {
      return {
        "status": "error",
        "message": "Email atau password salah"
      };
    }

    // Set current user and generate mock token
    _currentUser = Map<String, dynamic>.from(user);
    String mockToken = "mock_token_${user['id']}_${DateTime.now().millisecondsSinceEpoch}";
    setToken(mockToken);

    return {
      "status": "success",
      "user": user,
      "token": mockToken
    };
  }

  // Logout - POST /logout
  static Future<Map<String, dynamic>> logout() async {
    await _simulateNetworkDelay();

    _token = null;
    _currentUser = null;

    return {
      "status": "success",
      "message": "Logout berhasil"
    };
  }

  // Get User Profile - GET /profile
  static Future<Map<String, dynamic>> getProfile() async {
    await _simulateNetworkDelay();

    if (_token == null || _currentUser == null) {
      throw Exception("Unauthorized - Token tidak valid");
    }

    return {
      "status": "success",
      "user": _currentUser
    };
  }

  // Update User Profile - PUT /profile
  static Future<Map<String, dynamic>> updateProfile({
    String? nama,
    String? email,
    String? jabatan,
    String? divisi,
  }) async {
    await _simulateNetworkDelay();

    if (_token == null || _currentUser == null) {
      throw Exception("Unauthorized - Token tidak valid");
    }

    // Update current user data
    if (nama != null) _currentUser!['nama'] = nama;
    if (email != null) _currentUser!['email'] = email;
    if (jabatan != null) _currentUser!['jabatan'] = jabatan;
    if (divisi != null) _currentUser!['divisi'] = divisi;


    int userIndex = _mockUsers.indexWhere((u) => u['id'] == _currentUser!['id']);
    if (userIndex != -1) {
      _mockUsers[userIndex] = Map<String, dynamic>.from(_currentUser!);
    }

    return {
      "status": "success",
      "message": "Profile berhasil diperbarui",
      "user": _currentUser
    };
  }

  // ========== ADMIN ENDPOINTS ==========

  // Get All Users - GET /admin/users
  static Future<List<Map<String, dynamic>>> getUsers() async {
    await _simulateNetworkDelay();

    if (_token == null || _currentUser == null || _currentUser!['role'] != 'admin') {
      throw Exception("Forbidden - Admin access required");
    }

    return _mockUsers;
  }

  // Add User - POST /admin/users
  static Future<Map<String, dynamic>> addUser({
    required String nama,
    required String email,
    required String password,
    required String jabatan,
    required String divisi,
    String role = 'user',
  }) async {
    await _simulateNetworkDelay();

    if (_token == null || _currentUser == null || _currentUser!['role'] != 'admin') {
      throw Exception("Forbidden - Admin access required");
    }

    // Check if email already exists
    bool emailExists = _mockUsers.any((u) => u['email'] == email);
    if (emailExists) {
      return {
        "status": "error",
        "message": "Email sudah digunakan"
      };
    }

    // Create new user
    int newId = _mockUsers.length + 1;
    Map<String, dynamic> newUser = {
      "id": newId,
      "nama": nama,
      "email": email,
      "jabatan": jabatan,
      "divisi": divisi,
      "role": role,
    };

    _mockUsers.add(newUser);

    return {
      "status": "success",
      "message": "User berhasil ditambahkan",
      "user": newUser
    };
  }

  // Update User - PUT /admin/users/{id}
  static Future<Map<String, dynamic>> updateUser(int userId, {
    String? nama,
    String? email,
    String? jabatan,
    String? divisi,
    String? role,
  }) async {
    await _simulateNetworkDelay();

    if (_token == null || _currentUser == null || _currentUser!['role'] != 'admin') {
      throw Exception("Forbidden - Admin access required");
    }

    int userIndex = _mockUsers.indexWhere((u) => u['id'] == userId);
    if (userIndex == -1) {
      return {
        "status": "error",
        "message": "User tidak ditemukan"
      };
    }

    // Update user data
    if (nama != null) _mockUsers[userIndex]['nama'] = nama;
    if (email != null) _mockUsers[userIndex]['email'] = email;
    if (jabatan != null) _mockUsers[userIndex]['jabatan'] = jabatan;
    if (divisi != null) _mockUsers[userIndex]['divisi'] = divisi;
    if (role != null) _mockUsers[userIndex]['role'] = role;

    return {
      "status": "success",
      "message": "User berhasil diperbarui",
      "user": _mockUsers[userIndex]
    };
  }

  // Delete User - DELETE /admin/users/{id}
  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    await _simulateNetworkDelay();

    if (_token == null || _currentUser == null || _currentUser!['role'] != 'admin') {
      throw Exception("Forbidden - Admin access required");
    }

    int userIndex = _mockUsers.indexWhere((u) => u['id'] == userId);
    if (userIndex == -1) {
      return {
        "status": "error",
        "message": "User tidak ditemukan"
      };
    }

    _mockUsers.removeAt(userIndex);

    return {
      "status": "success",
      "message": "User berhasil dihapus"
    };
  }

  // Get All Divisions - GET /admin/divisions
  static Future<List<String>> getDivisions() async {
    await _simulateNetworkDelay();

    if (_token == null || _currentUser == null || _currentUser!['role'] != 'admin') {
      throw Exception("Forbidden - Admin access required");
    }

    return List<String>.from(_mockDivisions);
  }

  // Add Division - POST /admin/divisions
  static Future<Map<String, dynamic>> addDivision(String nama) async {
    await _simulateNetworkDelay();

    if (_token == null || _currentUser == null || _currentUser!['role'] != 'admin') {
      throw Exception("Forbidden - Admin access required");
    }

    if (_mockDivisions.contains(nama)) {
      return {
        "status": "error",
        "message": "Divisi sudah ada"
      };
    }

    _mockDivisions.add(nama);

    return {
      "status": "success",
      "message": "Divisi berhasil ditambahkan",
      "division": {
        "id": _mockDivisions.length,
        "nama": nama
      }
    };
  }

  // Delete Division - DELETE /admin/divisions/{id}
  static Future<Map<String, dynamic>> deleteDivision(int divisionId) async {
    await _simulateNetworkDelay();

    if (_token == null || _currentUser == null || _currentUser!['role'] != 'admin') {
      throw Exception("Forbidden - Admin access required");
    }

    if (divisionId <= 0 || divisionId > _mockDivisions.length) {
      return {
        "status": "error",
        "message": "Divisi tidak ditemukan"
      };
    }

    _mockDivisions.removeAt(divisionId - 1);

    return {
      "status": "success",
      "message": "Divisi berhasil dihapus"
    };
  }

  // Get Dashboard Stats - GET /admin/dashboard
  static Future<Map<String, dynamic>> getDashboardStats() async {
    await _simulateNetworkDelay();

    if (_token == null || _currentUser == null || _currentUser!['role'] != 'admin') {
      throw Exception("Forbidden - Admin access required");
    }

    Map<String, int> usersByDivision = {};
    for (String divisi in _mockDivisions) {
      usersByDivision[divisi] = _mockUsers.where((u) => u['divisi'] == divisi).length;
    }

    return {
      "status": "success",
      "totalUsers": _mockUsers.length,
      "totalDivisions": _mockDivisions.length,
      "usersByDivision": usersByDivision,
      "recentUsers": _mockUsers.take(3).toList()
    };
  }

  // Helper method to check if using mock
  static bool get isUsingMock => USE_MOCK;

  // Helper method to reset mock data (for testing)
  static void resetMockData() {
    _token = null;
    _currentUser = null;
    _mockUsers = [
      {
        "id": 1,
        "nama": "Andi Pratama",
        "email": "andi@muj.co.id",
        "jabatan": "Staff Finance",
        "divisi": "Finance",
        "role": "user"
      },
      {
        "id": 2,
        "nama": "Budi Santoso",
        "email": "budi@muj.co.id",
        "jabatan": "Manager IT",
        "divisi": "IT",
        "role": "admin"
      },
      // ... other users
    ];
    _mockDivisions = ["Finance", "IT", "HR", "Operasional"];
  }
}
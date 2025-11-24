import 'package:flutter/material.dart';
import 'home_page.dart';import '../../services/api_service.dart';
import '../erp.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool isLoading = false;

  Future<void> _login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showError("Email dan password tidak boleh kosong.");
      return;
    }
    setState(() => isLoading = true);
    try {
      final response = await ApiService.login(
        emailController.text,
        passwordController.text,
      );
      if (!mounted) return;

      // Check for success and user data presence
      if (response["status"] == "success" && response["user"] != null) {
        final userData = response["user"];
        final firstName = userData["first_name"] ?? "User";
        final lastName = userData["last_name"] ?? "";
        // Extract the role, default to "user" if not present
        final role = userData["role"] ?? "user";

        // --- NAVIGATION LOGIC BASED ON ROLE ---
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                firstName: firstName,
                lastName: lastName,
                isAdmin: role == "admin",
            ),

        ),
    );
        // --- END OF NAVIGATION LOGIC ---

      } else {
        // Handle login failure
        _showError(response["message"] ?? "Login gagal. Periksa kembali kredensial Anda.");
      }
    } catch (e) {
      // Handle exceptions (network errors, etc.)
      if (mounted) {
        _showError(e.toString().replaceFirst("Exception: ", ""));
      }
    } finally {
      // Ensure isLoading is set to false even if errors occur
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }


  void _showError(String message) {
    // Make sure the widget is still mounted before showing SnackBar
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showInfoDialog({required String title, required String message}) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- The rest of your build method remains the same ---
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              color: Theme.of(context).cardColor.withOpacity(0.92),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset("assets/images/logo.png", height: 40),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Login Aplikasi ERP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              SizedBox(height: 4),
                              Text("PT Migas Utama Jabar (Perseroda)", style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            ValueListenableBuilder<ThemeMode>(
                              valueListenable: themeNotifier,
                              builder: (context, mode, _) {
                                final isDark = mode == ThemeMode.dark;
                                return IconButton(
                                  tooltip: isDark ? 'Ubah ke mode terang' : 'Ubah ke mode gelap',
                                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                                  onPressed: () {
                                    themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: const Icon(Icons.email_outlined),
                        // BORDER SAAT TIDAK FOKUS
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey, width: 2),
                        ),

                        // BORDER SAAT FOKUS (DITEKAN)
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.green, width: 2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey, width: 2),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.green, width: 2.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: isLoading ? null : _login,
                        child: isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : const Text("Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
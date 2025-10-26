import 'package:flutter/material.dart';
import 'home_page.dart';
import 'admin/admin_page.dart'; // <-- Import the new AdminPage
import '../../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
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
        if (role == "admin") {
          // Navigate to AdminPage if role is admin
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminPage(
                firstName: firstName,
                lastName: lastName,
              ),
            ),
          );
        } else {
          // Navigate to HomePage for any other role (e.g., "user")
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                firstName: firstName,
                lastName: lastName,
              ),
            ),
          );
        }
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
              color: Colors.white.withOpacity(0.95),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Image.asset("assets/images/logo.png", height: 40),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Login Aplikasi ERP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("PT Migas Utama Jabar (Perseroda)", style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
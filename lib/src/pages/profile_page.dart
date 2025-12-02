import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String division;
  final String company;

  const ProfilePage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.division,
    required this.company,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // DATA
  late String _firstName;
  late String _lastName;
  late String _email;
  late String _division;
  late String _company;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstName = widget.firstName;
    _lastName = widget.lastName;
    _email = widget.email;
    _division = widget.division;
    _company = widget.company;

    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getProfileDivision();
      if (!mounted) return;

      setState(() {
        _firstName = (data['first_name'] ?? _firstName).toString();
        _lastName = (data['last_name'] ?? _lastName).toString();
        _division = (data['organization_name'] ?? _division).toString();
        _company = (data['alias'] ?? data['callsign'] ?? _company).toString();
      });
    } catch (_) {
      // ignore errors silently
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _valueOrDash(String val) => val.isNotEmpty ? val : "-";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullName = "$_firstName $_lastName".trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          children: [
            if (_isLoading) const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 16),


            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              backgroundImage: const AssetImage("assets/images/logo.png"),
            ),

            const SizedBox(height: 18),
            Text(
              fullName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),
            Text(
              _valueOrDash(_email),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),

            const SizedBox(height: 24),

            // =============== CARD DATA PENGGUNA ===============
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Data Pengguna",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),

                  _InfoRow(icon: Icons.badge_outlined, label: "Nama", value: fullName),
                  const Divider(height: 24),

                  _InfoRow(icon: Icons.email_outlined, label: "Email", value: _valueOrDash(_email)),
                  const Divider(height: 24),

                  _InfoRow(icon: Icons.apartment_outlined, label: "Perusahaan", value: _valueOrDash(_company)),
                  const Divider(height: 24),

                  _InfoRow(icon: Icons.business_center_outlined, label: "Divisi", value: _valueOrDash(_division)),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

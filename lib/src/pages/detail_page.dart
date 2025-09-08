import 'package:flutter/material.dart';

class DetailPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;

  const DetailPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              height: 200,
              child: Image.asset(
                image,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.apps,
                      size: 80,
                      color: Colors.green,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Description Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: isDark
                    ? Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Deskripsi Aplikasi",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getDescription(title),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Membuka $title...'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.launch, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Buka Aplikasi",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green,
                      width: 1.5,
                    ),
                  ),
                  child: IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$title ditambahkan ke favorit'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.favorite_border,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDescription(String appTitle) {
    switch (appTitle) {
      case 'DigiAM':
        return 'Aplikasi manajemen aset digital yang membantu dalam pengelolaan dan monitoring aset perusahaan secara real-time dengan fitur tracking, maintenance scheduling, dan reporting yang lengkap.';
      case 'Bisnis AP':
        return 'Platform monitoring bisnis Accounts Payable yang menyediakan dashboard analytics, tracking pembayaran, dan management vendor untuk optimisasi cash flow perusahaan.';
      case 'PBJ':
        return 'Sistem pengelolaan Pengadaan Barang dan Jasa yang mengintegrasikan proses procurement dari planning hingga evaluasi dengan workflow approval yang terintegrasi.';
      case 'Disposisi':
        return 'Aplikasi manajemen surat dan dokumen disposisi untuk mempercepat alur distribusi informasi dan decision making dalam organisasi dengan tracking yang akurat.';
      case 'Talenta':
        return 'Human Resource Management System yang komprehensif meliputi employee management, payroll, attendance, performance evaluation, dan talent development.';
      case 'Mansis':
        return 'Platform manajemen sistem informasi untuk monitoring infrastruktur IT, database management, security monitoring, dan system maintenance scheduling.';
      default:
        return 'Aplikasi yang dirancang khusus untuk mendukung operasional perusahaan dengan fitur-fitur yang terintegrasi dan user-friendly interface.';
    }
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryEntry {
  final String appName;
  final DateTime accessedAt;

  const HistoryEntry({required this.appName, required this.accessedAt});
}

class HistoryPage extends StatelessWidget {
  final List<HistoryEntry> historyItems;

  const HistoryPage({super.key, required this.historyItems});

  String _formatDate(DateTime date) {
    return DateFormat("dd MMMM yyyy, HH.mm").format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "History",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 1,
      ),
      body: historyItems.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: textColor.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              "Belum ada riwayat",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 6),
            Text(
              "Buka salah satu aplikasi untuk memulai daftar riwayat.",
              style: TextStyle(color: textColor.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
              ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: historyItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = historyItems[index];
          return Card(
            elevation: 0,
            color: isDark ? Colors.grey[850] : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history, color: Colors.green),
              ),
              title: Text(
                "Buka ${item.appName}",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _formatDate(item.accessedAt),
                style: TextStyle(color: textColor.withOpacity(0.7)),
              ),
            ),
          );
        },
            ),
    );
  }
}

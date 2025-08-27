import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {

    //ini contoh buat historynya
    final historyItems = [
      "Buka DigiAM - 23 Agustus 2025",
      "Buka PBJ - 22 Agustus 2025",
      "Buka Talenta - 20 Agustus 2025",
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("History")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: historyItems.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text(historyItems[index]),
            ),
          );
        },
      ),
    );
  }
}

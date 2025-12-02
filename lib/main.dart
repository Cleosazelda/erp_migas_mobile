import 'package:flutter/material.dart';
import 'package:erp/src/erp.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async { // <-- 1. Tambahkan 'async'
  // <-- 2. Pastikan baris ini ada SEBELUM pemanggilan async lainnya
  WidgetsFlutterBinding.ensureInitialized();

  // <-- 3. Panggil fungsi inisialisasi SEBELUM runApp()
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ERP();
  }
}
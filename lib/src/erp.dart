import 'package:flutter/material.dart';
import 'pages/login_page.dart';

import 'package:flutter/material.dart';
import 'pages/login_page.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

class ERP extends StatelessWidget {
  const ERP({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: "ERP MUJ",
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,  // PUTIH
            cardColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent, // WAJIB!
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,  // HITAM
            cardColor: Colors.black,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              surfaceTintColor: Colors.transparent, // WAJIB!
              elevation: 0,
            ),
          ),
          themeMode: mode,
          home: const LoginPage(),
        );
      },
    );
  }
}


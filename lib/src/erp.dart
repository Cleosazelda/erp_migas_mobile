import 'package:flutter/material.dart';
import 'pages/login_page.dart';

// bikin global notifier biar bisa diubah dari mana aja
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

class ERP extends StatelessWidget {
  const ERP({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          color: Colors.white70,
          title: "ERP MUJ",
          theme: ThemeData.light(),      // tema terang
          darkTheme: ThemeData.dark(),   // tema gelap
          themeMode: mode,               // ngikutin notifier
          home: const LoginPage(),
        );
      },
    );
  }
}
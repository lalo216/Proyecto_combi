import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'pages/boot_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const CombisApp(),
    ),
  );
}

class CombisApp extends StatelessWidget {
  const CombisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Curo combis',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB7E4C7),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const BootPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

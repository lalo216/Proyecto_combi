import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/boot_page.dart';
import 'state/app_state.dart';

void main() {
  runApp(
    // Cualquier widget puede leerlo con context.watch<AppState>()
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
      title: 'Combis Chiautempan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB7E4C7),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const BootPage(),
    );
  }
}

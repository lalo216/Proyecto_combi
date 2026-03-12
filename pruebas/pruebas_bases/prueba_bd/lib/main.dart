import 'package:flutter/material.dart';
import 'utils/common.dart';
import 'db_backend.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final seCreo = await InstalaDB.instance.verificarOCrearEsquema();
  debugLog(
    seCreo ? 'BD creada en este arranque' : 'BD ya existía',
    tag: 'MAIN',
  );

  runApp(const CombisApp());
}

class CombisApp extends StatefulWidget {
  const CombisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Combis App',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: const Text('solo backend'),

          body: Container(width: 100, height: 100),
        ),
      ),
    );
  }
}

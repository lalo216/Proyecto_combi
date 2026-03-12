import 'package:flutter/material.dart';
import 'utils/common.dart';
import 'db_backend.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final seCreo = await InstalaDB.instance.verificarOCrearEsquema();
  debugLog(seCreo ? 'BD creada en este arranque' : 'BD ya existía', tag: 'MAIN');

  runApp(const CombisApp());
}

class CombisApp extends StatelessWidget {
  const CombisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Combis App',
      debugShowCheckedModeBanner: false,
      // TODO: Aplicar AppTheme cuando esté listo
      home: const DbInicioScreen(),
    );
  }
}

/// Pantalla de inicio temporal para desarrollo de la BD.
/// Será reemplazada por db_frontend.dart.
class DbInicioScreen extends StatelessWidget {
  const DbInicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        // TODO: db_frontend.dart va aquí
        child: Text('BD lista — frontend pendiente'),
      ),
    );
  }
}
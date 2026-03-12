import 'package:flutter/material.dart';
import 'utils/common.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Update for android stage
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  }

   await _initializeDatabase();

  debugLog('App iniciada — Capa DB deshabilitada (Fase 3)', tag: 'MAIN');

  runApp(const CombisApp());
}

// ─── TODO: Fase 3b — Restaurar cuando se reactive la BD ─────────────────────
 Future<void> _initializeDatabase() async {
  try {
    debugLog('Initializing database...', tag: 'INIT');

    final db = DatabaseHelper.instance;
    final hasData = await db.hasData();

    if (!hasData) {
      debugLog('Database is empty. Seeding sample data...', tag: 'INIT');
      await _seedSampleData();
      debugLog('✓ Sample data seeded', tag: 'INIT');
    } else {
      debugLog('✓ Database already initialized', tag: 'INIT');
    }
  } catch (e, stackTrace) {
    errorLog(
      'Database initialization failed',
      error: e,
      stackTrace: stackTrace,
      tag: 'INIT',
    );
    rethrow;
  }
}

Future<void> _seedSampleData() async {
  final db = DatabaseHelper.instance;

  // Rutas de muestra con trayectos reales en el "mapa"
  final rutasejemplares = [
    RutaCombi(
      id: 1,
      number: 'A',
      name: 'Azul A — Virgen → Ocotlan (Parada en el chaparral)',
      color: Colors.blue,
      coordenada_inicio:  LatLng(19.3184318, -98.2334783)
      coordenada_fin: LatLng(19.316319, -98.218227)
      estimatedTime: '12 min',
    ),
    AppRoute(
      id: 2,
      number: 'B',
      name: 'Roja B — 20_de_Noviembre → Volcanes(parada en galerias)',
      color: Colors.red,
      coordenada_inicio:  LatLng(19.3184318, -98.2334783),
      coordenada_fin: LatLng(19.316319, -98.218227),
      estimatedTime: '10 min',
    ),
    AppRoute(
      id: 3,
      number: 'C',
      name: 'Verde C — Ocotlan → Sta. ana (parada en parque Hidalgo)',
      color: Colors.green,
      coordenada_inicio:  LatLng(19.3184318, -98.2334783),
      coordenada_fin: LatLng(19.316319, -98.218227),
      estimatedTime: '8 min',
    ),
  ];

  // Insert all routes
  for (final route in sampleRoutes) {
    await db.insertRoute(route);
    debugLog('Inserted route: ${route.number} - ${route.name}', tag: 'SEED');
  }
}

/// Main app widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppTheme.appTitle,
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'db_backend.dart';
import 'models/modelos.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SimpleDbApp());
}

class SimpleDbApp extends StatelessWidget {
  const SimpleDbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Combis App — Dev',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}


/// Pantalla única de la app de prueba de BD.
///
/// Estado mínimo:
///   [_cargando]   — muestra el spinner mientras la BD inicia o se resetea.
///   [_totalTablas], [_totalRutas], [_rutas] — datos leídos de la BD.
///
/// Los errores viajan por [InstalaDB.instance.errorNotifier].
/// El [ValueListenableBuilder] que envuelve el Scaffold reacciona
/// automáticamente sin setState adicional.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _cargando = false;
  int _totalTablas = 0;
  int _totalRutas = 0;
  List<Ruta> _rutas = [];

  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    InstalaDB.instance.limpiarError();
    setState(() => _cargando = true);
    await InstalaDB.instance.verificarOCrearEsquema();
    await _actualizarDatos();
    setState(() => _cargando = false);
  }

  Future<void> _actualizarDatos() async {
    final tablas = await InstalaDB.instance.contarTablas();
    final total = await InstalaDB.instance.contarRutas();
    final rutas = await InstalaDB.instance.obtenerRutas();
    setState(() {
      _totalTablas = tablas;
      _totalRutas = total;
      _rutas = rutas;
    });
  }

  Future<void> _reinstalar() async {
    InstalaDB.instance.limpiarError();
    setState(() => _cargando = true);
    final exito = await InstalaDB.instance.resetearBD();
    if (exito) await _actualizarDatos();
    setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: InstalaDB.instance.errorNotifier,
      builder: (context, errorMsg, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Combis DB v${InstalaDB.dbVersion}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _inicializarApp,
                tooltip: 'Actualizar',
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: _reinstalar,
                tooltip: 'Resetear BD',
              ),
            ],
          ),
          body: Column(
            children: [
              // Banner de error — solo visible cuando hay un problema en la BD.
              if (errorMsg != null) _ErrorBanner(mensaje: errorMsg),

              if (_cargando)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else ...[
                _StatsRow(tablas: _totalTablas, rutas: _totalRutas),
                const Divider(height: 1),
                Expanded(child: _ListaRutas(rutas: _rutas)),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// Widgets auxiliares
// ──────────────────────────────────────────────────────────

/// Banner rojo no intrusivo que aparece en la parte superior
/// cuando [InstalaDB.errorNotifier] tiene un valor.
class _ErrorBanner extends StatelessWidget {
  final String mensaje;
  const _ErrorBanner({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.red.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          // Descartar el error sin reiniciar la BD
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
            onPressed: InstalaDB.instance.limpiarError,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Fila de estadísticas: tablas activas y total de rutas.
class _StatsRow extends StatelessWidget {
  final int tablas;
  final int rutas;
  const _StatsRow({required this.tablas, required this.rutas});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatCard(label: 'Tablas', value: '$tablas'),
          _StatCard(label: 'Rutas', value: '$rutas'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Lista de rutas. Muestra un placeholder si la tabla está vacía.
class _ListaRutas extends StatelessWidget {
  final List<Ruta> rutas;
  const _ListaRutas({required this.rutas});

  @override
  Widget build(BuildContext context) {
    if (rutas.isEmpty) {
      return const Center(child: Text('No hay rutas guardadas'));
    }
    return ListView.builder(
      itemCount: rutas.length,
      itemBuilder: (context, i) {
        final ruta = rutas[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.black,
            child: Text(ruta.numero),
          ),
          title: Text(ruta.nombre),
          subtitle: Text('Paradas: ${ruta.paradas} • Favoritos: ${ruta.favoritas}'),
          trailing: const Icon(Icons.chevron_right),
        );
      },
    );
  }
}
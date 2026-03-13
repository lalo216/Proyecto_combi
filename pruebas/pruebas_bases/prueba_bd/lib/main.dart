import 'package:flutter/material.dart';
import 'db_backend.dart';
import 'models/modelos.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CombisApp());
}

class CombisApp extends StatelessWidget {
  const CombisApp({super.key});

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
          primary: Colors.orangeAccent,
        ),
      ),
      home: const DbInicioScreen(),
    );
  }
}

class DbInicioScreen extends StatefulWidget {
  const DbInicioScreen({super.key});

  @override
  State<DbInicioScreen> createState() => _DbInicioScreenState();
}

class _DbInicioScreenState extends State<DbInicioScreen> {
  bool _cargando = false;
  String? _mensajeEstado;
  int _totalTablas = 0;
  int _totalRutas = 0;
  List<Ruta> _rutas = [];

  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    setState(() { _cargando = true; _mensajeEstado = 'Verificando la base de datos...'; });
    try {
      await InstalaDB.instance.verificarOCrearEsquema();
      await _actualizarDatos();
      setState(() {
        _mensajeEstado = 'Se hizo al cien';
      });
    } catch (e) {
      setState(() {
        _mensajeEstado = 'Whoops, algo fallo!';
      });
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }
  Future<void> _reinstalar() async {
    setState(() {
      _cargando = true;
      _mensajeEstado = 'Reseteando base de datos...';
    });
    
    final exito = await InstalaDB.instance.resetearBD();
    
    if (exito) {
      await _actualizarDatos();
      setState(() {
        _mensajeEstado = '✓ Base de datos reiniciada';
      });
    } else {
      setState(() {
        _mensajeEstado = '✗ Error al reiniciar';
      });
    }
    
    setState(() {
      _cargando = false;
    });
  }
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Combis DB Debug'),
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
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_mensajeEstado != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _mensajeEstado!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCard(label: 'Tablas', value: '$_totalTablas'),
                      _StatCard(label: 'Rutas', value: '$_totalRutas'),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _rutas.isEmpty
                      ? const Center(child: Text('No hay rutas guardadas'))
                      : ListView.builder(
                          itemCount: _rutas.length,
                          itemBuilder: (context, index) {
                            final ruta = _rutas[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.black,
                                child: Text(ruta.numero),
                              ),
                              title: Text(ruta.nombre),
                              subtitle: Text(
                                'Paradas: ${ruta.paradas} • Favoritos: ${ruta.favoritas}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                            );
                          },
                        ),
                ),
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

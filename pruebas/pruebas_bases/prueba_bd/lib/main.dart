import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/common.dart';
import 'db_backend.dart';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'log/db_logger.dart';
// import 'package:flutter/foundation.dart';

const _negro     = Color(0xFF0D0D0D);
const _naranja   = Color(0xFFFF6B2B); 
const _rojo      = Color(0xFFCC2B2B);
const _verde     = Color(0xFF2BCC66);
const _textoPrincipal = Color(0xFFEDEDED);
const _textoApagado   = Color(0xFF666666);

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
        scaffoldBackgroundColor: _negro,
        colorScheme: const ColorScheme.dark(
          primary: _naranja,
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
  _Vista _vistaActual = _Vista.inicio;
  bool _cargando = false;
  String? _mensajeEstado;

  int _totalTablas = 0;
  int _totalRutas = 0;
  List<Map<String, String>> _rutasVista = [];

  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    setState(() { _cargando = true; _mensajeEstado = 'Inicializando base de datos...'; });
    try {
      await InstalaDB.instance.verificarOCrearEsquema();
      setState(() { _mensajeEstado = null; });
    } catch (e) {
      setState(() { _mensajeEstado = 'Error inicial: $e'; });
    } finally {
      setState(() { _cargando = false; });
    }
  }

  Future<void> _verBD() async {
    setState(() { _cargando = true; _mensajeEstado = null; });

    try {
      final tablas = await contarTablas();
      final total = await contarRutas();
      final rutas = await obtenRutas();

      setState(() {
        _totalTablas = tablas;
        _totalRutas = total;
        _rutasVista = rutas.map((r) => {
          'numero': r.numero,
          'nombre': r.nombre,
          'tiempo': '${r.tiempoEstimado} min',
          'activa': r.activa ? 'activa' : 'inactiva',
        }).toList();
        _vistaActual = _Vista.tabla;
      });
    } catch (e) {
      setState(() {
        _mensajeEstado = 'Error al leer la BD: $e';
      });
    } finally {
      setState(() { _cargando = false; });
    }
  }

  Future<void> _reinstalar() async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => const _DialogoConfirmacion(),
    );
    if (confirma != true) return;

    setState(() { _cargando = true; _mensajeEstado = null; });
    final exito = await InstalaDB.instance.resetearBD();

    setState(() {
      _cargando = false;
      _vistaActual = _Vista.inicio;
      _rutasVista = [];
      _mensajeEstado = exito
          ? '✓ BD reinstalada — tablas recreadas'
          : '✗ Falló la reinstalación';
    });
  }

  void _verLogs() => setState(() {
    _vistaActual = _Vista.logs;
    _mensajeEstado = null;
  });

  void _volver() => setState(() {
    _vistaActual = _Vista.inicio;
    _mensajeEstado = null;
  });


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Encabezado(mostrarVolver: _vistaActual != _Vista.inicio, onVolver: _volver),
              const SizedBox(height: 32),
              Expanded(
                child: _cargando
                    ? const _PanelCargando()
                    : _buildVistaActual(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVistaActual() {
    switch (_vistaActual) {
      case _Vista.inicio:
        return _PanelInicio(
          mensajeEstado: _mensajeEstado,
          onVerBD: _verBD,
          onReinstalar: _reinstalar,
          onVerLogs: _verLogs,
        );
      case _Vista.tabla:
        return _PanelTabla(
          totalTablas: _totalTablas,
          total: _totalRutas,
          rutas: _rutasVista,
        );
      case _Vista.logs:
        return const _PanelLogs();
    }
  }
}


enum _Vista { inicio, tabla, logs }


class _Encabezado extends StatelessWidget {
  final bool mostrarVolver;
  final VoidCallback onVolver;

  const _Encabezado({required this.mostrarVolver, required this.onVolver});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, color: _naranja),
            const SizedBox(width: 8),
            Text(
              'COMBIS APP — BACKSTAGE',
              style: GoogleFonts.sourceCodePro(
                fontSize: 11,
                letterSpacing: 3,
                color: _naranja,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (mostrarVolver)
              GestureDetector(
                onTap: onVolver,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '← volver',
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 11,
                      color: _textoApagado,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Container(height: 1, color: _naranja),
      ],
    );
  }
}


class _PanelInicio extends StatelessWidget {
  final String? mensajeEstado;
  final VoidCallback onVerBD;
  final VoidCallback onReinstalar;
  final VoidCallback onVerLogs;

  const _PanelInicio({
    this.mensajeEstado,
    required this.onVerBD,
    required this.onReinstalar,
    required this.onVerLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Módulos de Instalación',
          style: GoogleFonts.sourceCodePro(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _textoPrincipal,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Gestiona la base de datos SQLite y monitorea las operaciones en tiempo real.',
          style: GoogleFonts.sourceCodePro(
            fontSize: 13,
            color: _textoApagado,
            height: 1.6,
          ),
        ),

        const SizedBox(height: 24),

        _AccionCard(
          titulo: 'Ver Datos',
          subtitulo: 'Consulta tablas y registros actuales',
          color: _naranja,
          onTap: onVerBD,
        ),
        const SizedBox(height: 12),
        _AccionCard(
          titulo: 'Backstage Logs',
          subtitulo: 'Ver historial de eventos y errores',
          color: _verde,
          onTap: onVerLogs,
        ),
        const SizedBox(height: 12),
        _AccionCard(
          titulo: 'Reinstalar Todo',
          subtitulo: 'Reset de fábrica y datos de ejemplo',
          color: _rojo,
          onTap: onReinstalar,
        ),

        if (mensajeEstado != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: _naranja)),
            child: Text(
              mensajeEstado!,
              style: GoogleFonts.sourceCodePro(fontSize: 12, color: _naranja),
            ),
          ),
        ],

        const Spacer(),
        
        Text(
          'NOTAS DE DEV:\n • Web usa IndexedDB\n • Mobile usa SQLite nativo\n • Los logs persisten por sesión',
          style: GoogleFonts.sourceCodePro(fontSize: 10, color: _textoApagado, height: 1.5),
        ),
      ],
    );
  }
}

class _AccionCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Color color;
  final VoidCallback onTap;

  const _AccionCard({
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: GoogleFonts.sourceCodePro(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 1)),
                    Text(subtitulo,
                        style: GoogleFonts.sourceCodePro(
                            fontSize: 11, color: _textoApagado)),
                  ],
                ),
              ),
              Text('→', style: TextStyle(color: color, fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelLogs extends StatelessWidget {
  const _PanelLogs();

  @override
  Widget build(BuildContext context) {
    final logs = DBLogger.logs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'backstage_logs.txt',
          style: GoogleFonts.sourceCodePro(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textoPrincipal,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Color(0xFF141414),
            child: logs.isEmpty
                ? Center(
                    child: Text('No hay logs registrados aún.',
                        style: GoogleFonts.sourceCodePro(color: _textoApagado, fontSize: 12)))
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final isError = log.contains('ERROR:');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          log,
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 11,
                            color: isError ? _rojo : _textoApagado,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _PanelTabla extends StatelessWidget {
  final int totalTablas;
  final int total;
  final List<Map<String, String>> rutas;

  const _PanelTabla({required this.totalTablas, required this.total, required this.rutas});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'rutas',
              style: GoogleFonts.sourceCodePro(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textoPrincipal,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              color: _textoApagado,
              child: Text(
                '$totalTablas tablas',
                style: GoogleFonts.sourceCodePro(fontSize: 11, color: _negro, fontWeight: FontWeight.w700),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              color: _naranja,
              child: Text(
                '$total filas',
                style: GoogleFonts.sourceCodePro(fontSize: 11, color: _negro, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FilaTabla(cells: const ['#', 'nombre', 'tiempo', 'estado'], esEncabezado: true),
        Container(height: 1, color: _naranja),
        const SizedBox(height: 4),
        Expanded(
          child: rutas.isEmpty
              ? Center(child: Text('Sin datos.', style: GoogleFonts.sourceCodePro(fontSize: 12, color: _textoApagado)))
              : ListView.separated(
                  itemCount: rutas.length,
                  separatorBuilder: (_, _) => Container(height: 1, color: _negro),
                  itemBuilder: (_, i) {
                    final r = rutas[i];
                    return _FilaTabla(cells: [
                      r['numero'] ?? '',
                      r['nombre'] ?? '',
                      r['tiempo'] ?? '',
                      r['activa'] ?? '',
                    ]);
                  },
                ),
        ),
      ],
    );
  }
}

class _FilaTabla extends StatelessWidget {
  final List<String> cells;
  final bool esEncabezado;

  const _FilaTabla({required this.cells, this.esEncabezado = false});

  @override
  Widget build(BuildContext context) {
    final estilo = GoogleFonts.sourceCodePro(
      fontSize: 11,
      color: esEncabezado ? _textoApagado : _textoPrincipal,
      fontWeight: esEncabezado ? FontWeight.w600 : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text(cells[0], style: estilo)),
          Expanded(child: Text(cells[1], style: estilo, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 60, child: Text(cells[2], style: estilo, textAlign: TextAlign.right)),
          SizedBox(
            width: 70,
            child: Text(
              cells.length > 3 ? cells[3] : '',
              style: estilo.copyWith(
                color: cells.length > 3 && cells[3] == 'activa' ? _verde : _textoApagado,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelCargando extends StatelessWidget {
  const _PanelCargando();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: _naranja, strokeWidth: 2),
          ),
          const SizedBox(height: 16),
          Text(
            'procesando...',
            style: GoogleFonts.sourceCodePro(fontSize: 12, color: _textoApagado, letterSpacing: 2),
          ),
        ],
      ),
    );
  }
}

class _DialogoConfirmacion extends StatelessWidget {
  const _DialogoConfirmacion();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _negro,
      shape: const RoundedRectangleBorder(side: BorderSide(color: _rojo)),
      title: Text(
        'REINSTALAR BD',
        style: GoogleFonts.sourceCodePro(color: _rojo, fontWeight: FontWeight.w700, fontSize: 16),
      ),
      content: Text(
        'Esto borrará todas las tablas actuales y sembrará datos de ejemplo nuevos.',
        style: GoogleFonts.sourceCodePro(color: _textoPrincipal, fontSize: 13, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('CANCELAR', style: GoogleFonts.sourceCodePro(color: _textoApagado)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('PROCEDER', style: GoogleFonts.sourceCodePro(color: _rojo, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
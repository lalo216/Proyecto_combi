import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/common.dart';
import 'db_backend.dart';

// ─── Paleta ───────────────────────────────────────────────────────────────────

const _negro     = Color(0xFF0D0D0D);
const _superficie = Color(0xFF1A1A1A);
const _borde     = Color(0xFF2E2E2E);
const _naranja   = Color(0xFFFF6B2B); // Vibrant Sunset primario
const _rojo      = Color(0xFFCC2B2B);
const _textoPrincipal = Color(0xFFEDEDED);
const _textoApagado   = Color(0xFF666666);

// ─── Entry point ──────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final seCreo = await InstalaDB.instance.verificarOCrearEsquema();
  debugLog(seCreo ? 'BD creada en este arranque' : 'BD ya existía', tag: 'MAIN');

  runApp(const CombisApp());
}

// ─── App root ─────────────────────────────────────────────────────────────────

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
          surface: _superficie,
          primary: _naranja,
        ),
      ),
      home: const DbInicioScreen(),
    );
  }
}

// ─── Pantalla principal ───────────────────────────────────────────────────────

class DbInicioScreen extends StatefulWidget {
  const DbInicioScreen({super.key});

  @override
  State<DbInicioScreen> createState() => _DbInicioScreenState();
}

class _DbInicioScreenState extends State<DbInicioScreen> {
  // Estado de la pantalla
  _Vista _vistaActual = _Vista.inicio;
  bool _cargando = false;
  String? _mensajeEstado;

  // Datos cargados
  int _totalRutas = 0;
  List<Map<String, String>> _rutasVista = [];

  // ─── Acciones ───────────────────────────────────────────────────────────

  Future<void> _verBD() async {
    setState(() { _cargando = true; _mensajeEstado = null; });

    try {
      final total = await contarRutas();
      final rutas = await obtenRutas();

      setState(() {
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
    // Confirmación antes de destruir datos
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

  void _volver() => setState(() {
    _vistaActual = _Vista.inicio;
    _mensajeEstado = null;
  });

  // ─── Build ──────────────────────────────────────────────────────────────

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
                    : _vistaActual == _Vista.inicio
                        ? _PanelInicio(
                            mensajeEstado: _mensajeEstado,
                            onVerBD: _verBD,
                            onReinstalar: _reinstalar,
                          )
                        : _PanelTabla(
                            total: _totalRutas,
                            rutas: _rutasVista,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sub-vistas ───────────────────────────────────────────────────────────────

enum _Vista { inicio, tabla }

// ─── Encabezado ───────────────────────────────────────────────────────────────

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
              'COMBIS APP — BD DEV',
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
                child: Text(
                  '← volver',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 11,
                    color: _textoApagado,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Container(height: 1, color: _borde),
      ],
    );
  }
}

// ─── Panel de inicio ──────────────────────────────────────────────────────────

class _PanelInicio extends StatelessWidget {
  final String? mensajeEstado;
  final VoidCallback onVerBD;
  final VoidCallback onReinstalar;

  const _PanelInicio({
    this.mensajeEstado,
    required this.onVerBD,
    required this.onReinstalar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contexto
        Text(
          'Control de base de datos',
          style: GoogleFonts.sourceCodePro(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _textoPrincipal,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Esta herramienta gestiona el archivo SQLite local de la app '
          '(combisapp.sqlite3). Las operaciones aquí afectan directamente '
          'las tablas rutas y paradas. Reinstalar borra todos los datos.',
          style: GoogleFonts.sourceCodePro(
            fontSize: 13,
            color: _textoApagado,
            height: 1.6,
          ),
        ),

        const SizedBox(height: 12),

        // Indicadores de esquema
        _FilaEstado(label: 'tabla rutas', ok: true),
        _FilaEstado(label: 'tabla paradas', ok: true),

        const SizedBox(height: 8),

        // Mensaje de operación anterior, si hay
        if (mensajeEstado != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: _borde),
              color: _superficie,
            ),
            child: Text(
              mensajeEstado!,
              style: GoogleFonts.sourceCodePro(
                fontSize: 12,
                color: mensajeEstado!.startsWith('✓') ? _naranja : _rojo,
              ),
            ),
          ),
        ],

        const Spacer(),

        // Botones
        _BotonAccion(
          label: 'Ver BD',
          descripcion: 'Carga y muestra el contenido actual',
          color: _naranja,
          onTap: onVerBD,
        ),
        const SizedBox(height: 12),
        _BotonAccion(
          label: 'Reinstalar',
          descripcion: 'Borra y recrea todas las tablas',
          color: _rojo,
          onTap: onReinstalar,
          peligroso: true,
        ),
      ],
    );
  }
}

// ─── Panel tabla ──────────────────────────────────────────────────────────────

class _PanelTabla extends StatelessWidget {
  final int total;
  final List<Map<String, String>> rutas;

  const _PanelTabla({required this.total, required this.rutas});

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
              color: _naranja,
              child: Text(
                '$total filas',
                style: GoogleFonts.sourceCodePro(
                  fontSize: 11,
                  color: _negro,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Cabecera de tabla
        _FilaTabla(
          cells: const ['#', 'nombre', 'tiempo', 'estado'],
          esEncabezado: true,
        ),
        Container(height: 1, color: _naranja.withOpacity(0.4)),
        const SizedBox(height: 4),

        Expanded(
          child: rutas.isEmpty
              ? Center(
                  child: Text(
                    'Sin datos — usa Reinstalar para sembrar ejemplos',
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 12,
                      color: _textoApagado,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: rutas.length,
                  separatorBuilder: (_, _) =>
                      Container(height: 1, color: _borde),
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

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _FilaEstado extends StatelessWidget {
  final String label;
  final bool ok;

  const _FilaEstado({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            ok ? '✓' : '✗',
            style: TextStyle(
              color: ok ? _naranja : _rojo,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.sourceCodePro(
              fontSize: 12,
              color: _textoApagado,
            ),
          ),
        ],
      ),
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
      fontSize: 12,
      color: esEncabezado ? _textoApagado : _textoPrincipal,
      fontWeight: esEncabezado ? FontWeight.w600 : FontWeight.normal,
      letterSpacing: esEncabezado ? 1.5 : 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text(cells[0], style: estilo)),
          Expanded(child: Text(cells[1], style: estilo, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 64, child: Text(cells[2], style: estilo, textAlign: TextAlign.right)),
          SizedBox(
            width: 64,
            child: Text(
              cells.length > 3 ? cells[3] : '',
              style: estilo.copyWith(
                color: cells.length > 3 && cells[3] == 'activa'
                    ? _naranja
                    : _textoApagado,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  final String label;
  final String descripcion;
  final Color color;
  final VoidCallback onTap;
  final bool peligroso;

  const _BotonAccion({
    required this.label,
    required this.descripcion,
    required this.color,
    required this.onTap,
    this.peligroso = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: peligroso ? 2 : 1),
          color: peligroso ? color.withOpacity(0.08) : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descripcion,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 11,
                      color: _textoApagado,
                    ),
                  ),
                ],
              ),
            ),
            Text('→', style: TextStyle(color: color, fontSize: 18)),
          ],
        ),
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
            child: CircularProgressIndicator(
              color: _naranja,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'consultando...',
            style: GoogleFonts.sourceCodePro(
              fontSize: 12,
              color: _textoApagado,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Diálogo de confirmación ──────────────────────────────────────────────────

class _DialogoConfirmacion extends StatelessWidget {
  const _DialogoConfirmacion();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _superficie,
      shape: const RoundedRectangleBorder(),
      title: Text(
        'Reinstalar BD',
        style: GoogleFonts.sourceCodePro(
          color: _rojo,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      content: Text(
        'Esto borra todas las tablas y las recrea vacías. '
        'No hay vuelta atrás.',
        style: GoogleFonts.sourceCodePro(
          color: _textoApagado,
          fontSize: 13,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancelar',
            style: GoogleFonts.sourceCodePro(color: _textoApagado),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'Reinstalar',
            style: GoogleFonts.sourceCodePro(
              color: _rojo,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
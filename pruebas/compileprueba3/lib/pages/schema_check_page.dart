import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';

class SchemaCheckPage extends StatefulWidget {
  const SchemaCheckPage({super.key});

  @override
  State<SchemaCheckPage> createState() => _SchemaCheckPageState();
}

class _SchemaCheckPageState extends State<SchemaCheckPage> {
  final ApiService _api = ApiService();
  bool _loading = true;
  Map<String, dynamic>? _schema;
  String? _error;

  static const Map<String, List<String>> _expected = {
    'rutas': ['id', 'nombre_ruta', 'horario', 'tiempo_recorrido', 'start_point', 'end_point'],
    'paradas': ['id', 'route_id', 'name', 'lat', 'lng', 'order'],
    'usuarios': ['id', 'email', 'password', 'nombre_completo', 'municipio', 'role'],
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = context.read<AppState>().token;
      if (token == null) throw Exception('No hay token de sesión (¿sesión expirada?)');
      final data = await _api.getSchemaDetails(token);
      if (mounted) {
        setState(() {
          _schema = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspección de Esquema'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final serverTables = _schema?['tables'] as Map<String, dynamic>? ?? {};
    
    // Unimos tablas esperadas y reales para mostrar faltantes.
    final allTableNames = {..._expected.keys, ...serverTables.keys}.toList()..sort();

    return ListView.builder(
      itemCount: allTableNames.length,
      itemBuilder: (context, index) {
        final tableName = allTableNames[index];
        final columns = serverTables[tableName] as List?;
        final expectedCols = _expected[tableName];
        
        return _TableExpansionTile(
          name: tableName, 
          columns: columns,
          expectedColumns: expectedCols,
        );
      },
    );
  }
}

class _TableExpansionTile extends StatelessWidget {
  final String name;
  final List? columns;
  final List<String>? expectedColumns;

  const _TableExpansionTile({
    required this.name, 
    this.columns,
    this.expectedColumns,
  });

  @override
  Widget build(BuildContext context) {
    final exists = columns != null;
    final colorScheme = Theme.of(context).colorScheme;

    if (!exists) {
      return ListTile(
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        title: Text(name, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        subtitle: const Text('Tabla no encontrada en el servidor'),
      );
    }

    // Verificar si faltan columnas esperadas
    final actualColNames = columns!.map((c) => (c as Map)['Field']?.toString().toLowerCase()).toSet();
    final missingCols = expectedColumns?.where((e) => !actualColNames.contains(e.toLowerCase())).toList() ?? [];

    return ExpansionTile(
      leading: Icon(
        missingCols.isEmpty ? Icons.check_circle_outline : Icons.error_outline,
        color: missingCols.isEmpty ? Colors.green : Colors.red,
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        missingCols.isEmpty 
            ? '${columns!.length} columnas (OK)' 
            : '${columns!.length} columnas (Faltan: ${missingCols.join(', ')})',
        style: TextStyle(color: missingCols.isEmpty ? null : Colors.red),
      ),
      children: [
        for (final col in columns!)
          Builder(builder: (context) {
            final colMap = col as Map;
            final field = colMap['Field']?.toString() ?? 'unknown';
            final isExpected = expectedColumns?.any((e) => e.toLowerCase() == field.toLowerCase()) ?? false;
            
            return ListTile(
              dense: true,
              title: Text(field, style: TextStyle(fontWeight: isExpected ? FontWeight.bold : FontWeight.normal)),
              subtitle: Text(colMap['Type']?.toString() ?? ''),
              trailing: isExpected ? const Icon(Icons.check, size: 16, color: Colors.green) : null,
            );
          }),
        if (missingCols.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.all(8),
              color: colorScheme.errorContainer,
              child: Text(
                'Faltan columnas: ${missingCols.join(', ')}',
                style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 12),
              ),
            ),
          )
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

/// Pantalla de Rutas — demo de uso de API primitivo.
///
/// Intenta cargar rutas desde la API del servidor.
/// Si la API falla, carga datos del cache SQLite local.
/// Incluye búsqueda por nombre.
class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  final TextEditingController _buscarCtrl = TextEditingController();
  List<Map<String, dynamic>> _todasRutas = [];
  List<Map<String, dynamic>> _rutasFiltradas = [];
  bool _cargando = true;
  String? _fuente;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buscarCtrl.addListener(_filtrar);
    _cargarRutas();
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarRutas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    // Intentar API primero.
    try {
      final api = ApiService();
      final rutasApi = await api.fetchRutas();
      // Guardar en cache para offline.
      await CacheService.instance.sincronizarDesdeApi(rutasApi);
      setState(() {
        _todasRutas = rutasApi;
        _rutasFiltradas = rutasApi;
        _fuente = 'api';
        _cargando = false;
      });
      return;
    } catch (e) {
      // API falló — intentar cache.
    }

    // Fallback a cache.
    try {
      final rutasCache = await CacheService.instance.leerRutasConParadas();
      setState(() {
        _todasRutas = rutasCache;
        _rutasFiltradas = rutasCache;
        _fuente = 'cache';
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _cargando = false;
        _error = 'No se pudieron cargar rutas: $e';
      });
    }
  }

  void _filtrar() {
    final query = _buscarCtrl.text.toLowerCase();
    setState(() {
      _rutasFiltradas = _todasRutas.where((r) {
        final nombre = (r['name'] ?? '').toString().toLowerCase();
        final numero = (r['number'] ?? r['number_code'] ?? '')
            .toString()
            .toLowerCase();
        return nombre.contains(query) || numero.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de búsqueda.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _buscarCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar ruta...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              suffixIcon: _buscarCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38),
                      onPressed: () {
                        _buscarCtrl.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Indicador de fuente de datos.
        if (_fuente != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  _fuente == 'api' ? Icons.cloud_done : Icons.storage,
                  size: 14,
                  color: _fuente == 'api' ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  _fuente == 'api'
                      ? 'Datos del servidor'
                      : 'Datos locales (offline)',
                  style: TextStyle(
                    color: _fuente == 'api' ? Colors.green : Colors.orange,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Lista.
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _cargarRutas,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _rutasFiltradas.isEmpty
              ? const Center(
                  child: Text(
                    'No se encontraron rutas',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarRutas,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _rutasFiltradas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final ruta = _rutasFiltradas[i];
                      final colorHex =
                          (ruta['color'] as String?)?.replaceAll('#', '') ??
                          'FF6D00';
                      final color = Color(int.parse('FF$colorHex', radix: 16));

                      return ListTile(
                        tileColor: const Color(0xFF1E1E1E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          child: Text(
                            ruta['number'] ?? ruta['number_code'] ?? '?',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          ruta['name'] ?? 'Sin nombre',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '~${ruta['estimated_time']} min',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.white38,
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

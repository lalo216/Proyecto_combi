import 'package:flutter/material.dart';
import '../services/cache_service.dart';

/// Pantalla de Inicio con Mapa interactivo, manejado por bd local
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _rutas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final rutas = await CacheService.instance.leerRutasConParadas();
      setState(() {
        _rutas = rutas;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_rutas.isEmpty) {
      return const Center(
        child: Text(
          'No hay rutas en la BD local',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rutas.length,
        itemBuilder: (context, i) {
          final ruta = _rutas[i];
          final stops = ruta['stops'] as List<dynamic>? ?? [];
          final colorHex =
              (ruta['color'] as String?)?.replaceAll('#', '') ?? 'FF6D00';
          final color = Color(int.parse('FF$colorHex', radix: 16));

          return Card(
            color: const Color(0xFF1E1E1E),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        child: Text(
                          ruta['number_code'] ?? '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ruta['name'] ?? 'Sin nombre',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${ruta['start_point']} → ${ruta['end_point']}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${ruta['estimated_time']} min',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (stops.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 4),
                    Text(
                      'Paradas (${stops.length}):',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: stops.map<Widget>((s) {
                        return Chip(
                          label: Text(
                            s['name'] ?? '?',
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: color.withValues(alpha: 0.15),
                          labelStyle: TextStyle(color: color),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

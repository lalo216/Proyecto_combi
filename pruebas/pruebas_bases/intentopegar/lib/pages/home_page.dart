import 'package:flutter/material.dart';
import '../data/seed_data.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static List<Map<String, dynamic>> get _rutas {
    return SeedData.rutas.asMap().entries.map((entry) {
      final ruta = Map<String, dynamic>.from(entry.value);
      ruta['stops'] = SeedData.paradas
          .where((p) => p['ruta_index'] == entry.key)
          .toList();
      return ruta;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rutas = _rutas;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rutas.length,
      itemBuilder: (context, i) {
        final ruta = rutas[i];
        final stops = ruta['stops'] as List<dynamic>;
        final colorHex =
            (ruta['color'] as String).replaceAll('#', '');
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
                        ruta['number_code'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ruta['name'],
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
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: stops.map<Widget>((s) {
                      return Chip(
                        label: Text(
                          s['name'],
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: color.withValues(alpha: 0.15),
                        labelStyle: TextStyle(color: color),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

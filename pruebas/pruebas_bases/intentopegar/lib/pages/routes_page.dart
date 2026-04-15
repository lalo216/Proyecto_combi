import 'package:flutter/material.dart';
import '../data/seed_data.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  final TextEditingController _buscarCtrl = TextEditingController();
  late List<Map<String, dynamic>> _todasRutas;
  late List<Map<String, dynamic>> _rutasFiltradas;

  @override
  void initState() {
    super.initState();
    _todasRutas = SeedData.rutas
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
    _rutasFiltradas = _todasRutas;
    _buscarCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  void _filtrar() {
    final query = _buscarCtrl.text.toLowerCase();
    setState(() {
      _rutasFiltradas = _todasRutas.where((r) {
        final nombre = (r['name'] as String).toLowerCase();
        final numero = (r['number_code'] as String).toLowerCase();
        return nombre.contains(query) || numero.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _buscarCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar ruta...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _buscarCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _buscarCtrl.clear,
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
        Expanded(
          child: _rutasFiltradas.isEmpty
              ? const Center(
                  child: Text('No se encontraron rutas'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _rutasFiltradas.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final ruta = _rutasFiltradas[i];
                    final colorHex =
                        (ruta['color'] as String).replaceAll('#', '');
                    final color =
                        Color(int.parse('FF$colorHex', radix: 16));

                    return ListTile(
                      tileColor: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        child: Text(
                          ruta['number_code'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(ruta['name']),
                      subtitle: Text('~${ruta['estimated_time']} min'),
                      trailing: const Icon(Icons.chevron_right),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

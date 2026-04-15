// Pantalla principal: mapa OSM con polilíneas de rutas + hoja inferior con tarjetas.
// Los datos vienen de RouteRepository (offline-first: servidor → SQLite).

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/parada.dart';
import '../models/ruta.dart';
import '../repositories/route_repository.dart';
import '../services/api_service.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repo = RouteRepository();
  final _api = ApiService();

  List<Ruta> _rutas = [];
  List<Parada> _paradas = [];
  Ruta? _selectedRuta;
  String _healthStatus = 'checking';
  bool _loading = true;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkHealth();
  }

  Future<void> _loadData() async {
    final rutas = await _repo.getRutas();
    final paradas = await _repo.getAllParadas();
    if (!mounted) return;
    setState(() {
      _rutas = rutas;
      _paradas = paradas;
      _loading = false;
    });
  }

  Future<void> _checkHealth() async {
    try {
      final status = await _api.checkHealth();
      if (mounted) setState(() => _healthStatus = status);
    } on OfflineException {
      if (mounted) setState(() => _healthStatus = 'offline');
    }
  }

  // Convierte '#FF6D00' → Color
  Color _hexColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  List<Parada> get _visibleParadas => _selectedRuta == null
      ? _paradas
      : _paradas.where((p) => p.routeId == _selectedRuta!.id).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildMapTab(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    return Stack(
      children: [
        _buildMap(),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: _buildStatusBar(),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.28,
          minChildSize: 0.12,
          maxChildSize: 0.55,
          snap: true,
          snapSizes: const [0.12, 0.28, 0.55],
          builder: (context, scrollController) =>
              _buildRouteSheet(scrollController),
        ),
      ],
    );
  }

  Widget _buildStatusBar() {
    final (dotColor, label) = switch (_healthStatus) {
      'ok' => (Colors.green, 'Servidor OK'),
      'degraded' => (Colors.orange, 'Servidor degradado'),
      'offline' => (Colors.red, 'Sin conexión'),
      _ => (Colors.grey, 'Verificando...'),
    };

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.directions_bus_filled, color: Color(0xFFFF6D00)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Combis Chiautempan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Centro aproximado de Chiautempan
    const center = LatLng(19.3060, -98.1870);

    // Polilíneas — cada ruta con su color; la seleccionada se resalta
    final polylines = <Polyline>[];
    for (final ruta in _rutas) {
      final stops = _paradas
          .where((p) => p.routeId == ruta.id)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      if (stops.length < 2) continue;

      final isHighlighted =
          _selectedRuta == null || _selectedRuta!.id == ruta.id;

      polylines.add(Polyline(
        points: stops.map((p) => LatLng(p.lat, p.lng)).toList(),
        color: _hexColor(ruta.color)
            .withAlpha(isHighlighted ? 230 : 60),
        strokeWidth: _selectedRuta?.id == ruta.id ? 5.0 : 3.0,
        borderColor: isHighlighted ? Colors.white.withAlpha(80) : Colors.transparent,
        borderStrokeWidth: 1.5,
      ));
    }

    // Marcadores — círculos con el color de la ruta; inicio con ícono distinto
    final markers = <Marker>[];
    for (final p in _visibleParadas) {
      final ruta = _rutas.firstWhere(
        (r) => r.id == p.routeId,
        orElse: () => _rutas.first,
      );
      final color = _hexColor(ruta.color);
      markers.add(Marker(
        point: LatLng(p.lat, p.lng),
        width: 28,
        height: 28,
        child: Tooltip(
          message: '${ruta.number} — ${p.name}',
          child: p.order == 0
              ? Icon(Icons.circle, color: color, size: 22)
              : Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
        ),
      ));
    }

    return FlutterMap(
      options: const MapOptions(
        initialCenter: center,
        initialZoom: 14.5,
        maxZoom: 18,
        minZoom: 10,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'mx.combis.combischiautempanrun',
          tileProvider: NetworkTileProvider(
            headers: {
              'User-Agent': 'CombisChiautempan/0.1 (gooseymech@proton.me)',
            },
          ),
        ),
        PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildRouteSheet(ScrollController scrollController) {
    final surface = Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Encabezado
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  _selectedRuta == null
                      ? 'Rutas disponibles'
                      : 'Ruta ${_selectedRuta!.number} — ${_selectedRuta!.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (_selectedRuta != null) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _selectedRuta = null),
                    child: const Text('Ver todas'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Lista de rutas
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: scrollController,
                    itemCount: _rutas.length,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemBuilder: (_, i) => _buildRouteCard(_rutas[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(Ruta ruta) {
    final isSelected = _selectedRuta?.id == ruta.id;
    final color = _hexColor(ruta.color);
    final stopCount = _paradas.where((p) => p.routeId == ruta.id).length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            setState(() => _selectedRuta = isSelected ? null : ruta),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Badge de letra de ruta
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  ruta.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ruta.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$stopCount paradas',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: color, size: 22)
              else
                Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

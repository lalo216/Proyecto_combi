import 'package:flutter/material.dart';
import '../models/ruta.dart';
import '../models/parada.dart';
import '../database/database_helper.dart';

class RouteDetailPage extends StatefulWidget {
  final Ruta? selectedRoute;

  const RouteDetailPage({super.key, this.selectedRoute});

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Parada> _paradas = [];
  bool _isLoading = true;

  // HELPER: Robust Color Parsing
  Color get _routeColor {
    if (widget.selectedRoute == null) return Colors.grey;
    try {
      final hex = widget.selectedRoute!.color.trim().replaceFirst('#', '');
      return Color(int.parse('0xFF$hex'));
    } catch (e) {
      // Fallback if the string is incorrectly formatted
      return Colors.blueGrey; 
    }
  }

  @override
  void initState() {
    super.initState();
    _loadParadas();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(RouteDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRoute?.id != widget.selectedRoute?.id) {
      _loadParadas();
      _searchController.clear();
    }
  }

  Future<void> _loadParadas() async {
    setState(() => _isLoading = true);
    if (widget.selectedRoute != null) {
      final db = DatabaseHelper.instance;
      final paradas = await db.getParadas(widget.selectedRoute!.id);
      paradas.sort((a, b) => a.order.compareTo(b.order));
      setState(() {
        _paradas = paradas;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<Parada> get _filteredParadas {
    if (_searchController.text.isEmpty) return _paradas;
    final query = _searchController.text.toLowerCase();
    return _paradas
        .where((p) => p.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedRoute == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Selecciona una ruta en el mapa',
              // Robust Theme Handling: Fallback to a default style
              style: Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Ruta Header
        Container(
          color: _routeColor,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    widget.selectedRoute!.number,
                    style: (Theme.of(context).textTheme.titleMedium ?? const TextStyle()).copyWith(
                          fontWeight: FontWeight.bold,
                          color: _routeColor,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.selectedRoute!.name,
                      style: (Theme.of(context).textTheme.titleMedium ?? const TextStyle()).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (widget.selectedRoute!.estimatedTime > 0)
                      Text(
                        '${widget.selectedRoute!.estimatedTime} min aprox',
                        style: (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
                                  color: Colors.white70,
                                ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Search Field
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar parada...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _searchController.clear,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        // Paradas List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredParadas.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'No hay paradas para esta ruta'
                            : 'No hay paradas coincidentes',
                        style: Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredParadas.length,
                      itemBuilder: (context, index) {
                        final parada = _filteredParadas[index];
                        return _buildParadaCard(context, parada, index);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildParadaCard(BuildContext context, Parada parada, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _routeColor.withAlpha(80),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '${parada.order}',
                    style: (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
                          fontWeight: FontWeight.bold,
                          color: _routeColor,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parada.name,
                      style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      '${parada.lat.toStringAsFixed(4)}, ${parada.lng.toStringAsFixed(4)}',
                      style: (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.location_on_outlined,
                  size: 20, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}
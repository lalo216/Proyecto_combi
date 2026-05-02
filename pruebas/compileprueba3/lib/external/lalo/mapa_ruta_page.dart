import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../database/database_helper.dart';
import '../../services/api_service.dart';
import '../../state/app_state.dart';
import 'routing_service.dart';

class MapaRutaPage extends StatefulWidget {
  final int rutaId;

  const MapaRutaPage({super.key, required this.rutaId});

  @override
  State<MapaRutaPage> createState() => _MapaRutaPageState();
}

class _MapaRutaPageState extends State<MapaRutaPage> {
  final ApiService apiService = ApiService();
  final RoutingService routingService = RoutingService();

  List<Marker> markers = [];
  List<LatLng> polylinePoints = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    cargarRuta();
  }

  Future<void> cargarRuta() async {
    final appState = context.read<AppState>();
    final ruta = appState.routeById(widget.rutaId);

    final memo = appState.drawnFor(widget.rutaId);
    if (memo != null) {
      final poly = memo.polyline.map((c) => LatLng(c[0], c[1])).toList();
      final pts = memo.paradas
          .map((p) {
            final lat = p['lat'];
            final lon = p['lng'];
            if (lat == null || lon == null) return null;
            return LatLng((lat as num).toDouble(), (lon as num).toDouble());
          })
          .whereType<LatLng>()
          .toList();

      _aplicarRender(
        puntos: pts,
        polyline: poly,
        ruta: ruta,
      );
      return;
    }

    final cached = await DatabaseHelper.instance.getDrawnRoute(widget.rutaId);
    if (cached != null) {
      appState.setDrawn(
        routeId: widget.rutaId,
        paradas: cached.paradas,
        polyline: cached.polyline,
      );
      final poly = cached.polyline.map((c) => LatLng(c[0], c[1])).toList();
      final pts = cached.paradas
          .map((p) {
            final lat = p['lat'];
            final lon = p['lng'];
            if (lat == null || lon == null) return null;
            return LatLng((lat as num).toDouble(), (lon as num).toDouble());
          })
          .whereType<LatLng>()
          .toList();

      _aplicarRender(
        puntos: pts,
        polyline: poly,
        ruta: ruta,
      );
      return;
    }

    try {
      final paradasRaw = await apiService.getParadasPorRuta(widget.rutaId);
      if (paradasRaw.isEmpty) {
        throw const ApiException('Esta ruta aún no tiene paradas registradas');
      }
      final paradas = paradasRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final puntos = paradas
          .map((p) {
            final lat = p['lat'];
            final lon = p['lng'];
            if (lat == null || lon == null) return null;
            return LatLng((lat as num).toDouble(), (lon as num).toDouble());
          })
          .whereType<LatLng>()
          .toList();

      if (puntos.isEmpty) {
        throw const ApiException('La ruta no tiene coordenadas válidas');
      }

      final polyline = await routingService.getRutaPolyline(puntos);
      final polylineSerial =
          polyline.map((ll) => [ll.latitude, ll.longitude]).toList();

      await DatabaseHelper.instance.setDrawnRoute(
        widget.rutaId,
        paradas,
        polylineSerial,
      );
      appState.setDrawn(
        routeId: widget.rutaId,
        paradas: paradas,
        polyline: polylineSerial,
      );

      _aplicarRender(puntos: puntos, polyline: polyline, ruta: ruta);
    } on OfflineException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Sin conexión: ${e.message}';
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Error al cargar: $e';
        });
      }
    }
  }

  void _aplicarRender({
    required List<LatLng> puntos,
    required List<LatLng> polyline,
    Ruta? ruta,
  }) {
    if (!mounted) return;

    setState(() {
      markers = _construirMarkers(puntos, ruta);
      polylinePoints = polyline;
      _loading = false;
      _error = null;
    });
  }

  List<Marker> _construirMarkers(List<LatLng> puntos, Ruta? ruta) {
    if (puntos.isEmpty) return const [];
    final out = <Marker>[];
    for (var i = 0; i < puntos.length; i++) {
      final isStart = i == 0;
      final isEnd = i == puntos.length - 1;
      if (!isStart && !isEnd) {
        out.add(Marker(
          point: puntos[i],
          width: 28,
          height: 28,
          child: const Icon(Icons.circle, color: Colors.red, size: 14),
        ));
        continue;
      }
      final color = isStart ? Colors.green.shade700 : Colors.blue.shade800;
      final etiqueta = isStart
          ? (ruta?.startPoint ?? 'Inicio')
          : (ruta?.endPoint ?? 'Fin');
      out.add(Marker(
        point: puntos[i],
        width: 110,
        height: 64,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                etiqueta,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              isStart ? Icons.flag_circle : Icons.flag,
              color: color,
              size: 32,
            ),
          ],
        ),
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(19.3186, -98.1996),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'mx.combis.combischiautempan',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: polylinePoints,
                    strokeWidth: 4,
                    color: Colors.blue,
                  ),
                ],
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: Material(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

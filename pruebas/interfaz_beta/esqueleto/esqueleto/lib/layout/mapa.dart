import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'ApiService.dart';
import 'RoutingService.dart';

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

  @override
  void initState() {
    super.initState();
    cargarRuta();
  }

  Future<void> cargarRuta() async {
    try {
      final paradas = await apiService.getParadasPorRuta(widget.rutaId);

      // Crear markers
      final puntos = paradas
          .map((p) => LatLng(p["latitud"], p["longitud"]))
          .toList();
      setState(() {
        markers = puntos
            .map(
              (p) => Marker(
                point: p,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            )
            .toList();
      });

      // Obtener polilínea de OSRM
      final rutaPolyline = await routingService.getRutaPolyline(puntos);
      setState(() {
        polylinePoints = rutaPolyline;
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(19.3186, -98.1996),
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(markers: markers),
          PolylineLayer(
            polylines: [
              Polyline(
                points: polylinePoints,
                strokeWidth: 4,
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

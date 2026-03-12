import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'routing_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<LatLng> routePoints = [];

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  void _loadRoute() async {
    final service = RoutingService();
    final points = await service.getRoute(
      LatLng(19.3184318, -98.2334783), // CDMX
      LatLng(19.316319, -98.218227), // Tlaxcala
    );
    setState(() {
      routePoints = points;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa con Rutas")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(19.43, -99.13),
          initialZoom: 8,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.mi_app_web',
          ),
          PolylineLayer(
            polylines: [
              Polyline(points: routePoints, strokeWidth: 4, color: Colors.blue),
            ],
          ),
        ],
      ),
    );
  }
}

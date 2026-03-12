import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'route_model.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final List<CustomRoute> routes = [
    CustomRoute(
      name: "Ruta Azul",
      color: Colors.blue,
      stops: [
        LatLng(19.3139, -98.2400),
        LatLng(19.3165, -98.2370),
        LatLng(19.3180, -98.2360),
        LatLng(19.3400, -98.2000),
        LatLng(19.3060, -98.2100),
        LatLng(19.3300, -98.2200),
        LatLng(19.3200, -98.2500),
        LatLng(19.2900, -98.2700),
        LatLng(19.2800, -98.3300),
        LatLng(19.2800, -98.4400),
      ],
    ),
    CustomRoute(
      name: "Ruta Roja",
      color: Colors.red,
      stops: [
        LatLng(19.4167, -98.1833),
        LatLng(19.4200, -98.1800),
        LatLng(19.4000, -98.1900),
        LatLng(19.4300, -98.2000),
        LatLng(19.5000, -98.1500),
        LatLng(19.4800, -98.1200),
        LatLng(19.4600, -98.1000),
        LatLng(19.4500, -98.0800),
        LatLng(19.4800, -97.9800),
        LatLng(19.3167, -97.9167),
      ],
    ),
    CustomRoute(
      name: "Ruta Verde",
      color: Colors.green,
      stops: [
        LatLng(19.3167, -97.9167),
        LatLng(19.4000, -97.8500),
        LatLng(19.4000, -97.7500),
        LatLng(19.3500, -97.7500),
        LatLng(19.3500, -97.8000),
        LatLng(19.3500, -98.0500),
        LatLng(19.3000, -98.0500),
        LatLng(19.2800, -98.1000),
        LatLng(19.2500, -98.1500),
        LatLng(19.2500, -98.2000),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadAllRoutes();
  }

  Future<void> _loadAllRoutes() async {
    for (var route in routes) {
      await route.buildPolyline();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rutas en Tlaxcala")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(19.3139, -98.2400),
          initialZoom: 9,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.mi_app_web',
          ),
          PolylineLayer(
            polylines: routes
                .map(
                  (r) => Polyline(
                    points: r.polyline,
                    strokeWidth: 4,
                    color: r.color,
                  ),
                )
                .toList(),
          ),
          MarkerLayer(
            markers: routes
                .expand(
                  (r) => r.stops.map(
                    (p) => Marker(
                      point: p,
                      width: 40,
                      height: 40,
                      child: Icon(Icons.location_on, color: r.color),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

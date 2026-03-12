import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'route_model.dart';
import 'route_runner.dart';

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
    // Puedes añadir más rutas aquí...
  ];

  RouteRunner? runner;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    for (var route in routes) {
      await route.buildPolyline();
    }
    // Inicializamos el puntero en la primera ruta
    runner = RouteRunner(routePoints: routes.first.polyline);
    runner!.start(() {
      setState(() {});
    });
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
            markers: [
              // Marcadores de paradas
              ...routes.expand(
                (r) => r.stops.map(
                  (p) => Marker(
                    point: p,
                    width: 40,
                    height: 40,
                    child: Icon(Icons.location_on, color: r.color),
                  ),
                ),
              ),
              // Puntero animado
              if (runner?.currentPosition != null)
                Marker(
                  point: runner!.currentPosition!,
                  width: 50,
                  height: 50,
                  child: const Icon(Icons.directions_bus, color: Colors.black),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

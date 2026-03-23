import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'db_service.dart';
import 'route_model.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<CustomRoute> routes = [];
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final db = DBService();
    try {
      final fetchedRoutes = await db.fetchRoutes();
      for (var route in fetchedRoutes) {
        await route.buildPolyline(); // usa OSRM
      }
      setState(() {
        routes = fetchedRoutes;
        errorMessage = "";
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rutas en Tlaxcala")),
      body: errorMessage.isNotEmpty
          ? Center(
              child: Text(
                "❌ Error: $errorMessage",
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          : FlutterMap(
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

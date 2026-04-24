import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapaUsuarioPage extends StatefulWidget {
  const MapaUsuarioPage({super.key});

  @override
  State<MapaUsuarioPage> createState() => _MapaUsuarioPageState();
}

class _MapaUsuarioPageState extends State<MapaUsuarioPage> {
  LatLng? userLocation;

  @override
  void initState() {
    super.initState();
    obtenerUbicacion();
  }

  Future<void> obtenerUbicacion() async {
    try {
      // En web, el navegador pide permiso automáticamente si estás en localhost o HTTPS
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        userLocation = LatLng(pos.latitude, pos.longitude);
      });
    } catch (e) {
      // Fallback si falla la ubicación
      if (!mounted) return;
      setState(() {
        userLocation = LatLng(19.3186, -98.1999); // Ejemplo: Chiautempan
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa Usuario")),
      body: userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: userLocation!,
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

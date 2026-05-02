import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../util/error_reporter.dart';
import '../widgets/search_overlay.dart';

class MapaUsuarioPage extends StatefulWidget {
  const MapaUsuarioPage({super.key});

  @override
  State<MapaUsuarioPage> createState() => _MapaUsuarioPageState();
}

class _MapaUsuarioPageState extends State<MapaUsuarioPage> {
  static const LatLng _fallback = LatLng(19.3186, -98.1999);
  LatLng _center = _fallback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  Future<void> _initLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sin permiso de ubicación — usando Chiautempan'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        if (!mounted) return;
        setState(() => _center = LatLng(pos.latitude, pos.longitude));
      }
    } on TimeoutException catch (e) {
      if (mounted) reportError(context, e, hint: 'GPS timeout');
    } on LocationServiceDisabledException catch (e) {
      if (mounted) reportError(context, e, hint: 'GPS deshabilitado');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SearchSurface(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _center,
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'mx.combis.combischiautempan',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _center,
                width: 36,
                height: 36,
                child: const Icon(Icons.my_location, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

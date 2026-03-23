import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'route_model.dart';

class DBService {
  final String apiUrl =
      "http://localhost/api/gen_rut.php"; // Ajusta según tu entorno

  Future<List<CustomRoute>> fetchRoutes() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          List<CustomRoute> routes = [];
          for (var r in data['routes']) {
            final color = _hexToColor(r['color'] ?? '#000000');
            List<LatLng> stops = [];
            for (var s in r['stops']) {
              final lat = double.parse(s['latitude'].toString());
              final lng = double.parse(s['longitude'].toString());
              stops.add(LatLng(lat, lng));
            }
            routes
                .add(CustomRoute(name: r['name'], color: color, stops: stops));
          }
          return routes;
        } else {
          throw Exception("Error API: ${data['message']}");
        }
      } else {
        throw Exception("Error HTTP: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error de conexión: $e");
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}

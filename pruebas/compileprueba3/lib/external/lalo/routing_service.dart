import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  final String osrmUrl = "https://router.project-osrm.org/route/v1/driving";

  Future<List<LatLng>> getRutaPolyline(List<LatLng> puntos) async {
    final coords = puntos.map((p) => "${p.longitude},${p.latitude}").join(";");
    final response = await http.get(
      Uri.parse("$osrmUrl/$coords?overview=full&geometries=geojson"),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coordsList = data["routes"][0]["geometry"]["coordinates"] as List;
      return coordsList.map((c) => LatLng(c[1], c[0])).toList();
    } else {
      throw Exception("Error al obtener ruta OSRM: ${response.statusCode}");
    }
  }
}

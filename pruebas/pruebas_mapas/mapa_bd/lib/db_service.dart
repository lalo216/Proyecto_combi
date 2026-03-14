import 'package:mysql1/mysql1.dart';
import 'package:latlong2/latlong.dart';
import 'route_model.dart';
import 'package:flutter/material.dart';

class DBService {
  final ConnectionSettings settings = ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: '',
    db: 'combis',
  );

  Future<List<CustomRoute>> fetchRoutes() async {
    final conn = await MySqlConnection.connect(settings);

    // Traer todas las rutas
    final routesResult = await conn.query('SELECT * FROM Routes');
    List<CustomRoute> routes = [];

    for (var row in routesResult) {
      final routeId = row['route_id'];
      final name = row['name'];
      final colorHex = row['color'] ?? '#000000';

      // Convertir color hex a Color
      final color = _hexToColor(colorHex);

      // Traer paradas de la ruta
      final stopsResult = await conn.query(
        'SELECT s.stop_id, s.name, s.latitude, s.longitude, rs.stop_order '
        'FROM RouteStops rs '
        'JOIN Stops s ON rs.stop_id = s.stop_id '
        'WHERE rs.route_id = ? ORDER BY rs.stop_order',
        [routeId],
      );

      List<LatLng> stops = [];
      for (var stopRow in stopsResult) {
        stops.add(LatLng(stopRow['latitude'], stopRow['longitude']));
      }

      routes.add(CustomRoute(name: name, color: color, stops: stops));
    }

    await conn.close();
    return routes;
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // alpha
    }
    return Color(int.parse(hex, radix: 16));
  }
}

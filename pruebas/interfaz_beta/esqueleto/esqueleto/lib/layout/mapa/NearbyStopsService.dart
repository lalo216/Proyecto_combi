import 'package:latlong2/latlong.dart';

class NearbyStopsService {
  final Distance distance = Distance();

  List<Map<String, dynamic>> getStopsWithinRadius(
    LatLng userLocation,
    List<Map<String, dynamic>> stops,
    double radiusMeters,
  ) {
    return stops.where((stop) {
      final stopLocation = LatLng(stop['latitud'], stop['longitud']);
      final d = distance(userLocation, stopLocation);
      return d <= radiusMeters;
    }).toList();
  }
}

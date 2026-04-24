import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class UserLocationService {
  Future<LatLng> getCurrentLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      // Fallback si falla la ubicación
      return LatLng(19.3186, -98.1996); // Ejemplo: Chiautempan
    }
  }
}

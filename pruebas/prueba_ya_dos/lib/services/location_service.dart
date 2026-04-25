import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Servicio unificado de ubicación con enfoque respeto del usuario.
///
/// Política: solicitar permisos UNA SOLA VEZ. Si el usuario rechaza o elige
/// "denegado para siempre", respetamos su decisión sin insistir.
///
/// Flujo:
/// 1. Verifica permisos actuales
/// 2. Si están denegados, solicita UNA VEZ (sin persistencia)
/// 3. Si el usuario rechaza → retorna fallback sin más diálogos
/// 4. Si están denegados permanentemente → retorna fallback silenciosamente
/// 5. (Admin dashboard puede ofrecer botón para abrir Settings manualmente)
///
/// Uso:
/// ```dart
/// final service = LocationService();
/// final ubicacion = await service.getCurrentLocation();
/// print('Ubicación: ${ubicacion.latitude}, ${ubicacion.longitude}');
/// ```
class LocationService {
  static const LatLng defaultLocation = LatLng(19.3186, -98.1996);

  /// Obtiene la ubicación actual del usuario.
  ///
  /// Retorna:
  /// - LatLng con ubicación real si los permisos están otorgados
  /// - defaultLocation (Chiautempan) si no hay permisos o falla la geolocalización
  ///
  /// Comportamiento:
  /// - Si permisos = denied: solicita UNA VEZ y respeta la respuesta
  /// - Si permisos = deniedForever: retorna fallback silenciosamente (usuario puede cambiar en Settings)
  /// - Si hay error de red/timeout: retorna fallback
  Future<LatLng> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        // Independientemente de la respuesta, respetamos la decisión del usuario
      }

      // retornar fallback sin insistir
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return defaultLocation;
      }

      // 4. Si llegamos aquí, los permisos están otorgados (whileInUse o always)
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('LocationService error: $e');
      return defaultLocation;
    }
  }

  /// Abre la pantalla de configuración de ubicación del dispositivo.
  ///
  /// Uso: llamar desde admin dashboard si el usuario quiere cambiar permisos manualmente.
  /// Ejemplo:
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: () => LocationService().openLocationSettings(),
  ///   child: Text('Cambiar permisos de ubicación'),
  /// )
  /// ```
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Comprueba si los permisos de ubicación están otorgados sin solicitar.
  ///
  /// Uso: verificar estado actual sin mostrar diálogos.
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Comprueba si los permisos están denegados permanentemente.
  ///
  /// Uso: mostrar mensaje "ve a Settings" en el admin dashboard.
  Future<bool> isLocationPermissionDeniedForever() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.deniedForever;
  }
}

// services/api_service.dart
// Capa de comunicación HTTP con el servidor del API (Tailscale, Lane A).
// Lanza [OfflineException] si no hay conexión, timeout, respuesta no-200, o JSON malformado.
// Nota: respuestas no-200 se tratan como offline por ahora; cuando se agregue auth,
// se distinguirá 401/403 con un ApiException separado.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_base.dart';
import '../models/parada.dart';
import '../models/ruta.dart';

class OfflineException implements Exception {
  const OfflineException();
  @override
  String toString() => 'OfflineException: sin conexión con el servidor';
}

// 401/403 del servidor — token inválido o expirado.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException $statusCode: $message';
}

class ApiService {
  static const String _base = ApiBase.url;
  static const Duration _timeout = Duration(seconds: 10);

  Future<String> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_base/check.php'))
          .timeout(_timeout);
      if (response.statusCode != 200) throw const OfflineException();
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['status'] as String? ?? 'degraded';
    } on SocketException {
      throw const OfflineException();
    } on TimeoutException {
      throw const OfflineException();
    } on FormatException {
      throw const OfflineException();
    } catch (_) {
      throw const OfflineException();
    }
  }

  /// Obtiene todas las rutas con paradas incrustadas desde routes.php.
  Future<({List<Ruta> rutas, List<Parada> paradas})> fetchRoutes() async {
    try {
      final response = await http
          .get(Uri.parse('$_base/routes.php'))
          .timeout(_timeout);
      if (response.statusCode != 200) throw const OfflineException();
      final list = jsonDecode(response.body) as List<dynamic>;

      final rutas = <Ruta>[];
      final paradas = <Parada>[];

      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final ruta = Ruta.fromJson(map);
        rutas.add(ruta);
        for (final s in (map['stops'] as List<dynamic>? ?? [])) {
          paradas.add(
            Parada.fromJsonEmbedded(s as Map<String, dynamic>, ruta.id),
          );
        }
      }

      return (rutas: rutas, paradas: paradas);
    } on SocketException {
      throw const OfflineException();
    } on TimeoutException {
      throw const OfflineException();
    } on FormatException {
      throw const OfflineException();
    } catch (_) {
      throw const OfflineException();
    }
  }

  // --- Favoritos (requieren token JWT) ---

  /// Devuelve los IDs de rutas favoritas del usuario.
  /// Lanza [ApiException] si el token es inválido (401).
  Future<List<int>> getFavorites(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_base/favorites.php'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_timeout);
      if (response.statusCode == 401) {
        throw const ApiException(401, 'Sesión expirada');
      }
      if (response.statusCode != 200) throw const OfflineException();
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final ids = (body['favorites'] as List<dynamic>).map((e) => e as int).toList();
      return ids;
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const OfflineException();
    } on TimeoutException {
      throw const OfflineException();
    } on FormatException {
      throw const OfflineException();
    }
  }

  /// Agrega una ruta a favoritos. No falla si ya existe (INSERT IGNORE).
  Future<void> addFavorite(String token, int routeId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_base/favorites.php'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'route_id': routeId}),
          )
          .timeout(_timeout);
      if (response.statusCode == 401) throw const ApiException(401, 'Sesión expirada');
      if (response.statusCode != 201) throw const OfflineException();
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const OfflineException();
    } on TimeoutException {
      throw const OfflineException();
    }
  }

  /// Quita una ruta de favoritos.
  Future<void> removeFavorite(String token, int routeId) async {
    try {
      final request = http.Request('DELETE', Uri.parse('$_base/favorites.php'))
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({'route_id': routeId});
      final streamed = await request.send().timeout(_timeout);
      if (streamed.statusCode == 401) throw const ApiException(401, 'Sesión expirada');
      if (streamed.statusCode != 200) throw const OfflineException();
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const OfflineException();
    } on TimeoutException {
      throw const OfflineException();
    }
  }

  /// Lanza [OfflineException] si no hay red o la respuesta es inválida.
  Future<({List<Ruta> rutas, List<Parada> paradas, int schemaVersion})?>
      sync(int clientVersion) async {
    try {
      final response = await http
          .get(Uri.parse('$_base/sync.php?client_version=$clientVersion'))
          .timeout(_timeout);
      if (response.statusCode != 200) throw const OfflineException();
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (body['status'] == 'up_to_date') return null;

      final schemaVersion = body['schema_version'] as int;
      final rutas = (body['rutas'] as List<dynamic>)
          .map((e) => Ruta.fromJson(e as Map<String, dynamic>))
          .toList();
      final paradas = (body['paradas'] as List<dynamic>)
          .map((e) => Parada.fromJson(e as Map<String, dynamic>))
          .toList();

      return (rutas: rutas, paradas: paradas, schemaVersion: schemaVersion);
    } on SocketException {
      throw const OfflineException();
    } on TimeoutException {
      throw const OfflineException();
    } on FormatException {
      throw const OfflineException();
    } catch (_) {
      throw const OfflineException();
    }
  }
}

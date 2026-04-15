// services/api_service.dart
// Capa de comunicación HTTP con mechyserver (Tailscale, Lane A).
// Lanza [OfflineException] si no hay conexión, timeout, respuesta no-200, o JSON malformado.
// Nota: respuestas no-200 se tratan como offline por ahora; cuando se agregue auth,
// se distinguirá 401/403 con un ApiException separado.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/parada.dart';
import '../models/ruta.dart';

class OfflineException implements Exception {
  const OfflineException();
  @override
  String toString() => 'OfflineException: sin conexión con el servidor';
}

class ApiService {
  static const String _base =
      'https://mechyserver.taile37db1.ts.net/combiapi';
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
    }
  }
}

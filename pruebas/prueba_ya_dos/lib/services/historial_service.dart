// services/historial_service.dart
// Historial de rutas vistas por el usuario logueado.
// - logView(token, rutaId): fire-and-forget cuando el usuario toca una tarjeta
//   de ruta. No bloquea la navegación si falla.
// - fetchRecientes(token): trae los últimos 5 ruta_id distintos del server.
// El cliente cruza los ints contra la caché SQLite de rutas para armar la UI.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_base.dart';

class HistorialException implements Exception {
  final String message;
  const HistorialException(this.message);
  @override
  String toString() => message;
}

class HistorialService {
  static const String _base = ApiBase.url;
  static const Duration _timeout = Duration(seconds: 8);

  /// POST /historial.php — registra una visita. No lanza excepciones:
  /// fallos de red o auth se loggean y se ignoran (fire-and-forget).
  Future<void> logView(String token, int rutaId) async {
    try {
      await http
          .post(
            Uri.parse('$_base/historial.php'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'ruta_id': rutaId}),
          )
          .timeout(_timeout);
    } on SocketException {
      // Sin red — no importa, el historial se re-sincroniza al volver online.
    } on TimeoutException {
      // Igual: no es crítico.
    } catch (e) {
      // Silencioso por diseño — nunca debe bloquear la navegación.
    }
  }

  /// GET /historial.php — devuelve hasta 5 ruta_id distintos, más reciente primero.
  /// Lanza [HistorialException] si la respuesta no es 200 o JSON malformado.
  Future<List<int>> fetchRecientes(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_base/historial.php'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw HistorialException('HTTP ${response.statusCode}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final ids = (data?['ruta_ids'] as List?) ?? const [];
      return ids.map((e) => (e as num).toInt()).toList();
    } on SocketException {
      throw const HistorialException('Sin conexión');
    } on TimeoutException {
      throw const HistorialException('Timeout');
    } on FormatException {
      throw const HistorialException('Respuesta del servidor malformada');
    }
  }
}

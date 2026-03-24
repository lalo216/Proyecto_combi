import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Cliente HTTP para comunicarse con la API REST del servidor.
///
/// Cada método devuelve datos parseados o lanza una excepción
/// con un mensaje descriptivo para que la UI pueda reaccionar.
class ApiService {
  final String _baseUrl;
  final Duration _timeout;

  ApiService({String? baseUrl, int? timeoutSeconds})
    : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
      _timeout = Duration(
        seconds: timeoutSeconds ?? AppConfig.httpTimeoutSeconds,
      );

  /// Health check: verifica que el servidor esté vivo y MySQL accesible.
  /// Devuelve el JSON completo del response (info de red, status, timestamp).
  /// Lanza excepción si no se puede conectar.
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/check.php'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Servidor respondió con código ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception(
        'Timeout: el servidor no respondió en ${_timeout.inSeconds}s',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtiene todas las rutas activas con sus paradas embebidas.
  /// Formato esperado: {"status":"ok","data":[...]}
  //   Future<List<Map<String, dynamic>>> fetchRutas() async {
  //     try {
  //       final response = await http
  //           .get(Uri.parse('$_baseUrl/rutas.php'))
  //           .timeout(_timeout);

  //       if (response.statusCode == 200) {
  //         final body = jsonDecode(response.body) as Map<String, dynamic>;
  //         if (body['status'] == 'ok') {
  //           return List<Map<String, dynamic>>.from(body['data'] ?? []);
  //         } else {
  //           throw Exception('API error: ${body['message'] ?? 'status no ok'}');
  //         }
  //       } else {
  //         throw Exception('HTTP ${response.statusCode}');
  //       }
  //     } on TimeoutException {
  //       throw Exception('Timeout al obtener rutas');
  //     } catch (e) {
  //       if (e is Exception) rethrow;
  //       throw Exception('Error al obtener rutas: $e');
  //     }
  //   }

  //   /// Obtiene paradas filtradas por ruta.
  //   Future<List<Map<String, dynamic>>> fetchParadas({int? rutaId}) async {
  //     try {
  //       final queryParams = rutaId != null ? '?ruta_id=$rutaId' : '';
  //       final response = await http
  //           .get(Uri.parse('$_baseUrl/paradas.php$queryParams'))
  //           .timeout(_timeout);

  //       if (response.statusCode == 200) {
  //         final body = jsonDecode(response.body) as Map<String, dynamic>;
  //         if (body['status'] == 'ok') {
  //           return List<Map<String, dynamic>>.from(body['data'] ?? []);
  //         } else {
  //           throw Exception('API error: ${body['message'] ?? 'status no ok'}');
  //         }
  //       } else {
  //         throw Exception('HTTP ${response.statusCode}');
  //       }
  //     } on TimeoutException {
  //       throw Exception('Timeout al obtener paradas');
  //     } catch (e) {
  //       if (e is Exception) rethrow;
  //       throw Exception('Error al obtener paradas: $e');
  //     }
  //   }
}

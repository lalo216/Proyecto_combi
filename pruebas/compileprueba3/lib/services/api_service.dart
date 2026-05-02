import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_base.dart';
import '../state/app_state.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
  @override
  String toString() =>
      statusCode == null ? message : 'HTTP $statusCode — $message';
}

class OfflineException extends ApiException {
  const OfflineException(super.message);
}

// El servidor publica un schema_version mayor del que conoce este build.
// Boot atrapa esta excepción y entra en modo solo-lectura.
class SchemaMismatchException extends ApiException {
  final int serverVersion;
  final int clientVersion;
  const SchemaMismatchException({
    required this.serverVersion,
    required this.clientVersion,
  }) : super('Versión del servidor más reciente que el cliente');
}

class HealthResult {
  final bool ok;
  final int? serverSchemaVersion;
  const HealthResult({required this.ok, this.serverSchemaVersion});
}

class SyncResult {
  final List<Ruta> rutas;
  final bool upToDate;
  final int serverSchemaVersion;
  const SyncResult({
    required this.rutas,
    required this.upToDate,
    required this.serverSchemaVersion,
  });
}

class ApiService {
  static const Duration _timeout = Duration(seconds: 8);
  static const String _base = ApiBase.apiurl;

  Future<HealthResult> check() async {
    try {
      final r =
          await http.get(Uri.parse('$_base/check.php')).timeout(_timeout);
      if (r.statusCode != 200) {
        return const HealthResult(ok: false);
      }
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      // status puede ser "ok" o "degraded" — degraded = MySQL caído pero
      // PHP sigue respondiendo. Lo tratamos como no-ok para boot.
      final ok = body['status'] == 'ok';
      final ver = (body['schema_version'] as num?)?.toInt();
      return HealthResult(ok: ok, serverSchemaVersion: ver);
    } on SocketException {
      return const HealthResult(ok: false);
    } on TimeoutException {
      return const HealthResult(ok: false);
    } on FormatException {
      return const HealthResult(ok: false);
    }
  }

  Future<SyncResult> sync({String? token}) async {
    final clientV = ApiBase.localdbversion;
    try {
      final r = await http
          .get(
            Uri.parse('$_base/sync.php?client_version=$clientV'),
            headers: token == null ? null : {'Authorization': 'Bearer $token'},
          )
          .timeout(_timeout);

      if (r.statusCode != 200) {
        throw ApiException('Sync falló', statusCode: r.statusCode);
      }
      final body = jsonDecode(r.body) as Map<String, dynamic>;

      final serverV =
          (body['schema_version'] as num?)?.toInt() ?? clientV;
      if (serverV > clientV) {
        throw SchemaMismatchException(
          serverVersion: serverV,
          clientVersion: clientV,
        );
      }

      if (body['status'] == 'up_to_date') {
        return SyncResult(
          rutas: const [],
          upToDate: true,
          serverSchemaVersion: serverV,
        );
      }

      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Sync sin payload');
      }
      final list = (data['rutas'] as List?) ?? const [];
      final rutas = list
          .map((e) => Ruta.fromJson(e as Map<String, dynamic>))
          .toList();
      return SyncResult(
        rutas: rutas,
        upToDate: false,
        serverSchemaVersion: serverV,
      );
    } on SocketException {
      throw const OfflineException('Sin conexión');
    } on TimeoutException {
      throw const OfflineException('Timeout');
    } on FormatException {
      throw const ApiException('Respuesta del servidor malformada');
    }
  }

  Future<List<dynamic>> getParadasPorRuta(int rutaId) async {
    try {
      final r = await http
          .get(Uri.parse('$_base/routes.php?id=$rutaId'))
          .timeout(_timeout);
      if (r.statusCode != 200) {
        throw ApiException('Paradas falló', statusCode: r.statusCode);
      }
      final body = jsonDecode(r.body) as Map<String, dynamic>;

      final rutas = body['data'] as List?;
      if (rutas == null || rutas.isEmpty) return const [];
      final ruta = rutas.first as Map<String, dynamic>;
      return (ruta['stops'] as List?) ?? const [];
    } on SocketException {
      throw const OfflineException('Sin conexión');
    } on TimeoutException {
      throw const OfflineException('Timeout');
    } on FormatException {
      throw const ApiException('Respuesta del servidor malformada');
    }
  }

  // Devuelve el contenido de "data" ya desempacado:
  // { id, nombre_completo, municipio } para registrar (sin token — se
  // espera que el caller dispare login() inmediatamente después).
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String nombreCompleto,
    required String municipio,
  }) async {
    try {
      final r = await http
          .post(
            Uri.parse('$_base/registrar.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'nombre_completo': nombreCompleto,
              'municipio': municipio,
            }),
          )
          .timeout(_timeout);
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      if (r.statusCode != 201 && r.statusCode != 200) {
        final msg = (body['message'] as String?) ?? 'Registro falló';
        throw ApiException(msg, statusCode: r.statusCode);
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Respuesta del servidor malformada');
      }
      return data;
    } on SocketException {
      throw const OfflineException('Sin conexión');
    } on TimeoutException {
      throw const OfflineException('Timeout');
    } on FormatException {
      throw const ApiException('Respuesta del servidor malformada');
    }
  }

  // Devuelve { token, nombre_completo, municipio } — el contenido de "data".
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final r = await http
          .post(
            Uri.parse('$_base/login.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      if (r.statusCode != 200) {
        final msg = (body['message'] as String?) ?? 'Login falló';
        throw ApiException(msg, statusCode: r.statusCode);
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Respuesta del servidor malformada');
      }
      return data;
    } on SocketException {
      throw const OfflineException('Sin conexión');
    } on TimeoutException {
      throw const OfflineException('Timeout');
    } on FormatException {
      throw const ApiException('Respuesta del servidor malformada');
    }
  }

  Future<Map<String, dynamic>> getSchemaDetails(String token) async {
    try {
      final r = await http.get(
        Uri.parse('$_base/schema.php'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(_timeout);
      if (r.statusCode != 200) {
        throw ApiException('Error al obtener esquema', statusCode: r.statusCode);
      }
      return jsonDecode(r.body) as Map<String, dynamic>;
    } on SocketException {
      throw const OfflineException('Sin conexión');
    } on TimeoutException {
      throw const OfflineException('Timeout');
    } on FormatException {
      throw const ApiException('Respuesta del servidor malformada');
    }
  }
}

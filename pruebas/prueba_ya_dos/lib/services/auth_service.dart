import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/api_base.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  static const String _base = ApiBase.url;
  static const Duration _timeout = Duration(seconds: 10);

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _tokenKey = 'auth_token';
  // Fuera del JWT: mantenemos claim estrecho y cacheamos nombre aquí.
  static const _nombreKey = 'user_nombre_completo';
  static const _municipioKey = 'user_municipio';

  Future<void> register(String email, String password, String nombre, String municipio) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_base/registrar.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password, 'nombre':nombre, 'municipio':municipio}),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 409) {
        throw const AuthException('El correo ya está registrado');
      }
      if (response.statusCode != 201) {
        throw AuthException(body['message'] as String? ?? 'Error al registrarse');
      }
      // Guardamos nombre y municipio devueltos por el servidor para que
      // restoreSession() los tenga disponibles tras login subsecuente.
      final data = body['data'] as Map<String, dynamic>?;
      final nombreSrv = data?['nombre_completo'] as String? ?? nombre;
      final municipioSrv = data?['municipio'] as String? ?? municipio;
      await _storage.write(key: _nombreKey, value: nombreSrv);
      await _storage.write(key: _municipioKey, value: municipioSrv);
    } on AuthException {
      rethrow;
    } on SocketException {
      throw const AuthException('Sin conexión con el servidor');
    } on TimeoutException {
      throw const AuthException('El servidor tardó demasiado');
    } on FormatException {
      throw const AuthException('Respuesta inválida del servidor, checa locales?');
    }
  }

  Future<Map<String, String>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_base/login.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 401) {
        throw const AuthException('Correo o contraseña incorrectos');
      }
      if (response.statusCode != 200) {
        throw AuthException(body['message'] as String? ?? 'Error al iniciar sesión');
      }

      final data = body['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      await _storage.write(key: _tokenKey, value: token);
      final claims = _decodePayload(token);

      // nombre_completo y municipio llegan en el cuerpo de la respuesta,
      // NO en el JWT (decisión: mantener el token estrecho).
      final nombre = data['nombre_completo'] as String?;
      final municipio = data['municipio'] as String?
          ?? claims['municipio'] as String?;
      if (nombre != null) await _storage.write(key: _nombreKey, value: nombre);
      if (municipio != null) {
        await _storage.write(key: _municipioKey, value: municipio);
      }

      return {
        'token': token,
        'email': claims['email'] as String? ?? email,
        'role':  claims['role']  as String? ?? 'user',
        'id':    claims['sub']   as String? ?? '',
        'nombre_completo': nombre ?? '',
        'municipio': municipio ?? '',
      };
    } on AuthException {
      rethrow;
    } on SocketException {
      throw const AuthException('Sin conexión con el servidor');
    } on TimeoutException {
      throw const AuthException('El servidor tardó demasiado');
    } on FormatException {
      throw const AuthException('Respuesta inválida del servidor');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _nombreKey);
    await _storage.delete(key: _municipioKey);
  }

  Future<Map<String, String>?> restoreSession() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;

    final claims = _decodePayload(token);
    final exp = claims['exp'];
    if (exp != null) {
      final expiry = exp is int ? exp : int.tryParse(exp.toString()) ?? 0;
      if (expiry < DateTime.now().millisecondsSinceEpoch ~/ 1000) {
        await logout(); // token expirado — limpiar
        return null;
      }
    }

    final nombre = await _storage.read(key: _nombreKey) ?? '';
    final municipio = await _storage.read(key: _municipioKey)
        ?? claims['municipio'] as String? ?? '';

    return {
      'email': claims['email'] as String? ?? '',
      'role':  claims['role']  as String? ?? 'user',
      'id':    claims['sub']   as String? ?? '',
      'nombre_completo': nombre,
      'municipio': municipio,
    };
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);
  
  Map<String, dynamic> _decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final padded = base64Url.normalize(parts[1]);
      return jsonDecode(utf8.decode(base64Url.decode(padded))) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}

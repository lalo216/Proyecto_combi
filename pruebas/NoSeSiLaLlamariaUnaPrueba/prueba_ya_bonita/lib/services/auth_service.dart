import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  static const String _base =
      'https://mechyserver.taile37db1.ts.net/combiapi';
  static const Duration _timeout = Duration(seconds: 10);

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _tokenKey = 'auth_token';

  Future<void> register(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_base/registrar.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 409) {
        throw const AuthException('El correo ya está registrado');
      }
      if (response.statusCode != 201) {
        throw AuthException(body['message'] as String? ?? 'Error al registrarse');
      }
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

      final token = (body['data'] as Map<String, dynamic>)['token'] as String;
      await _storage.write(key: _tokenKey, value: token);

      // (la verificación ocurre en el servidor en cada request protegido)
      final claims = _decodePayload(token);
      return {
        'token': token,
        'email': claims['email'] as String? ?? email,
        'role':  claims['role']  as String? ?? 'user',
        'id':    claims['sub']   as String? ?? '',
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
  }

  // --- Restaurar sesión al arrancar la app ---
  // Devuelve los datos del usuario si hay un token válido y no expirado.
  // Devuelve null si no hay sesión o el token expiró (y lo borra).
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

    return {
      'email': claims['email'] as String? ?? '',
      'role':  claims['role']  as String? ?? 'user',
      'id':    claims['sub']   as String? ?? '',
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

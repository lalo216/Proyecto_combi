import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthResult {
  final String token;
  final String userId;
  final String email;
  final String? nombre;
  final String? nombreCompleto;
  final String? municipio;
  final String? role;
  final DateTime expiresAt;

  const AuthResult({
    required this.token,
    required this.userId,
    required this.email,
    required this.expiresAt,
    this.nombre,
    this.nombreCompleto,
    this.municipio,
    this.role,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isAdmin => role == 'admin';
}

class AuthService {
  final ApiService _api;
  final FlutterSecureStorage _storage;

  AuthService({ApiService? api, FlutterSecureStorage? storage})
      : _api = api ?? ApiService(),
        _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  // El JWT lleva sub/email/role/municipio/iat/exp pero NO nombre_completo.
  // Para que restoreSession pueda saludar al usuario sin pegarle al server,
  // stasheamos el nombre aparte tras login/registro.
  static const String _kToken = 'jwt';
  static const String _kNombre = 'profile_nombre_completo';

  // registrar.php devuelve {id, nombre_completo, municipio} SIN token.
  // Hacemos auto-login para tener una sesión utilizable de inmediato.
  Future<AuthResult> register({
    required String email,
    required String password,
    required String nombreCompleto,
    required String municipio,
  }) async {
    await _api.register(
      email: email,
      password: password,
      nombreCompleto: nombreCompleto,
      municipio: municipio,
    );
    return login(email: email, password: password);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.login(email: email, password: password);
    return _persistFromBody(data);
  }

  Future<void> logout() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kNombre);
  }

  Future<AuthResult?> restoreSession() async {
    final token = await _storage.read(key: _kToken);
    if (token == null) return null;
    try {
      final claims = _decodeJwtPayload(token);
      final expiresAt = _expFromClaims(claims);
      if (DateTime.now().isAfter(expiresAt)) {
        await logout();
        return null;
      }
      final fullName = await _storage.read(key: _kNombre);
      return AuthResult(
        token: token,
        userId: claims['sub'] as String,
        email: (claims['email'] ?? '') as String,
        nombre: _firstName(fullName),
        nombreCompleto: fullName,
        municipio: claims['municipio'] as String?,
        role: claims['role'] as String?,
        expiresAt: expiresAt,
      );
    } catch (_) {
      await logout();
      return null;
    }
  }

  Future<AuthResult> _persistFromBody(Map<String, dynamic> data) async {
    final token = data['token'] as String?;
    if (token == null) {
      throw const ApiException('Respuesta del servidor malformada');
    }
    final claims = _decodeJwtPayload(token);
    final fullName = data['nombre_completo'] as String?;
    final municipio =
        (data['municipio'] as String?) ?? claims['municipio'] as String?;

    final result = AuthResult(
      token: token,
      userId: claims['sub'] as String,
      email: (claims['email'] ?? '') as String,
      nombre: _firstName(fullName),
      nombreCompleto: fullName,
      municipio: municipio,
      role: claims['role'] as String?,
      expiresAt: _expFromClaims(claims),
    );
    await _storage.write(key: _kToken, value: token);
    if (fullName != null && fullName.isNotEmpty) {
      await _storage.write(key: _kNombre, value: fullName);
    } else {
      await _storage.delete(key: _kNombre);
    }
    return result;
  }
}

String? _firstName(String? fullName) {
  if (fullName == null || fullName.isEmpty) return null;
  return fullName.split(' ').first;
}

DateTime _expFromClaims(Map<String, dynamic> claims) {
  final exp = (claims['exp'] as num?)?.toInt() ?? 0;
  return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
}

Map<String, dynamic> _decodeJwtPayload(String jwt) {
  final parts = jwt.split('.');
  if (parts.length != 3) {
    throw const FormatException('JWT malformado');
  }
  final normalized = base64Url.normalize(parts[1]);
  final decoded = utf8.decode(base64Url.decode(normalized));
  return jsonDecode(decoded) as Map<String, dynamic>;
}

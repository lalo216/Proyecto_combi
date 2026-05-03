import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';

class Ruta {
  final int id;
  final String nombre;
  final String horario;
  final int estimatedTime; // El servidor guarda este campo pero el payload simplificado lo llama tiempo_recorrido, así que ambos se aceptan en fromJson
  final String? startPoint;
  final String? endPoint;

  const Ruta({
    required this.id,
    required this.nombre,
    this.horario = '',
    this.estimatedTime = 0,
    this.startPoint,
    this.endPoint,
  });

  // Acepta nombre_ruta (canonical) y estimated_time o tiempo_recorrido.
  factory Ruta.fromJson(Map<String, dynamic> json) => Ruta(
        id: (json['id'] as num).toInt(),
        nombre: (json['nombre_ruta'] ?? '') as String,
        horario: (json['horario'] ?? '') as String,
        estimatedTime: ((json['estimated_time'] ?? json['tiempo_recorrido'] ?? 0) as num).toInt(),
        startPoint: json['start_point'] as String?,
        endPoint: json['end_point'] as String?,
      );
}

String _norm(String s) {
  const from = 'áéíóúüñÁÉÍÓÚÜÑ';
  const to = 'aeiouunAEIOUUN';
  final buf = StringBuffer();
  for (final c in s.runes) {
    final ch = String.fromCharCode(c);
    final i = from.indexOf(ch);
    buf.write(i == -1 ? ch.toLowerCase() : to[i].toLowerCase());
  }
  return buf.toString();
}

class AppState extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userId;
  String? _userEmail;
  String? _nombre;
  String? _token;
  String? _municipio;
  String? _role;

  List<Ruta> _routes = const [];
  bool _hasSyncedThisSession = false;
  DateTime? _lastSyncAt;

  int? _drawnRouteId;
  List<Map<String, dynamic>>? _drawnParadas;
  List<List<double>>? _drawnPolyline;

  // Favoritos en RAM para que el ícono de estrella sea reactivo sin esperar
  // un round-trip a SQLite. Se hidrata desde DB tras setSession y se mantiene
  // sincronizado en toggleFavorito (set primero, DB después).
  Set<int> _favoritosIds = {};

  // Modo solo-lectura: el servidor anunció un schema_version mayor que el del
  // cliente. Sync queda deshabilitado hasta que se actualice el APK.
  bool _readOnlyMode = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get nombre => _nombre;
  String? get nombreusuario => _nombre;
  String? get token => _token;
  String? get municipio => _municipio;
  String? get role => _role;
  bool get isAdmin => _role == 'admin';
  bool get readOnlyMode => _readOnlyMode;
  String get saludo => _nombre != null ? '¡Hola, $_nombre!' : 'Hola';

  List<Ruta> get routes => List.unmodifiable(_routes);
  DateTime? get lastSyncAt => _lastSyncAt;
  bool get hasSyncedThisSession => _hasSyncedThisSession;

  /// TTL: 1 hora desde el último sync exitoso.
  static const Duration syncTtl = Duration(hours: 1);

  bool get needsSync {
    if (_readOnlyMode) return false;
    if (!_hasSyncedThisSession) return true;
    if (_lastSyncAt == null) return true;
    return DateTime.now().difference(_lastSyncAt!) >= syncTtl;
  }

  /// Tiempo restante antes de que expire el TTL del sync.
  /// null si ya expiró, si no ha sincronizado, o si está en readOnly.
  Duration? get remainingtime {
    if (_readOnlyMode) return null;
    if (_lastSyncAt == null) return null;
    final expiry = _lastSyncAt!.add(syncTtl);
    final remaining = expiry.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  void setSession({
    required String userId,
    required String email,
    String? nombre,
    String? token,
    String? municipio,
    String? role,
  }) {
    _isLoggedIn = true;
    _userId = userId;
    _userEmail = email;
    _nombre = nombre;
    _token = token;
    _municipio = municipio;
    _role = role;
    notifyListeners();
    _hydrateFavoritos();
  }

  void clearSession() {
    _isLoggedIn = false;
    _userId = null;
    _userEmail = null;
    _nombre = null;
    _token = null;
    _municipio = null;
    _role = null;
    _favoritosIds = {};
    notifyListeners();
  }

  void setReadOnlyMode(bool value) {
    if (_readOnlyMode == value) return;
    _readOnlyMode = value;
    notifyListeners();
  }

  void setSeedRoutes(List<Ruta> seed) {
    _routes = List.of(seed);
    notifyListeners();
  }

  /// Marca sync exitoso sin reemplazar rutas (para "up_to_date").
  Future<void> stampSync() async {
    _hasSyncedThisSession = true;
    _lastSyncAt = DateTime.now();
    await DatabaseHelper.instance.setLastSyncAt(_lastSyncAt!);
    notifyListeners();
  }

  Future<void> replaceRoutes(List<Ruta> next) async {
    _routes = List.of(next);
    _hasSyncedThisSession = true;
    _lastSyncAt = DateTime.now();
    await DatabaseHelper.instance.setLastSyncAt(_lastSyncAt!);
    notifyListeners();
  }

  Future<void> hydrateLastSyncAt() async {
    _lastSyncAt = await DatabaseHelper.instance.getLastSyncAt();
    notifyListeners();
  }

  List<Ruta> search(String query) {
    final q = _norm(query.trim());
    if (q.isEmpty) return const [];
    return _routes.where((r) {
      if (_norm(r.nombre).contains(q)) return true;
      if (r.startPoint != null && _norm(r.startPoint!).contains(q)) return true;
      if (r.endPoint != null && _norm(r.endPoint!).contains(q)) return true;
      return false;
    }).toList();
  }

  Ruta? routeById(int id) {
    for (final r in _routes) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<void> logRouteOpened(int routeId) async {
    if (!_isLoggedIn || _userId == null) return;
    await DatabaseHelper.instance.logRouteOpened(_userId!, routeId);
    notifyListeners();
  }

  Future<void> logQuery(String query) async {
    if (!_isLoggedIn || _userId == null) return;
    await DatabaseHelper.instance.logQuery(_userId!, query);
    notifyListeners();
  }

  Future<List<int>> recentRouteIds({int limit = 5}) {
    if (!_isLoggedIn || _userId == null) return Future.value(const []);
    return DatabaseHelper.instance.recentRouteIds(_userId!, limit: limit);
  }

  Set<int> get favoritosIds => Set.unmodifiable(_favoritosIds);
  bool isFavorito(int routeId) => _favoritosIds.contains(routeId);

  Future<List<int>> getFavoritos() {
    if (!_isLoggedIn || _userId == null) return Future.value(const []);
    if (_favoritosIds.isNotEmpty) {
      return Future.value(_favoritosIds.toList());
    }
    return DatabaseHelper.instance.getFavoritos(_userId!);
  }

  Future<void> _hydrateFavoritos() async {
    if (!_isLoggedIn || _userId == null) return;
    final list = await DatabaseHelper.instance.getFavoritos(_userId!);
    _favoritosIds = list.toSet();
    notifyListeners();
  }

  ({List<Map<String, dynamic>> paradas, List<List<double>> polyline})?
      drawnFor(int routeId) {
    if (_drawnRouteId != routeId) return null;
    final p = _drawnParadas;
    final l = _drawnPolyline;
    if (p == null || l == null) return null;
    return (paradas: p, polyline: l);
  }

  void setDrawn({
    required int routeId,
    required List<Map<String, dynamic>> paradas,
    required List<List<double>> polyline,
  }) {
    _drawnRouteId = routeId;
    _drawnParadas = paradas;
    _drawnPolyline = polyline;
    // Sin notifyListeners — el consumidor (MapaRutaPage) lo lee en initState.
  }

  Future<void> toggleFavorito(int routeId) async {
    if (!_isLoggedIn || _userId == null) return;
    if (_favoritosIds.contains(routeId)) {
      _favoritosIds.remove(routeId);
      notifyListeners();
      await DatabaseHelper.instance.removeFavorito(_userId!, routeId);
    } else {
      _favoritosIds.add(routeId);
      notifyListeners();
      await DatabaseHelper.instance.addFavorito(_userId!, routeId);
    }
  }
}

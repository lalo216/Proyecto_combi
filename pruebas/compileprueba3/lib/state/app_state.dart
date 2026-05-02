import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';

class Ruta {
  final int id;
  final String nombre;
  final String horario;
  final int tiempoRecorrido;
  final String? startPoint;
  final String? endPoint;

  const Ruta({
    required this.id,
    required this.nombre,
    this.horario = '',
    this.tiempoRecorrido = 0,
    this.startPoint,
    this.endPoint,
  });

  // Acepta el shape "reducido" (nombre_ruta/tiempo_recorrido) y el shape
  // legacy del servidor actual (name/estimated_time). Mientras sync.php no
  // se actualice al payload simplificado, ambos coexisten — un solo modelo,
  // sin duplicar.
  factory Ruta.fromJson(Map<String, dynamic> json) => Ruta(
        id: (json['id'] as num).toInt(),
        nombre: (json['nombre_ruta'] ??
                json['nombre'] ??
                json['name'] ??
                '') as String,
        horario: (json['horario'] ?? '') as String,
        tiempoRecorrido: ((json['tiempo_recorrido'] ??
                json['estimated_time'] ??
                0) as num)
            .toInt(),
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
  DateTime? _lastSyncAt;

  // Memo de la última ruta dibujada en esta sesión: paradas + polilínea OSRM.
  // Sólo una ruta a la vez; cuando el usuario abre otra, ésta se reemplaza.
  // SQLite (rutas_drawn) es el respaldo entre sesiones.
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
  String? get token => _token;
  String? get municipio => _municipio;
  String? get role => _role;
  bool get isAdmin => _role == 'admin';
  bool get readOnlyMode => _readOnlyMode;
  String get saludo => _nombre == null ? 'Hola' : 'Hola, $_nombre';

  List<Ruta> get routes => List.unmodifiable(_routes);
  DateTime? get lastSyncAt => _lastSyncAt;

  bool get canSync {
    if (_readOnlyMode) return false;
    if (_lastSyncAt == null) return true;
    return DateTime.now().difference(_lastSyncAt!) >= const Duration(hours: 1);
  }

  Duration? get timeUntilNextSync {
    if (_lastSyncAt == null) return Duration.zero;
    final next = _lastSyncAt!.add(const Duration(hours: 1));
    final now = DateTime.now();
    return next.isAfter(now) ? next.difference(now) : Duration.zero;
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

  Future<void> replaceRoutes(List<Ruta> next) async {
    _routes = List.of(next);
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

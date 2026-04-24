// El token JWT persiste en SecureStorage (AuthService), no aquí.
// Al arrancar, BootPage llama a AuthService.restoreSession() y popula este estado.

import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AppState extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userEmail;
  String? _userRole;
  String? _userId;

  // IDs de rutas favoritas — solo en memoria(ram), nunca en SQLite.
  final Set<int> _favoriteIds = {};

  bool get isLoggedIn => _isLoggedIn;
  String? get userEmail => _userEmail;
  String? get userRole => _userRole;
  String? get userId => _userId;
  Set<int> get favoriteIds => Set.unmodifiable(_favoriteIds);
  bool isFavorite(int rutaId) => _favoriteIds.contains(rutaId);

  void setUser({
    required bool loggedIn,
    String? email,
    String? role,
    String? id,
  }) {
    _isLoggedIn = loggedIn;
    _userEmail = email;
    _userRole = role;
    _userId = id;
    notifyListeners();
  }

  void clearUser() {
    _isLoggedIn = false;
    _userEmail = null;
    _userRole = null;
    _userId = null;
    _favoriteIds.clear();
    notifyListeners();
  }

  /// Carga favoritos desde el servidor. Silencia errores de red — la app sigue
  /// funcionando sin favoritos si no hay conexión.
  Future<void> loadFavorites(ApiService api, AuthService auth) async {
    final token = await auth.getToken();
    if (token == null) return;
    try {
      final ids = await api.getFavorites(token);
      _favoriteIds
        ..clear()
        ..addAll(ids);
      notifyListeners();
    } on ApiException {
      // Token inválido — no limpiar favoritos existentes, BootPage ya restauró sesión
    } on OfflineException {
      // Sin red — continuar con lista vacía
    }
  }


  Future<void> toggleFavorite(ApiService api, AuthService auth, int rutaId) async {
    final token = await auth.getToken();
    if (token == null) return;

    final wasAdded = _favoriteIds.contains(rutaId);
    try {
      if (wasAdded) {
        await api.removeFavorite(token, rutaId);
      } else {
        await api.addFavorite(token, rutaId);
      }
    } catch (_) {
      // Revertir si el servidor falló
      if (wasAdded) {
        _favoriteIds.add(rutaId);
      } else {
        _favoriteIds.remove(rutaId);
      }
      notifyListeners();
    }
  }
}

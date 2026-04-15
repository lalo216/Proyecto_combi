// El token JWT persiste en SecureStorage (AuthService), no aquí.
// Al arrancar, BootPage llama a AuthService.restoreSession() y popula este estado.

import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userEmail;
  String? _userRole;
  String? _userId;

  bool get isLoggedIn => _isLoggedIn;
  String? get userEmail => _userEmail;
  String? get userRole => _userRole;
  String? get userId => _userId;

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
    notifyListeners();
  }
}

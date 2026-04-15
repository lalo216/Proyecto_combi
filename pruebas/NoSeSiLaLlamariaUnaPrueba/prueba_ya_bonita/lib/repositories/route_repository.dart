import '../database/database_helper.dart';
import '../models/parada.dart';
import '../models/ruta.dart';
import '../services/api_service.dart';

class RouteRepository {
  final ApiService _api;
  final DatabaseHelper _db;

  RouteRepository({ApiService? api, DatabaseHelper? db})
      : _api = api ?? ApiService(),
        _db = db ?? DatabaseHelper.instance;

  /// Intenta sincronizar con el servidor en segundo plano antes de devolver.
  Future<List<Ruta>> getRutas() async {
    await _trySyncSilently();
    return _db.getRutas();
  }

  /// Devuelve todas las paradas de SQLite (todas las rutas).
  Future<List<Parada>> getAllParadas() async {
    return _db.getAllParadas();
  }

  /// Devuelve las paradas de una ruta específica de SQLite.
  Future<List<Parada>> getParadas(int routeId) async {
    return _db.getParadas(routeId);
  }

  /// Silencia [OfflineException] — sin conexión no es un error en offline-first.
  Future<void> _trySyncSilently() async {
    try {
      final version = await _db.getSchemaVersion();
      final result = await _api.sync(version);
      if (result != null) {
        await _db.replaceAll(
          result.rutas,
          result.paradas,
          result.schemaVersion,
        );
      }
    } on OfflineException {
      // Sin conexión — SQLite es suficiente
    }
  }
}

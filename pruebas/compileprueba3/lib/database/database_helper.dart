import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;
  static const int _version = 2;
  static const String _dbName = 'combis_v3.db';

  Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int _) async {
    await db.execute('''
      CREATE TABLE favoritos (
        user_id    TEXT    NOT NULL,
        route_id   INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (user_id, route_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE historial_rutas (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id  TEXT    NOT NULL,
        route_id INTEGER NOT NULL,
        visto_en INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_hist_rutas_user_time ON historial_rutas(user_id, visto_en DESC)',
    );

    await db.execute('''
      CREATE TABLE historial_busquedas (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id    TEXT    NOT NULL,
        query      TEXT    NOT NULL,
        buscado_en INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_hist_busq_user_time ON historial_busquedas(user_id, buscado_en DESC)',
    );

    await db.execute('''
      CREATE TABLE meta (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await _createRutasDrawn(db);
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await _createRutasDrawn(db);
    }
  }

  Future<void> _createRutasDrawn(Database db) async {
    await db.execute('''
      CREATE TABLE rutas_drawn (
        route_id      INTEGER PRIMARY KEY,
        paradas_json  TEXT NOT NULL,
        polyline_json TEXT NOT NULL,
        cached_at     INTEGER NOT NULL
      )
    ''');
  }

  Future<List<int>> getFavoritos(String userId) async {
    final d = await db;
    final rows = await d.query(
      'favoritos',
      columns: ['route_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => r['route_id'] as int).toList();
  }

  Future<void> addFavorito(String userId, int routeId) async {
    final d = await db;
    await d.insert(
      'favoritos',
      {
        'user_id': userId,
        'route_id': routeId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeFavorito(String userId, int routeId) async {
    final d = await db;
    await d.delete(
      'favoritos',
      where: 'user_id = ? AND route_id = ?',
      whereArgs: [userId, routeId],
    );
  }

  Future<void> logRouteOpened(String userId, int routeId) async {
    final d = await db;
    await d.insert('historial_rutas', {
      'user_id': userId,
      'route_id': routeId,
      'visto_en': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<int>> recentRouteIds(String userId, {int limit = 5}) async {
    final d = await db;
    final rows = await d.rawQuery(
      '''
      SELECT route_id, MAX(visto_en) AS last_seen
      FROM historial_rutas
      WHERE user_id = ?
      GROUP BY route_id
      ORDER BY last_seen DESC
      LIMIT ?
      ''',
      [userId, limit],
    );
    return rows.map((r) => r['route_id'] as int).toList();
  }

  Future<void> logQuery(String userId, String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final d = await db;
    await d.insert('historial_busquedas', {
      'user_id': userId,
      'query': trimmed,
      'buscado_en': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static const String _kLastSync = 'last_sync_at';

  Future<DateTime?> getLastSyncAt() async {
    final d = await db;
    final rows = await d.query(
      'meta',
      where: 'key = ?',
      whereArgs: [_kLastSync],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final ms = int.tryParse(rows.first['value'] as String);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastSyncAt(DateTime when) async {
    final d = await db;
    await d.insert(
      'meta',
      {'key': _kLastSync, 'value': when.millisecondsSinceEpoch.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DrawnRoute?> getDrawnRoute(int routeId) async {
    final d = await db;
    final rows = await d.query(
      'rutas_drawn',
      where: 'route_id = ?',
      whereArgs: [routeId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    final paradas = (jsonDecode(r['paradas_json'] as String) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final polyline = (jsonDecode(r['polyline_json'] as String) as List)
        .map((e) => List<double>.from((e as List).map((n) => (n as num).toDouble())))
        .toList();
    return DrawnRoute(paradas: paradas, polyline: polyline);
  }

  Future<void> setDrawnRoute(
    int routeId,
    List<Map<String, dynamic>> paradas,
    List<List<double>> polyline,
  ) async {
    final d = await db;
    await d.insert(
      'rutas_drawn',
      {
        'route_id': routeId,
        'paradas_json': jsonEncode(paradas),
        'polyline_json': jsonEncode(polyline),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

class DrawnRoute {
  final List<Map<String, dynamic>> paradas;
  final List<List<double>> polyline;
  const DrawnRoute({required this.paradas, required this.polyline});
}

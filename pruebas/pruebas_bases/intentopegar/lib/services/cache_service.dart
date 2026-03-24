import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../config/app_config.dart';
import '../data/seed_data.dart';

/// Cache SQLite local para datos de rutas y paradas.
///
/// Patrón Singleton: acceder via [CacheService.instance].
/// Esta BD es la "cacheable" — contiene datos de la innovación (rutas/paradas).
/// No contiene datos sensibles de usuario (esos van en MySQL remoto).
///
/// Se siembra una sola vez con datos hardcoded de [SeedData].
/// Después se actualiza desde la API cuando hay conexión.
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  static Database? _database;

  /// True si la BD fue recién sembrada (primera vez).
  bool fueRecienSembrada = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final ubicacion = await getDatabasesPath();
    final path = join(ubicacion, AppConfig.localDbName);
    return await openDatabase(
      path,
      version: AppConfig.localDbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Crear tablas — schema idéntico al de MySQL para compatibilidad.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rutas (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        number_code    TEXT    NOT NULL UNIQUE,
        name           TEXT    NOT NULL,
        color          TEXT    NOT NULL,
        description    TEXT,
        start_point    TEXT    NOT NULL,
        end_point      TEXT    NOT NULL,
        estimated_time INTEGER NOT NULL,
        is_active      INTEGER NOT NULL DEFAULT 1,
        created_at     TEXT    NOT NULL,
        updated_at     TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS paradas (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        route_id       INTEGER NOT NULL,
        name           TEXT    NOT NULL,
        latitude       REAL    NOT NULL,
        longitude      REAL    NOT NULL,
        order_in_route INTEGER NOT NULL,
        created_at     TEXT    NOT NULL,
        FOREIGN KEY (route_id) REFERENCES rutas(id) ON DELETE CASCADE
      )
    ''');

    await _sembrar(db);
    fueRecienSembrada = true;
  }

  /// Inserta datos de [SeedData] en la BD local.
  Future<void> _sembrar(Database db) async {
    final now = DateTime.now().toIso8601String();

    final rutaIds = <int>[];
    for (final ruta in SeedData.rutas) {
      final id = await db.insert('rutas', {
        ...ruta,
        'created_at': now,
        'updated_at': now,
      });
      rutaIds.add(id);
    }

    // Insertar paradas con el ID real de su ruta.
    for (final parada in SeedData.paradas) {
      final rutaIndex = parada['ruta_index'] as int;
      final datos = Map<String, dynamic>.from(parada)..remove('ruta_index');
      datos['route_id'] = rutaIds[rutaIndex];
      datos['created_at'] = now;
      await db.insert('paradas', datos);
    }
  }

  /// Obtiene todas las rutas con sus paradas embebidas.
  Future<List<Map<String, dynamic>>> leerRutasConParadas() async {
    final db = await database;
    final rutas = await db.query('rutas', where: 'is_active = 1');

    final resultado = <Map<String, dynamic>>[];
    for (final ruta in rutas) {
      final paradas = await db.query(
        'paradas',
        where: 'route_id = ?',
        whereArgs: [ruta['id']],
        orderBy: 'order_in_route ASC',
      );
      resultado.add({...ruta, 'stops': paradas});
    }
    return resultado;
  }

  /// Cuenta las rutas en la BD local.
  Future<int> contarRutas() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM rutas');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Cuenta las paradas en la BD local.
  Future<int> contarParadas() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM paradas');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ──────────────────────────────────────────────
  // Escritura (para sincronizar desde API)
  // ──────────────────────────────────────────────

  /// Reemplaza todos los datos locales con los del servidor.
  /// Se usa después de un fetch exitoso de la API.
  Future<void> sincronizarDesdeApi(List<Map<String, dynamic>> rutasApi) async {
    final db = await database;
    await db.transaction((txn) async {
      // Limpiar datos existentes.
      await txn.delete('paradas');
      await txn.delete('rutas');

      // Insertar datos frescos del servidor.
      final now = DateTime.now().toIso8601String();
      for (final ruta in rutasApi) {
        final rutaId = await txn.insert('rutas', {
          'number_code': ruta['number'] ?? ruta['number_code'],
          'name': ruta['name'],
          'color': ruta['color'],
          'description': ruta['description'],
          'start_point': ruta['start_point'],
          'end_point': ruta['end_point'],
          'estimated_time': ruta['estimated_time'],
          'is_active': ruta['is_active'] ?? 1,
          'created_at': ruta['created_at'] ?? now,
          'updated_at': ruta['updated_at'] ?? now,
        });

        final stops = ruta['stops'] as List<dynamic>? ?? [];
        for (final stop in stops) {
          await txn.insert('paradas', {
            'route_id': rutaId,
            'name': stop['name'],
            'latitude': stop['lat'] ?? stop['latitude'],
            'longitude': stop['lng'] ?? stop['longitude'],
            'order_in_route': stop['order'] ?? stop['order_in_route'],
            'created_at': stop['created_at'] ?? now,
          });
        }
      }
    });
  }

  // ──────────────────────────────────────────────
  // Mantenimiento
  // ──────────────────────────────────────────────

  /// Resetea la BD: borra y recrea. Solo para desarrollo.
  Future<void> resetearBD() async {
    final ubicacion = await getDatabasesPath();
    final path = join(ubicacion, AppConfig.localDbName);
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    await deleteDatabase(path);
    fueRecienSembrada = false;
    // Al acceder a database de nuevo, se ejecuta _onCreate.
    await database;
  }

  Future<void> cerrar() async {
    await _database?.close();
    _database = null;
  }
}

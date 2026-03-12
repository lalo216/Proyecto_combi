import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'utils/common.dart';

/// Gestión del archivo SQLite: apertura, esquema y mantenimiento.
/// No contiene queries de negocio — esas viven en common.dart.
class InstalaDB {
  static final InstalaDB instance = InstalaDB._instance();
  static Database? _database;

  InstalaDB._instance();

  Future<Database> get db async {
    _database ??= await _initDb();
    return _database!;
  }

  // ─── Apertura ─────────────────────────────────────────────────────────────

  Future<Database> _initDb() async {
    final ubicacion = await getDatabasesPath();
    final path = join(ubicacion, 'combisapp.sqlite3');
    debugLog('Ruta BD: $path', tag: 'DB');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      // onUpgrade: _onUpgrade
    );
  }

  // ─── Esquema ──────────────────────────────────────────────────────────────

  /// Callback de sqflite. Se ejecuta una sola vez al crear la BD.
  /// No llamar directamente.
  Future<void> _onCreate(Database db, int version) async {
    debugLog('Creando esquema v$version...', tag: 'DB');
    await _crearTablas(db);
    debugLog('✓ Esquema listo', tag: 'DB');
  }

  /// SQL centralizado. Separado para que [verificarOCrearEsquema] lo reutilice
  /// sin duplicar instrucciones.
  Future<void> _crearTablas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rutas (
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        numero             TEXT    NOT NULL UNIQUE,
        nombre             TEXT    NOT NULL,
        color              TEXT    NOT NULL,
        descripcion        TEXT,
        coordenadas_inicio TEXT    NOT NULL,
        coordenadas_fin    TEXT    NOT NULL,
        tiempo_estimado    INTEGER NOT NULL,
        activa             INTEGER NOT NULL DEFAULT 1,
        creada_en          TEXT    NOT NULL,
        actualizada_en     TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS paradas (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        rutas_id       INTEGER NOT NULL,
        nombre         TEXT    NOT NULL,
        latitud        REAL    NOT NULL,
        longitud       REAL    NOT NULL,
        orden_en_ruta  INTEGER NOT NULL,
        creada_en      TEXT    NOT NULL,
        FOREIGN KEY (rutas_id) REFERENCES rutas (id) ON UPDATE CASCADE
      )
    ''');
  }

  // ─── Mantenimiento ────────────────────────────────────────────────────────

  /// Verifica si las tablas existen; las crea si no.
  /// Regresa [true] si tuvo que crearlas.
  Future<bool> verificarOCrearEsquema() async {
    final basedatos = await db;
    final resultado = await basedatos.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='rutas'",
    );

    if (resultado.isEmpty) {
      debugLog('Tablas ausentes — creando...', tag: 'DB');
      await _crearTablas(basedatos);
      debugLog('✓ Esquema creado por verificarOCrearEsquema()', tag: 'DB');
      return true;
    }

    debugLog('✓ Esquema verificado', tag: 'DB');
    return false;
  }

  /// Destruye y recrea todas las tablas. Solo para desarrollo.
  Future<bool> resetearBD() async {
    try {
      final basedatos = await db;
      debugLog('Reseteando BD...', tag: 'DB');
      await basedatos.execute('DROP TABLE IF EXISTS paradas');
      await basedatos.execute('DROP TABLE IF EXISTS rutas');
      await _crearTablas(basedatos);
      debugLog('✓ BD reseteada', tag: 'DB');
      return true;
    } catch (e, st) {
      errorLog('Fallo el reset', error: e, stackTrace: st, tag: 'DB');
      return false;
    }
  }

  Future<bool> cerrarBD() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      debugLog('BD cerrada', tag: 'DB');
      return true;
    }
    return false;
  }
}
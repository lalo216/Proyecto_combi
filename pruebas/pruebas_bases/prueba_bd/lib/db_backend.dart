import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../utils/common.dart';
import '../models/ruta.dart';

/// Instalador de Base de Datos SQLite
class InstalaDB {
  static final InstalaDB instance = InstalaDB._instance();
  static Database? _database;

  InstalaDB._instance();

  Future<Database> get db async {
    _database ??= await initDb();
    return _database!;
  }

  Future<Database> initDb() async {
    final ubicaciondb = await getDatabasesPath();
    final path = join(ubicaciondb, 'combisapp.sqlite3');

    debugLog('Ruta de la BD: $path', tag: 'DB');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      // onUpgrade: _onUpgrade, // TODO: Fase 3b
    );
  }
  Future<void> _onCreate(Database db, int version) async {
    debugLog('Creando esquema inicial v$version...', tag: 'DB');
    await _crearTablas(db);
    debugLog('✓ Esquema creado', tag: 'DB');
  }

  Future<void> _crearTablas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rutas (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        numero            TEXT    NOT NULL UNIQUE,
        name              TEXT    NOT NULL,
        color             TEXT    NOT NULL,
        description       TEXT,
        coordenadas_inicio TEXT   NOT NULL,
        coordenadas_fin   TEXT    NOT NULL,
        estimated_time    INTEGER NOT NULL,
        is_active         INTEGER NOT NULL DEFAULT 1,
        created_at        TEXT    NOT NULL,
        updated_at        TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS paradas (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        rutas_id       INTEGER NOT NULL,
        name           TEXT    NOT NULL,
        latitude       REAL    NOT NULL,
        longitude      REAL    NOT NULL,
        order_in_route INTEGER NOT NULL,
        created_at     TEXT    NOT NULL,
        FOREIGN KEY (rutas_id) REFERENCES rutas (id) ON UPDATE CASCADE
      )
    ''');
    Future<int> jalafinparadas() async {
  try {
    final tablaparadas = db.rawQuery(
     "SELECT MAX(id) as ultimo FROM paradas"
     );
     if (tablaparadas.isNotEmpty && tablaparadas.last['ultimo'] != null) {
      return resultado.last['ultimo'] as int;
     }
  else 
    return 0; // Retornamos 0 si la tabla está vacía
  } catch (e) {
    errorLog('Error al obtener el último ID', error: e, tag: 'DB');
    return -1;
  }
}

// Crud super basico

  Future<List<Ruta>> obtenRutas() async {
    try {
      final basedatos = await db;
      final filas = await basedatos.query('rutas', orderBy: 'numero ASC');
      return filas.map(Ruta.fromMap).toList();
    } catch (e) {
      errorLog('Error al obtener rutas', error: e, tag: 'DB');
      return [];
    }
  }

   Future<bool> resetearBD() async {
    try {
      debugLog('Reseteando BD...', tag: 'DB');
      final basedatos = await db;
      await basedatos.execute('DROP TABLE IF EXISTS paradas');
      await basedatos.execute('DROP TABLE IF EXISTS rutas');
      await _crearTablas(basedatos);
      debugLog('✓ BD reseteada', tag: 'DB');
      return true;
    } catch (e, stackTrace) {
      errorLog('Fallo el reset de BD', error: e, stackTrace: stackTrace, tag: 'DB');
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
  }
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import './models/modelos.dart';

/// Capa de persistencia SQLite para la Combis App.
///
/// Patrón Singleton: acceder siempre via [InstalaDB.instance].
/// Los errores de inicialización se exponen en [errorNotifier] para
/// que la UI pueda reaccionar sin lanzar excepciones al árbol de widgets.
///
/// Puntos de fallo reales:
///   • [_crearTablas]        — SQL malformado o disco lleno
///   • [_sembrarDatosEjemplo] — violación de UNIQUE en los INSERT iniciales
/// Los métodos CRUD individuales son poco propensos a fallar en condiciones normales.
class InstalaDB {
  InstalaDB._();
  static final InstalaDB instance = InstalaDB._();

  static Database? _database;
  final String _dbName = 'combis.db';

  /// Incrementar manualmente al cambiar el esquema.
  static const int dbVersion = 1;

  /// Canal reactivo de errores. La UI escucha este notifier.
  /// null  → sin error activo
  /// String → mensaje descriptivo del último error
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  void limpiarError() => errorNotifier.value = null;

  // ──────────────────────────────────────────────
  // Inicialización
  // ──────────────────────────────────────────────

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDb();
      return _database!;
    } catch (e) {
      // Este catch cubre fallos en _crearTablas y _sembrarDatosEjemplo.
      // errorNotifier ya fue actualizado con el mensaje específico dentro de _onCreate,
      // pero si el error viene del propio openDatabase lo cubrimos aquí también.
      errorNotifier.value ??= 'No se pudo abrir la base de datos: $e';
      rethrow;
    }
  }

  Future<Database> _initDb() async {
    final ubicacion = await getDatabasesPath();
    final path = join(ubicacion, _dbName);
    return await openDatabase(path, version: dbVersion, onCreate: _onCreate);
  }

  /// sqflite llama a este método solo cuando la BD no existe todavía.
  /// Se ejecuta una única vez en el ciclo de vida de la app.
  Future<void> _onCreate(Database db, int version) async {
    // Paso 1: estructura — el más crítico; sin tablas no hay app.
    try {
      await _crearTablas(db);
    } catch (e) {
      errorNotifier.value = 'Error al crear tablas: $e';
      rethrow;
    }

    // Paso 2: datos de ejemplo — falla si hay duplicados u otro constraint.
    try {
      await _sembrarDatosEjemplo(db);
    } catch (e) {
      errorNotifier.value = 'Error al sembrar datos iniciales: $e';
      rethrow;
    }
  }

  Future<void> _crearTablas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rutas (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre    TEXT    NOT NULL UNIQUE,
        numero    TEXT    NOT NULL,
        favoritas INTEGER NOT NULL DEFAULT 0,
        paradas   INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuarios (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre      TEXT    NOT NULL,
        correo      TEXT    NOT NULL UNIQUE,
        contrasenna TEXT    NOT NULL,
        rol         TEXT    NOT NULL DEFAULT 'usuario'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS combis (
        id     INTEGER PRIMARY KEY AUTOINCREMENT,
        placas TEXT    NOT NULL UNIQUE,
        chofer TEXT    NOT NULL
      )
    ''');
  }

  Future<void> _sembrarDatosEjemplo(Database db) async {
    await db.execute('''
      INSERT INTO rutas (nombre, numero, favoritas, paradas)
      VALUES
        ("Virgen",  "01", 15, 5),
        ("Ocotlan", "12",  8, 12)
    ''');

    await db.execute('''
      INSERT INTO usuarios (nombre, correo, contrasenna, rol)
      VALUES ("Admin", "admin@coolbis.com", "Admin", "admin")
    ''');
  }

  // ──────────────────────────────────────────────
  // Utilidades de esquema
  // ──────────────────────────────────────────────

  /// Abre (o crea) la BD. Devuelve true si todo está bien.
  Future<bool> verificarOCrearEsquema() async {
    try {
      await database;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int> contarTablas() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ──────────────────────────────────────────────
  // CRUD — Rutas
  // ──────────────────────────────────────────────

  Future<List<Ruta>> obtenerRutas() async {
    final db = await database;
    final maps = await db.query('rutas');
    return maps.map(Ruta.fromMap).toList();
  }

  Future<int> contarRutas() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM rutas');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> insertarRuta(Ruta ruta) async {
    final db = await database;
    return db.insert('rutas', ruta.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> actualizarRuta(Ruta ruta) async {
    final db = await database;
    return db.update('rutas', ruta.toMap(),
        where: 'id = ?', whereArgs: [ruta.id]);
  }

  Future<int> eliminarRuta(int id) async {
    final db = await database;
    return db.delete('rutas', where: 'id = ?', whereArgs: [id]);
  }

  // ──────────────────────────────────────────────
  // Mantenimiento
  // ──────────────────────────────────────────────

  /// Borra y recrea la BD desde cero. Útil durante desarrollo.
  Future<bool> resetearBD() async {
    try {
      final ubicacion = await getDatabasesPath();
      final path = join(ubicacion, _dbName);
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      await deleteDatabase(path);
      await database; // dispara _onCreate de nuevo
      return true;
    } catch (e) {
      errorNotifier.value = 'Error al resetear BD: $e';
      return false;
    }
  }

  Future<void> cerrarBD() async {
    await _database?.close();
    _database = null;
  }
}
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'log/db_logger.dart';

/// Gestión del archivo SQLite: apertura, esquema y mantenimiento.
class InstalaDB {
  static final InstalaDB instance = InstalaDB._instance();
  static Database? _database;
  
  static const String _dbName = 'combisapp.db';
  static const int _dbVersion = 1;

  InstalaDB._instance();

  Future<Database> get db async {
    _database ??= await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path;
    if (kIsWeb) {
      DBLogger.log('Iniciando BD en Web (IndexedDB)');
      databaseFactory = databaseFactoryFfiWeb;
      path = _dbName;
    } else {
      final ubicacion = await getDatabasesPath();
      path = join(ubicacion, _dbName);
      DBLogger.log('Iniciando BD en Local: $path');
    }

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    DBLogger.log('Creando esquema v$version...');
    await _crearTablas(db);
    await _sembrarDatosEjemplo(db);
    DBLogger.log('✓ Esquema listo y datos sembrados');
  }

  /// SQL centralizado. Separado para que [verificarOCrearEsquema] lo reutilice
  /// sin duplicar instrucciones.
  Future<void> _crearTablas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rutas (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre           TEXT    NOT NULL UNIQUE,
        numero           TEXT    NOT NULL,
        favoritas        INTEGER NOT NULL DEFAULT 0,
        paradas          INTEGER NOT NULL DEFAULT 0,
        tiempo_estimado  INTEGER NOT NULL DEFAULT 0,
        activa           INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuarios (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre         TEXT    NOT NULL,
        correo         TEXT    NOT NULL UNIQUE,
        contrasenna    TEXT    NOT NULL,
        rol            TEXT    NOT NULL DEFAULT 'usuario'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS combis (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        placas         TEXT    NOT NULL UNIQUE,
        chofer         TEXT    NOT NULL
      )
    ''');
  }

  Future<bool> verificarOCrearEsquema() async {
    try {
      final basedatos = await db;
      final resultado = await basedatos.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='rutas'",
      );

      if (resultado.isEmpty) {
        DBLogger.log('Tablas ausentes — creando...');
        await _crearTablas(basedatos);
        await _sembrarDatosEjemplo(basedatos);
        return true;
      }
      DBLogger.log('✓ Esquema verificado');
      return false;
    } catch (e, st) {
      DBLogger.error('Error al verificar esquema', error: e, stackTrace: st);
      return false;
    }
  }

  Future<bool> resetearBD() async {
    try {
      final basedatos = await db;
      DBLogger.log('Reseteando BD...');
      await basedatos.execute('DROP TABLE IF EXISTS rutas');
      await basedatos.execute('DROP TABLE IF EXISTS usuarios');
      await basedatos.execute('DROP TABLE IF EXISTS combis');
      await _crearTablas(basedatos);
      await _sembrarDatosEjemplo(basedatos);
      DBLogger.log('✓ BD reseteada exitosamente');
      return true;
    } catch (e, st) {
      DBLogger.error('Fallo el reset de BD', error: e, stackTrace: st);
      return false;
    }
  }

  Future<void> _sembrarDatosEjemplo(Database db) async {
    // Insertar rutas de ejemplo
    await db.execute('''
      INSERT INTO rutas (nombre, numero, favoritas, paradas, tiempo_estimado, activa)
      VALUES 
      ("Centro Directo", "01", 15, 5, 25, 1),
      ("Circuito Norte", "12", 8, 12, 45, 1)
    ''');
    
    // Insertar un administrador de ejemplo
    await db.execute('''
      INSERT INTO usuarios (nombre, correo, contrasenna, rol)
      VALUES ("Admin Root", "admin@coolbis.com", "root123", "admin")
    ''');

    DBLogger.log('✓ Datos de ejemplo sembrados con roles y rutas extendidas');
  }


  Future<bool> cerrarBD() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      DBLogger.log('BD cerrada');
      return true;
    }
    return false;
  }
}
// Patrón Singleton: acceder siempre via DatabaseHelper.instance.
// La BD es una caché de sólo lectura para datos (preferiblemente) solo accesibles mediante nuestros endpoints.
// El servidor MySQL es la fuente de verdad, la bd mysqlite que carga el usuario contiene información identificable.

import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/ruta.dart';
import '../models/parada.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;
  static const int _version = 1;
  static const String _dbName = 'combis.db';

  Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }
    // Compatibilidad
  Future<Database> _init() async {
    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(path, version: _version, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int _) async {
    await db.execute('''
      CREATE TABLE rutas (
        id             INTEGER PRIMARY KEY,
        number         TEXT    NOT NULL,
        name           TEXT    NOT NULL,
        color          TEXT    NOT NULL,
        description    TEXT,
        start_point    TEXT,
        end_point      TEXT,
        estimated_time INTEGER NOT NULL DEFAULT 0,
        is_active      INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE paradas (
        id          INTEGER PRIMARY KEY,
        route_id    INTEGER NOT NULL,
        name        TEXT    NOT NULL,
        lat         REAL    NOT NULL,
        lng         REAL    NOT NULL,
        stop_order  INTEGER NOT NULL,
        FOREIGN KEY(route_id) REFERENCES rutas(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE meta_sync (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.insert('meta_sync', {'key': 'schema_version', 'value': '0'});
  }


  Future<int> getSchemaVersion() async {
    final d = await db;
    final rows = await d.query(
      'meta_sync',
      where: 'key = ?',
      whereArgs: ['schema_version'],
    );
    if (rows.isEmpty) return 0;
    return int.tryParse(rows.first['value'] as String) ?? 0;
  }

  /// Reemplaza todas las rutas y paradas en una única transacción atómica
  Future<void> replaceAll(
    List<Ruta> rutas,
    List<Parada> paradas,
    int schemaVersion,
  ) async {
    final d = await db;
    await d.transaction((txn) async {
      await txn.delete('paradas');
      await txn.delete('rutas');
      for (final r in rutas) {
        await txn.insert('rutas', r.toMap());
      }
      for (final p in paradas) {
        await txn.insert('paradas', p.toMap());
      }
      await txn.update(
        'meta_sync',
        {'value': schemaVersion.toString()},
        where: 'key = ?',
        whereArgs: ['schema_version'],
      );
    });
  }

 
  Future<List<Ruta>> getRutas() async {
    final d = await db;
    final maps = await d.query(
      'rutas',
      where: 'is_active = 1',
      orderBy: 'number ASC',
    );
    return maps.map(Ruta.fromMap).toList();
  }


  Future<List<Parada>> getParadas(int routeId) async {
    final d = await db;
    final maps = await d.query(
      'paradas',
      where: 'route_id = ?',
      whereArgs: [routeId],
      orderBy: 'stop_order ASC',
    );
    return maps.map(Parada.fromMap).toList();
  }

  Future<List<Parada>> getAllParadas() async {
    final d = await db;
    final maps = await d.query(
      'paradas',
      orderBy: 'route_id ASC, stop_order ASC',
    );
    return maps.map(Parada.fromMap).toList();
  }
}

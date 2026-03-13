import 'package:sqflite/sqflite.dart';
import '../db_backend.dart';
import '../models/modelos.dart';

// ─── Debug ────────────────────────────────────────────────────────────────────

void debugLog(String mensaje, {String tag = 'APP'}) {
  DBLogger.log(mensaje, tag: tag);
}

void errorLog(
  String mensaje, {
  required Object error,
  StackTrace? stackTrace,
  String tag = 'APP',
}) {
  DBLogger.error(mensaje, error: error, stackTrace: stackTrace, tag: tag);
}


Future<int> contarRutas() async {
  try {
    final basedatos = await InstalaDB.instance.db;
    final resultado = await basedatos.rawQuery(
      'SELECT COUNT(*) as total FROM rutas',
    );
    return Sqflite.firstIntValue(resultado) ?? 0;
  } catch (e) {
    errorLog('Error al contar rutas', error: e, tag: 'DB');
    return -1;
  }
}

/// Cuenta el número de tablas creadas por el usuario en la BD
Future<int> contarTablas() async {
  try {
    final basedatos = await InstalaDB.instance.db;
    final resultado = await basedatos.rawQuery(
        "SELECT COUNT(*) as count FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
    return Sqflite.firstIntValue(resultado) ?? 0;
  } catch (e) {
    errorLog('Error al contar tablas', error: e, tag: 'DB');
    return -1;
  }
}

/// Regresa todas las rutas ordenadas por número.
Future<List<Ruta>> obtenRutas() async {
  try {
    final basedatos = await InstalaDB.instance.db;
    final filas = await basedatos.query('rutas', orderBy: 'numero ASC');
    return filas.map(Ruta.fromMap).toList();
  } catch (e) {
    errorLog('Error al obtener rutas', error: e, tag: 'DB');
    return [];
  }
}

/// Inserta una ruta. Regresa el ID asignado, o -1 si falló.
Future<int> insertarRuta(Ruta ruta) async {
  try {
    final basedatos = await InstalaDB.instance.db;
    return await basedatos.insert('rutas', ruta.toMap());
  } catch (e) {
    errorLog('Error al insertar ruta', error: e, tag: 'DB');
    return -1;
  }
}

/// Actualiza una ruta existente. Regresa filas afectadas (1 si funcionó, 0 si no).
Future<int> actualizarRuta(Ruta ruta) async {
  try {
    final basedatos = await InstalaDB.instance.db;
    return await basedatos.update(
      'rutas',
      ruta.toMap(),
      where: 'id = ?',
      whereArgs: [ruta.id],
    );
  } catch (e) {
    errorLog('Error al actualizar ruta', error: e, tag: 'DB');
    return -1;
  }
}
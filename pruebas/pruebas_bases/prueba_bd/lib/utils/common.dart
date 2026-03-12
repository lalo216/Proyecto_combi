import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../db_backend.dart';
import '../models/ruta.dart';

// ─── Debug ────────────────────────────────────────────────────────────────────

/// Imprime en consola solo en modo debug. No hace nada en release.
void debugLog(String mensaje, {String tag = 'APP'}) {
  if (kDebugMode) debugPrint('[$tag] $mensaje');
}

/// Igual que [debugLog] pero formatea el error y el stack trace.
void errorLog(
  String mensaje, {
  required Object error,
  StackTrace? stackTrace,
  String tag = 'APP',
}) {
  if (kDebugMode) {
    debugPrint('[$tag] ERROR: $mensaje');
    debugPrint('[$tag] → $error');
    if (stackTrace != null) debugPrint('[$tag] $stackTrace');
  }
}

// ─── Queries ──────────────────────────────────────────────────────────────────

/// Devuelve cuántas rutas hay en la BD.
/// Usa COUNT(*) — no carga filas al cliente.
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
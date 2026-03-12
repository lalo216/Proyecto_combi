import 'package:flutter/foundation.dart';

/// Log de depuración — solo imprime en desarrollo
void debugLog(String message, {String? tag}) {
  if (kDebugMode) {
    final prefix = tag != null ? '[$tag]' : '[CombisApp]';
    debugPrint('$prefix $message');
  }
}

/// Log de error con error y stack trace opcionales
void errorLog(
  String message, {
  String? tag,
  dynamic error,
  StackTrace? stackTrace,
}) {
  if (kDebugMode) {
    final prefix = tag != null ? '[$tag]' : '[ERROR]';
    debugPrint('$prefix $message');
    if (error != null) debugPrint('  Error: $error');
    if (stackTrace != null) debugPrint('  Stack: $stackTrace');
  }
}

// ============ FORMATO ============

/// Formatear duración para mostrar (ej. "5 min", "1 hora")
String formatDuration(int minutes) {
  if (minutes < 60) {
    return '$minutes min';
  }
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  return mins > 0 ? '$hours h ${mins}m' : '$hours h';
}

/// Formatear distancia (ej. "1.5 km", "500 m")
String formatDistance(double km) {
  if (km < 1) {
    final meters = (km * 1000).toInt();
    return '$meters m';
  }
  return '${km.toStringAsFixed(1)} km';
}

/// Verificar si un string no está vacío
bool isNotEmpty(String? value) {
  return value != null && value.trim().isNotEmpty;
}

const String databaseName = 'combisapp.db';
const int databaseVersion = 1;

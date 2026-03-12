import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Modelo local que representa una ruta de combi.
/// Refleja directamente la tabla [rutas] en la BD SQLite.
class Ruta {
  final int? id;
  final String numero;
  final String nombre;
  final Color color;
  final String? descripcion;
  final LatLng coordenadasInicio;
  final LatLng coordenadasFin;
  final int tiempoEstimado; // en minutos
  final bool activa;
  final DateTime creadaEn;
  final DateTime actualizadaEn;

  const Ruta({
    this.id,
    required this.numero,
    required this.nombre,
    required this.color,
    this.descripcion,
    required this.coordenadasInicio,
    required this.coordenadasFin,
    required this.tiempoEstimado,
    this.activa = true,
    required this.creadaEn,
    required this.actualizadaEn,
  });

  // ─── Serialización ────────────────────────────────────────────────────────

  /// Convierte una fila de la BD (Map) a un objeto Ruta.
  factory Ruta.fromMap(Map<String, dynamic> mapa) {
    return Ruta(
      id: mapa['id'] as int?,
      numero: mapa['numero'] as String,
      nombre: mapa['name'] as String,
      color: _hexAColor(mapa['color'] as String),
      descripcion: mapa['description'] as String?,
      coordenadasInicio: _textoALatLng(mapa['coordenadas_inicio'] as String),
      coordenadasFin: _textoALatLng(mapa['coordenadas_fin'] as String),
      tiempoEstimado: mapa['estimated_time'] as int,
      activa: (mapa['is_active'] as int) == 1,
      creadaEn: DateTime.parse(mapa['created_at'] as String),
      actualizadaEn: DateTime.parse(mapa['updated_at'] as String),
    );
  }

  /// Convierte el objeto Ruta a un Map listo para insertar en la BD.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'numero': numero,
      'nombre': nombre,
      'color': _colorAHex(color),
      'description': descripcion,
      'coordenadas_inicio': _latLngATexto(coordenadasInicio),
      'coordenadas_fin': _latLngATexto(coordenadasFin),
      'estimated_time': tiempoEstimado,
      'is_active': activa ? 1 : 0,
      'created_at': creadaEn.toIso8601String(),
      'updated_at': actualizadaEn.toIso8601String(),
    };
  }

  // ─── Helpers de conversión (privados) ─────────────────────────────────────

  /// "19.3184,-98.2334" → LatLng(19.3184, -98.2334)
  static LatLng _textoALatLng(String texto) {
    final partes = texto.split(',');
    return LatLng(double.parse(partes[0]), double.parse(partes[1]));
  }

  static String _latLngATexto(LatLng coord) =>
      '${coord.latitude},${coord.longitude}';

  static Color _hexAColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', '0xFF')));

  static String _colorAHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  @override
  String toString() => 'Ruta($numero — $nombre)';
}
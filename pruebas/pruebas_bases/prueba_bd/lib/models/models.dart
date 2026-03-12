// import 'package:flutter/material.dart';

/// Modelo de Ruta - Escalable y simple.
class Ruta {
  final int? id;
  final String numero;
  final String nombre;
  final int favoritas;
  final int paradas;
  final int tiempoEstimado; // en minutos
  final bool activa;

  const Ruta({
    this.id,
    required this.numero,
    required this.nombre,
    this.favoritas = 0,
    this.paradas = 0,
    this.tiempoEstimado = 0,
    this.activa = true,
  });

  factory Ruta.fromMap(Map<String, dynamic> map) {
    return Ruta(
      id: map['id'] as int?,
      numero: map['numero'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      favoritas: map['favoritas'] as int? ?? 0,
      paradas: map['paradas'] as int? ?? 0,
      tiempoEstimado: map['tiempo_estimado'] as int? ?? 0,
      activa: (map['activa'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'numero': numero,
      'nombre': nombre,
      'favoritas': favoritas,
      'paradas': paradas,
      'tiempo_estimado': tiempoEstimado,
      'activa': activa ? 1 : 0,
    };
  }
}

/// Modelo de Usuario con distinción de Roles.
class Usuario {
  final int? id;
  final String nombre;
  final String correo;
  final String contrasenna;
  final String rol; // 'admin' o 'usuario'

  const Usuario({
    this.id,
    required this.nombre,
    required this.correo,
    required this.contrasenna,
    this.rol = 'usuario',
  });

  bool get isAdmin => rol == 'admin';

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as int?,
      nombre: map['nombre'] as String? ?? '',
      correo: map['correo'] as String? ?? '',
      contrasenna: map['contrasenna'] as String? ?? '',
      rol: map['rol'] as String? ?? 'usuario',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'correo': correo,
      'contrasenna': contrasenna,
      'rol': rol,
    };
  }
}

/// Modelo de Combi.
class Combi {
  final int? id;
  final String placas;
  final String chofer;

  const Combi({
    this.id,
    required this.placas,
    required this.chofer,
  });

  factory Combi.fromMap(Map<String, dynamic> map) {
    return Combi(
      id: map['id'] as int?,
      placas: map['placas'] as String? ?? '',
      chofer: map['chofer'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'placas': placas,
      'chofer': chofer,
    };
  }
}

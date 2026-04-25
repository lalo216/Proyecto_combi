// Modelo de ruta de combi.

class Ruta {
  final int id;
  final String number;        // 'A', 'B', 'C'
  final String name;          // 'Centro → Volcanes'
  final String color;         // '#FF6D00'
  final String? description;
  final String? startPoint;
  final String? endPoint;
  final int estimatedTime;    // minutos
  final bool isActive;

  const Ruta({
    required this.id,
    required this.number,
    required this.name,
    required this.color,
    this.description,
    this.startPoint,
    this.endPoint,
    this.estimatedTime = 0,
    this.isActive = true,
  });

  // ── SQLite ────────────────────────────────────────────────────────────────

  factory Ruta.fromMap(Map<String, dynamic> map) => Ruta(
        id:            map['id']             as int,
        number:        map['number']         as String,
        name:          map['name']           as String,
        color:         map['color']          as String,
        description:   map['description']    as String?,
        startPoint:    map['start_point']    as String?,
        endPoint:      map['end_point']      as String?,
        estimatedTime: map['estimated_time'] as int? ?? 0,
        isActive:     (map['is_active']      as int?  ?? 1) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id':             id,
        'number':         number,
        'name':           name,
        'color':          color,
        'description':    description,
        'start_point':    startPoint,
        'end_point':      endPoint,
        'estimated_time': estimatedTime,
        'is_active':      isActive ? 1 : 0,
      };

  // ── API ───────────────────────────────────────────────────────────────────
  // Coincide con el JSON que devuelve sync.php (array "rutas").
  // routes.php devuelve el mismo contrato sin el campo de paradas incrustado.

  factory Ruta.fromJson(Map<String, dynamic> json) => Ruta(
        id:            json['id']             as int,
        number:        json['number']         as String,
        name:          json['name']           as String,
        color:         json['color']          as String,
        description:   json['description']    as String?,
        startPoint:    json['start_point']    as String?,
        endPoint:      json['end_point']      as String?,
        estimatedTime: json['estimated_time'] as int? ?? 0,
        isActive:     (json['is_active']      as int?  ?? 1) == 1,
      );
}

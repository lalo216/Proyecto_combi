// Modelo de parada (stop) de una ruta de combi.

class Parada {
  final int id;
  final int routeId;
  final String name;
  final double lat;
  final double lng;
  final int order;   

  const Parada({
    required this.id,
    required this.routeId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.order,
  });

  // Nota: SQLite reserva la palabra ORDER, así que la columna se llama stop_order.

  factory Parada.fromMap(Map<String, dynamic> map) => Parada(
        id:      map['id']         as int,
        routeId: map['route_id']   as int,
        name:    map['name']       as String,
        lat:    (map['lat']        as num).toDouble(),
        lng:    (map['lng']        as num).toDouble(),
        order:   map['stop_order'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id':         id,
        'route_id':   routeId,
        'name':       name,
        'lat':        lat,
        'lng':        lng,
        'stop_order': order,
      };

  // ── API — sync.php ────────────────────────────────────────────────────────
  // JSON: { "id":101, "ruta_id":1, "name":"Zócalo", "lat":19.31, "lng":-98.19, "order":0 }

  factory Parada.fromJson(Map<String, dynamic> json) => Parada(
        id:      json['id']      as int,
        routeId: json['ruta_id'] as int,
        name:    json['name']    as String,
        lat:    (json['lat']     as num).toDouble(),
        lng:    (json['lng']     as num).toDouble(),
        order:   json['order']   as int,
      );

  // ── API — routes.php (paradas incrustadas, sin ruta_id) ──────────────────
  // JSON: { "id":101, "name":"Zócalo", "lat":19.31, "lng":-98.19, "order":0 }

  factory Parada.fromJsonEmbedded(Map<String, dynamic> json, int routeId) => Parada(
        id:      json['id']    as int,
        routeId: routeId,
        name:    json['name']  as String,
        lat:    (json['lat']   as num).toDouble(),
        lng:    (json['lng']   as num).toDouble(),
        order:   json['order'] as int,
      );
}

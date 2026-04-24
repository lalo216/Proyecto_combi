/// Datos hardcoded para el siembro inicial de la BD local (SQLite).
///
/// Estos datos son el último fallback: si no hay API ni cache,
/// la app siembra la BD con esta información para funcionar offline.
/// Las coordenadas son reales de Chiautempan/Tlaxcala (~19.31°N, -98.19°O).
class SeedData {
  SeedData._();

  /// Rutas de ejemplo para el siembro inicial.
  /// Cada mapa sigue el schema de la tabla `rutas`.
  static const List<Map<String, dynamic>> rutas = [
    {
      'number_code': 'A',
      'name': 'Centro → Volcanes',
      'color': '#FF6D00',
      'description': 'Ruta principal del centro a la zona de Volcanes',
      'start_point': 'Zócalo de Chiautempan',
      'end_point': 'Volcanes',
      'estimated_time': 25,
      'is_active': 1,
    },
    {
      'number_code': 'B',
      'name': 'Ocotlán → Centro',
      'color': '#1E88E5',
      'description': 'Conecta la Basílica de Ocotlán con el centro de Tlaxcala',
      'start_point': 'Basílica de Ocotlán',
      'end_point': 'Centro Tlaxcala',
      'estimated_time': 20,
      'is_active': 1,
    },
  ];

  /// Paradas de ejemplo. El campo `ruta_index` mapea al índice en [rutas]
  /// (0-based). Se reemplaza por el ID real al insertar en la BD.
  static const List<Map<String, dynamic>> paradas = [
    // Ruta A: Centro → Volcanes
    {
      'ruta_index': 0,
      'name': 'Zócalo',
      'latitude': 19.3060000,
      'longitude': -98.1870000,
      'order_in_route': 1,
    },
    {
      'ruta_index': 0,
      'name': 'Mercado',
      'latitude': 19.3080000,
      'longitude': -98.1850000,
      'order_in_route': 2,
    },
    {
      'ruta_index': 0,
      'name': 'Volcanes',
      'latitude': 19.3200000,
      'longitude': -98.1700000,
      'order_in_route': 3,
    },
    // Ruta B: Ocotlán → Centro
    {
      'ruta_index': 1,
      'name': 'Basílica',
      'latitude': 19.3140000,
      'longitude': -98.2340000,
      'order_in_route': 1,
    },
    {
      'ruta_index': 1,
      'name': 'Av. Juárez',
      'latitude': 19.3120000,
      'longitude': -98.2200000,
      'order_in_route': 2,
    },
    {
      'ruta_index': 1,
      'name': 'Centro',
      'latitude': 19.3100000,
      'longitude': -98.2080000,
      'order_in_route': 3,
    },
  ];
}

// Estos IDs son permanentes — nunca eliminar ni renumerar sin una migración apropiada. PORFAVOR!!!
// El servidor MySQL es la fuente de verdad; esto es el fallback para cuando
// boot_page.dart no puede alcanzar sync.php en el primer arranque.
//
// Las coordenadas son aproximaciones muy equis (~19.306°N, -98.187°O).

import '../database/database_helper.dart';
import '../models/ruta.dart';
import '../models/parada.dart';

class SeedData {
  SeedData._();


  static const List<Ruta> rutas = [
    Ruta(id: 1, number: 'A', name: 'Centro → Volcanes',     color: '#FF6D00'),
    Ruta(id: 2, number: 'B', name: 'Escalinatas → Mercado', color: '#FF8500'),
    Ruta(id: 3, number: 'C', name: 'Zócalo → Bienestar',    color: '#9D4EDD'),
  ];


  static const List<Parada> paradas = [
    // Ruta A — Centro → Volcanes
    Parada(id: 101, routeId: 1, name: 'Zócalo',       lat: 19.30950, lng: -98.18900, order: 0),
    Parada(id: 102, routeId: 1, name: 'Av. Hidalgo',  lat: 19.30700, lng: -98.18550, order: 1),
    Parada(id: 103, routeId: 1, name: 'Volcanes',     lat: 19.30250, lng: -98.18100, order: 2),

    // Ruta B — Escalinatas → Mercado
    Parada(id: 201, routeId: 2, name: 'Escalinatas',   lat: 19.31100, lng: -98.19000, order: 0),
    Parada(id: 202, routeId: 2, name: 'Plaza Central', lat: 19.30800, lng: -98.18600, order: 1),
    Parada(id: 203, routeId: 2, name: 'Mercado',       lat: 19.30500, lng: -98.18700, order: 2),

    // Ruta C — Zócalo → Bienestar
    Parada(id: 301, routeId: 3, name: 'Zócalo',        lat: 19.30950, lng: -98.18900, order: 0),
    Parada(id: 302, routeId: 3, name: 'Calle Juárez',  lat: 19.31050, lng: -98.19300, order: 1),
    Parada(id: 303, routeId: 3, name: 'Bienestar',     lat: 19.31150, lng: -98.19700, order: 2),
  ];
   /// schemaVersion = 1 coincide con SCHEMA_VERSION en common.php,
  /// así que la siguiente vez que haya conexión, sync.php devolverá "up_to_date".
  static Future<void> sembrar() async {
    await DatabaseHelper.instance.replaceAll(rutas, paradas, 1);
  }
}

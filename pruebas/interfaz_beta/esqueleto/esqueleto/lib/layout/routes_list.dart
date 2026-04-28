import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:esqueleto/layout/mapa.dart';
import 'package:esqueleto/layout/barr_nav.dart';
import 'dart:convert';

class RoutesList extends StatefulWidget {
  final String query;

  const RoutesList({super.key, required this.query});

  @override
  State<RoutesList> createState() => _RoutesListState();
}

class _RoutesListState extends State<RoutesList> {
  List rutas = [];

  @override
  void initState() {
    super.initState();
    fetchRutas();
  }

  Future<void> fetchRutas() async {
    try {
      final response = await http.get(
        Uri.parse("http://172.20.10.8/beta/rutas.php"),
      );
      if (response.statusCode == 200) {
        setState(() {
          rutas = json.decode(response.body);
        });
      } else {
        print("Error al cargar datos: ${response.statusCode}");
      }
    } catch (e) {
      print("Error de conexión: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar rutas según búsqueda
    final resultados = widget.query.isEmpty
        ? rutas // si está vacío, mostrar recientes
        : rutas
              .where(
                (ruta) => ruta["nombre_ruta"].toLowerCase().contains(
                  widget.query.toLowerCase(),
                ),
              )
              .toList();

    return Expanded(
      child: ListView.builder(
        itemCount: resultados.length,
        itemBuilder: (context, index) {
          final ruta = resultados[index];
          return ListTile(
            title: Text(ruta["nombre_ruta"]),
            subtitle: Text(
              "Horario: ${ruta["horario"]} | Tiempo: ${ruta["tiempo_recorrido"]} min",
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalleRutaPage(
                    id: ruta["id"], // atributo de la BD
                    nombre: ruta["nombre_ruta"],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Página de detalle
class DetalleRutaPage extends StatelessWidget {
  final String id;
  final String nombre;

  const DetalleRutaPage({super.key, required this.id, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Detalle de $nombre")),
      body: Stack(
        children: [
          MapaRutaPage(rutaId: int.parse(id)),
          BarraNav(),
        ],
      ),
    );
  }
}

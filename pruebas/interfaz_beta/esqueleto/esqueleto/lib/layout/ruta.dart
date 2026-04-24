import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Importa tu página de mapa
import 'mapa.dart';

class RutasContainer extends StatefulWidget {
  final String apiUrl;

  const RutasContainer({Key? key, required this.apiUrl}) : super(key: key);

  @override
  _RutasContainerState createState() => _RutasContainerState();
}

class _RutasContainerState extends State<RutasContainer> {
  List rutas = [];

  @override
  void initState() {
    super.initState();
    fetchRutas();
  }

  Future<void> fetchRutas() async {
    try {
      final response = await http.get(Uri.parse(widget.apiUrl));
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

  Color _hexToColor(String code) {
    return Color(int.parse(code.substring(1), radix: 16) + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: rutas.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3, // 👈 muestra todas las rutas
              itemBuilder: (context, index) {
                final ruta = rutas[index];
                return Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      // Navegar al mapa pasando el id de la ruta
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapaRutaPage(
                            rutaId: int.parse(ruta['id'].toString()),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ruta['nombre_ruta'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Horario: ${ruta['horario']}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Tiempo: ${ruta['tiempo_recorrido']} min",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _hexToColor(ruta['color_ruta']),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

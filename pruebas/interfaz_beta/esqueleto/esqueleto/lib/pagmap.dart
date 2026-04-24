import 'package:esqueleto/layout/mapa.dart';
import 'package:flutter/material.dart';
import 'package:esqueleto/layout/barr_nav.dart';
import 'package:flutter_map/flutter_map.dart';

class Mapa extends StatelessWidget {
  const Mapa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa")),
      body: Stack(
        children: [
          MapaRutaPage(
            rutaId: 1,
          ), // Aquí puedes pasar el ID de la ruta que quieras mostrar
          BarraNav(),
        ],
      ),
    );
  }
}

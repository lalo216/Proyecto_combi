import 'package:flutter/material.dart';
import 'package:esqueleto/layout/ruta.dart';

class Tarjetas extends StatelessWidget {
  const Tarjetas({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // contenedor con altura fija y scroll, se utilza porque singlechildscrollview no funciona con listview.builder y no tiene una propiedad fija para limitar su altura, rompiedno asi la creacion de objetos
      height: 500, // altura fija para el contenedor

      child: Stack(
        //encapsular los widget dentro de un stack para colocar el degradado encima de los widget y que no se vea afectado por el scroll
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  "Rutas recientes",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                // Primer contenedor con tarjetas+
                RutasContainer(apiUrl: 'http://localhost/beta/rutas.php'),

                Text(
                  "Rutas recomendadas",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                // Segundo contenedor con otras tarjetas o widgets
                RutasContainer(apiUrl: 'http://localhost/beta/rutas.php'),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 120, // altura del degradado
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(0, 255, 255, 255),
                    Colors.white, // color de fondo de tu pantalla
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

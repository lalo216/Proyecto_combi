import 'package:flutter/material.dart';
import 'package:esqueleto/layout/clas_boton.dart';
import 'package:esqueleto/busqueda.dart';
import 'package:esqueleto/perfil.dart';
import 'package:esqueleto/pagmap.dart';
import 'package:esqueleto/main.dart';
import 'package:esqueleto/layout/mapa/MapaUsuarioPage.dart';

class BarraNav extends StatelessWidget {
  const BarraNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      // centra el hijo en el padre
      child: Container(
        width:
            MediaQuery.of(context).size.width *
            0.95, // el ancho del contenedor es el 95% del ancho de la pantalla
        height: 100,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 97, 255, 118),
          borderRadius: BorderRadius.all(Radius.circular(15)),
          border: Border.all(
            color: const Color.fromARGB(255, 108, 107, 107),
            width: 0.5,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              spreadRadius: 2,
              blurRadius: 6,
              offset: Offset(2, 4),
            ),
          ],
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            HoverIconButton(
              icon: Icons.home,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MainApp()),
                );
              },
            ),

            HoverIconButton(
              icon: Icons.search,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Busqueda()),
                );
              },
            ),

            HoverIconButton(
              icon: Icons.map,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MapaUsuarioPage(),
                  ),
                );
              },
            ),

            HoverIconButton(
              icon: Icons.person,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Perfil()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

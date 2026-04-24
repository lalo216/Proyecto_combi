import 'package:flutter/material.dart';
import 'package:esqueleto/busqueda.dart';

class BotonBusqueda extends StatelessWidget {
  const BotonBusqueda({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20), // margen alrededor del botón
      width: MediaQuery.of(context).size.width * 0.8,
      height: 80,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Busqueda()),
          );
        },

        style: ElevatedButton.styleFrom(
          side: const BorderSide(
            color: Color.fromARGB(255, 254, 255, 255),
            width: 9,
          ), // borde en el botón
          backgroundColor: const Color.fromARGB(
            255,
            233,
            232,
            232,
          ), // color de fondo
          foregroundColor: const Color.fromARGB(
            255,
            0,
            0,
            0,
          ), // color del texto
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25), // bordes redondeados
          ),
          elevation: 7,
        ),
        child: Text(
          "¿A dónde quieres ir?",
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

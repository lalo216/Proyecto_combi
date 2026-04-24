import 'package:esqueleto/layout/boton_busq.dart';
import 'package:esqueleto/layout/barr_nav.dart';
import 'package:esqueleto/layout/rutas.dart';
import 'package:flutter/material.dart';
import 'package:esqueleto/layout/rutas.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Menú superior"), // aquí tu rectángulo de menú
          backgroundColor: Colors.green,
        ),

        body: Column(children: [BotonBusqueda(), Tarjetas(), BarraNav()]),
      ),
    );
  }
}

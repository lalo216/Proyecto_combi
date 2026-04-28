import 'package:flutter/material.dart';
import 'package:esqueleto/layout/barr_nav.dart';
import 'package:esqueleto/layout/ini_reg.dart';
import 'package:esqueleto/layout/perf.dart';

class Perfil extends StatelessWidget {
  const Perfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Perfil")),
      body: Column(
        children: [
          PerfilPage(),

          const Text("Editar Perfil"),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuthPage()),
              );
            },
            child: const Text("Cerrar Sesión"),
          ),
          BarraNav(),
        ],
      ),
    );
  }
}

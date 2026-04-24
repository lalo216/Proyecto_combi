import 'package:flutter/material.dart';
import 'package:esqueleto/layout/barr_nav.dart';

class Perfil extends StatelessWidget {
  const Perfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Perfil")),
      body: Column(
        children: [
          BarraNav()
        ]
      ),
    );
  }
}

import 'package:flutter/material.dart';

class PantallaPerfil extends StatelessWidget {
  const PantallaPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Imagen de usuario centrada
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(80),
                  child: Image.network(
                    'https://via.placeholder.com/150',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Lista de opciones
              Expanded(
                child: ListView(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Nombre'),
                    ),
                    Divider(),

                    ListTile(
                      leading: Icon(Icons.phone),
                      title: Text('Número'),
                    ),
                    Divider(),

                    ListTile(
                      leading: Icon(Icons.email),
                      title: Text('Correo'),
                    ),
                    Divider(),

                    ListTile(
                      leading: Icon(Icons.map),
                      title: Text('Ruta favorita'),
                    ),
                    Divider(),

                    ListTile(
                      leading: Icon(Icons.history),
                      title: Text('Historial'),
                    ),
                    Divider(),

                    ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Salir'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Barra inferior
      bottomNavigationBar: BottomAppBar(
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              IconButton(icon: Icon(Icons.home), onPressed: null),
              IconButton(icon: Icon(Icons.search), onPressed: null),
              IconButton(icon: Icon(Icons.notifications), onPressed: null),
              IconButton(icon: Icon(Icons.person), onPressed: null),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PantallaPerfil(),
  ));
}
import 'package:flutter/material.dart';void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi App',
      home: Scaffold(
        appBar: AppBar(
        ),
        body: Center(
          // La magia comienza aquí
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                                    Image.asset(
                        'assets/esoso.jpg',
                         height: 150,
                      ),
                      const SizedBox(height: 20),
                Text(
                  'Registro/Inicio de sesion',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 30),
                
                // Campo de Usuario
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej: Juan Perez',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 15),
                
                // Campo de colonia
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Municipio',
                     hintText: 'Ej: municipio',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 25),
                //campo gmail
                 TextField(
                  decoration: InputDecoration(
                    labelText: 'Gmail',
                    hintText: 'Ej: ejemplo@gmail.com',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 15),
                
                //contraseña
                 TextField(
                  decoration: InputDecoration(
                    labelText: 'contraseña',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 15),
                
                // Botón de acción
                ElevatedButton(
                  onPressed: () {
                    // poner funcion de saludo
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50), // Botón largo
                  ),
                  child: Text('Iniciar Sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
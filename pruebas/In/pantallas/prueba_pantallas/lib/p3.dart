import 'package:flutter/material.dart';

class PantallaVacia extends StatelessWidget {
  const PantallaVacia({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: const SafeArea(
        child: SizedBox.expand(), // ocupa toda la pantalla en blanco
      ),


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
    home: PantallaVacia(),
  ));
}
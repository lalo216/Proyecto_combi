import 'package:flutter/material.dart';

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
        body: Center(
          //contenedor principal
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Column(
                children: [
                  Container(
                    width: 400,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 162, 0, 255),
                    ),
                  ),
                  Text("Morado"),
                ],
              ),

              Column(
                children: [
                  Container(
                    width: 400,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 4, 188),
                    ),
                  ),
                  Text("Rosa"),
                ],
              ),

              Column(
                children: [
                  Container(
                    width: 400,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 251, 255, 0),
                    ),
                  ),
                  Text("Amarillo"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

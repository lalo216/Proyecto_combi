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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Container(
                width: 400,
                height: 100,
                decoration: BoxDecoration(color: Colors.green),
                child: Text("verde"),
              ),

              Container(
                width: 400,
                height: 100,
                decoration: BoxDecoration(color: Colors.blue),
                child: Text("azul"),
              ),

              Container(
                width: 400,
                height: 100,
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 255, 0, 157),
                ),
                child: Text("fucsia"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            children: <Widget>[
              Container(
                width: 150,
                height: 150,

                alignment: Alignment.topLeft,
                margin: EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.blue),
                child: Text("Eduardo"),
              ),

              Container(
                width: 20,
                height: 300,

                alignment: Alignment.bottomRight,
                margin: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red,
                  border: Border.all(color: Colors.yellow),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text("Beristain"),
              ),

              Container(
                width: 200,
                height: 200,

                alignment: Alignment.center,
                padding: EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text("Ortiz"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'db_test.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test MySQL via API',
      home: Scaffold(
        appBar: AppBar(title: const Text('Prueba de conexión MySQL')),
        body: const Center(child: ConnectionWidget()),
      ),
    );
  }
}

class ConnectionWidget extends StatelessWidget {
  const ConnectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: testConnection(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text("❌ Error: ${snapshot.error}");
        } else {
          return Text(
            snapshot.data ?? "Sin mensaje",
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          );
        }
      },
    );
  }
}

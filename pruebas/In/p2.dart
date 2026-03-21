import 'package:flutter/material.dart';

class PantallaNueva extends StatelessWidget {
  const PantallaNueva({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantalla'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              //  Widget 1
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      '¿A dónde va?',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Texto debajo del widget 1
              const Text(
                'Aquí puedes agregar una descripción o información relevante para el usuario.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 16),

              // Widgets 2, 3 y 4 en columna
              Expanded(
                child: ListView.separated(
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SizedBox(
                        height: 100,
                        child: Center(
                          child: Text('Widget ${index + 2}'),
                        ),
                      ),
                    );
                  },
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
    home: PantallaNueva(),
  ));
}
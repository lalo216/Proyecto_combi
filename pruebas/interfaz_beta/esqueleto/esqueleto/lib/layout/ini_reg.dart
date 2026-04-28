import 'package:flutter/material.dart';
import 'package:esqueleto/main.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true; // controla el switch

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Logo arriba
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Image.asset(
                  'assets/image1.png', // coloca tu logo aquí
                  height: 400,
                ),
              ),
            ),

            // Switch entre Login y Registro
            Container(
              width: 500,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isLogin = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isLogin ? Colors.blue : Colors.grey[300],
                        ),
                        child: const Center(
                          child: Text(
                            "Iniciar Sesión",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isLogin = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isLogin ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: const Center(
                          child: Text(
                            "Registrarse",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Contenido dinámico
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: isLogin ? _buildLoginForm() : _buildRegisterForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        TextField(decoration: const InputDecoration(labelText: "Usuario")),
        const SizedBox(height: 12),
        TextField(
          obscureText: true,
          decoration: const InputDecoration(labelText: "Contraseña"),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MainApp()),
            );
          },
          child: const Text("Iniciar Sesión"),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(decoration: const InputDecoration(labelText: "Usuario")),
          const SizedBox(height: 12),
          TextField(decoration: const InputDecoration(labelText: "Municipio")),
          const SizedBox(height: 12),
          TextField(decoration: const InputDecoration(labelText: "Correo")),
          const SizedBox(height: 12),
          TextField(
            obscureText: true,
            decoration: const InputDecoration(labelText: "Contraseña"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MainApp()),
              );
            },
            child: const Text("Registrarse"),
          ),
        ],
      ),
    );
  }
}

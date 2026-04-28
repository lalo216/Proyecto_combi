import 'package:flutter/material.dart';

class PerfilPage extends StatelessWidget {
  // Simulación de datos que vendrían de la BD
  final Map<String, dynamic> usuario = {
    "usuario": "lalo123",
    "municipio": "San Francisco Tetlanohcan",
    "correo": "lalo@example.com",
    "rol": "admin",
    "fecha_registro": "2026-04-27",
  };

  PerfilPage({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        height: 600,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow("Usuario", usuario["usuario"]),
                SizedBox(height: 20),
                const Divider(),
                SizedBox(height: 20),
                _buildInfoRow("Municipio", usuario["municipio"]),
                SizedBox(height: 20),
                const Divider(),
                SizedBox(height: 20),
                _buildInfoRow("Correo", usuario["correo"]),
                SizedBox(height: 20),
                const Divider(),
                SizedBox(height: 20),
                _buildInfoRow("Rol", usuario["rol"]),
                SizedBox(height: 20),
                const Divider(),
                SizedBox(height: 20),
                _buildInfoRow("Fecha de Registro", usuario["fecha_registro"]),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}

Widget _buildInfoRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../data/seed_data.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionCard(
          titulo: 'App',
          children: [
            _InfoRow(label: 'Nombre', valor: AppConfig.appName),
            _InfoRow(label: 'Versión', valor: AppConfig.appVersion),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          titulo: 'Datos',
          children: [
            _InfoRow(label: 'Rutas', valor: '${SeedData.rutas.length}'),
            _InfoRow(label: 'Paradas', valor: '${SeedData.paradas.length}'),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String titulo;
  final List<Widget> children;

  const _SectionCard({required this.titulo, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String valor;

  const _InfoRow({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

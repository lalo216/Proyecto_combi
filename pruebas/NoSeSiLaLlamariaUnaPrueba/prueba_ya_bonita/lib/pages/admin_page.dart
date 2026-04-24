// pages/admin_page.dart
// Panel de administración — visible solo si role == 'admin'.
// Muestra: estado del servidor, versión de schema, botón para sync manual.

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _api = ApiService();
  final _db = DatabaseHelper.instance;

  String _serverStatus = 'Verificando...';
  int? _schemaVersion;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final health = await _api.checkHealth();
      final version = await _db.getSchemaVersion();
      if (mounted) {
        setState(() {
          _serverStatus = health;
          _schemaVersion = version;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _serverStatus = 'offline');
    }
  }

  Future<void> _syncManual() async {
    setState(() => _syncing = true);
    try {
      final version = await _db.getSchemaVersion();
      final result = await _api.sync(version);
      if (result != null) {
        await _db.replaceAll(
          result.rutas,
          result.paradas,
          result.schemaVersion,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sincronización completada')),
          );
          await _loadStatus();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos ya al día')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Panel de administración'), centerTitle: false),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado del servidor
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estado del servidor', style: tt.titleSmall),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _serverStatus == 'ok'
                                ? Colors.green
                                : _serverStatus == 'degraded'
                                    ? Colors.orange
                                    : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _serverStatus,
                          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Versión de schema
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Versión de schema local', style: tt.titleSmall),
                    const SizedBox(height: 12),
                    Text(
                      _schemaVersion?.toString() ?? 'Cargando...',
                      style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón de sync manual
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _syncing ? null : _syncManual,
                icon: const Icon(Icons.sync),
                label: _syncing ? const Text('Sincronizando...') : const Text('Sincronizar ahora'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

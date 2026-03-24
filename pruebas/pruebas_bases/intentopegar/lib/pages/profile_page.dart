import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

/// Pantalla de Perfil — estado de conexión y stats de la BD.
///
/// Demuestra:
/// - Health check al servidor bajo demanda
/// - Conteo de datos en la BD local
/// - Botón de reseteo de BD (solo desarrollo)
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool? _servidorOnline;
  String _servidorMsg = 'No verificado';
  int _rutasLocales = 0;
  int _paradasLocales = 0;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarStats();
  }

  Future<void> _cargarStats() async {
    _rutasLocales = await CacheService.instance.contarRutas();
    _paradasLocales = await CacheService.instance.contarParadas();
    setState(() {});
  }

  Future<void> _checkServidor() async {
    setState(() {
      _cargando = true;
      _servidorOnline = null;
      _servidorMsg = 'Conectando...';
    });

    try {
      final api = ApiService();
      final info = await api.healthCheck();
      setState(() {
        _servidorOnline = true;
        _servidorMsg = 'Online — ${info['hostname'] ?? 'archymachine'}';
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _servidorOnline = false;
        _servidorMsg = e.toString().replaceAll('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _resetearBD() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Resetear BD local?'),
        content: const Text(
          'Se borrarán todos los datos locales y se re-sembrarán desde cero. '
          'Esto es solo para desarrollo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Resetear'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await CacheService.instance.resetearBD();
      await _cargarStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Info de la app.
        _SectionCard(
          titulo: 'App',
          children: [
            _InfoRow(label: 'Nombre', valor: AppConfig.appName),
            _InfoRow(label: 'Versión', valor: AppConfig.appVersion),
            _InfoRow(label: 'API URL', valor: AppConfig.apiBaseUrl),
          ],
        ),

        const SizedBox(height: 16),

        // BD local.
        _SectionCard(
          titulo: 'Base de datos local (SQLite)',
          children: [
            _InfoRow(label: 'Nombre', valor: AppConfig.localDbName),
            _InfoRow(label: 'Schema v', valor: '${AppConfig.localDbVersion}'),
            _InfoRow(label: 'Rutas', valor: '$_rutasLocales'),
            _InfoRow(label: 'Paradas', valor: '$_paradasLocales'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _resetearBD,
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: const Text('Resetear BD (dev)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade300,
                  side: BorderSide(color: Colors.red.shade300.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Servidor.
        _SectionCard(
          titulo: 'Servidor',
          children: [
            Row(
              children: [
                Icon(
                  _servidorOnline == true
                      ? Icons.cloud_done
                      : _servidorOnline == false
                          ? Icons.cloud_off
                          : Icons.cloud_queue,
                  color: _servidorOnline == true
                      ? Colors.green
                      : _servidorOnline == false
                          ? Colors.red
                          : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _servidorMsg,
                    style: TextStyle(
                      color: _servidorOnline == true
                          ? Colors.green
                          : _servidorOnline == false
                              ? Colors.red
                              : Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cargando ? null : _checkServidor,
                icon: _cargando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_find, size: 18),
                label: Text(_cargando ? 'Probando...' : 'Probar conexión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Card con título para agrupar info.
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

/// Fila label: valor.
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

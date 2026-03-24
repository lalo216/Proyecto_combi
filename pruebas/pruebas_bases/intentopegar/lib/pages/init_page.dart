import 'package:flutter/material.dart';
import '../services/cache_service.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

/// Pantalla de inicialización.
///
/// Flujo:
///   1. Siembra la BD local SQLite (o la lee si ya existe)
///   2. Prueba conexión al servidor "archymachine"
///   3. Muestra resultado: ✅ o ❌
///   4. Botón CONTINUAR siempre disponible después del siembro
///
/// El usuario pasa esta pantalla una vez y entra a la app principal.
class InitPage extends StatefulWidget {
  final VoidCallback onContinuar;

  const InitPage({super.key, required this.onContinuar});

  @override
  State<InitPage> createState() => _InitPageState();
}

class _InitPageState extends State<InitPage> {
  // Estados del proceso de init.
  bool _sembrandoBD = true;
  bool _bdLista = false;
  int _totalRutas = 0;
  int _totalParadas = 0;
  bool _fueRecienSembrada = false;

  bool _probandoServidor = false;
  bool? _servidorConectado; 
  String _mensajeServidor = '';
  Map<String, dynamic>? _infoServidor;

  String? _error;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    setState(() {
      _sembrandoBD = true;
      _error = null;
    });

    try {
      await CacheService.instance.database;
      _fueRecienSembrada = CacheService.instance.fueRecienSembrada;

      // Leer conteos.
      // _totalRutas = await CacheService.instance.contarRutas();
      // _totalParadas = await CacheService.instance.contarParadas();

      setState(() {
        _sembrandoBD = false;
        _bdLista = true;
      });
    } catch (e) {
      setState(() {
        _sembrandoBD = false;
        _bdLista = false;
        _error = 'Error al inicializar BD local: $e';
      });
      return; 
    }

    // Paso 2: Probar conexión al servidor.
    setState(() => _probandoServidor = true);

    try {
      final api = ApiService();
      final info = await api.healthCheck();

      setState(() {
        _probandoServidor = false;
        _servidorConectado = true;
        _infoServidor = info;
        _mensajeServidor = 'Conectado a ${info['hostname'] ?? 'archymachine'}';
      });
    } catch (e) {
      setState(() {
        _probandoServidor = false;
        _servidorConectado = false;
        _mensajeServidor = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo / Título.
              Text(
                '🚐',
                style: TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 12),
              Text(
                AppConfig.appName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'v${AppConfig.appVersion}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
              ),

              const Spacer(),

              // Estado de BD local.
              _StatusTile(
                icon: _sembrandoBD
                    ? Icons.hourglass_top
                    : _bdLista
                        ? Icons.check_circle
                        : Icons.error,
                iconColor: _sembrandoBD
                    ? Colors.orange
                    : _bdLista
                        ? Colors.green
                        : Colors.red,
                titulo: 'Base de datos local',
                subtitulo: _sembrandoBD
                    ? 'Sembrando datos iniciales...'
                    : _bdLista
                        ? _fueRecienSembrada
                            ? 'Se acaba de sembrar'
                            : 'Lista'
                        : 'Error',
                cargando: _sembrandoBD,
              ),

              const SizedBox(height: 16),

              // Estado de servidor.
              _StatusTile(
                icon: _probandoServidor
                    ? Icons.wifi_find
                    : _servidorConectado == true
                        ? Icons.cloud_done
                        : _servidorConectado == false
                            ? Icons.cloud_off
                            : Icons.cloud_queue,
                iconColor: _probandoServidor
                    ? Colors.orange
                    : _servidorConectado == true
                        ? Colors.green
                        : _servidorConectado == false
                            ? Colors.red
                            : Colors.grey,
                titulo: 'Servidor (archymachine)',
                subtitulo: _probandoServidor
                    ? 'Probando conexión...'
                    : _servidorConectado == null
                        ? 'Esperando BD local...'
                        : _mensajeServidor,
                cargando: _probandoServidor,
              ),

              // Info extra del servidor si está conectado.
              if (_infoServidor != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'IP: ${_infoServidor!['ip'] ?? '?'}\n'
                    'MySQL: ${_infoServidor!['mysql_status'] ?? '?'}\n'
                    'Timestamp: ${_infoServidor!['timestamp'] ?? '?'}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],

              // Error general.
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              if (_bdLista)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: widget.onContinuar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6D00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CONTINUAR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),

              // Botón de reintentar si la BD falló.
              if (!_bdLista && !_sembrandoBD)
                TextButton.icon(
                  onPressed: _iniciar,
                  icon: const Icon(Icons.refresh, color: Colors.orange),
                  label: const Text(
                    'Reintentar',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tile reutilizable para mostrar estado de un paso del init.
class _StatusTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String titulo;
  final String subtitulo;
  final bool cargando;

  const _StatusTile({
    required this.icon,
    required this.iconColor,
    required this.titulo,
    required this.subtitulo,
    this.cargando = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          if (cargando)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: iconColor,
              ),
            )
          else
            Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

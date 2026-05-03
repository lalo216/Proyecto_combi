import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_base.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import 'home_page.dart';

// Catálogo mínimo embebido — sólo (id, nombre, start/end) para que el
// listado de rutas se pinte antes del primer sync. IDs estables para que
// los favoritos sobrevivan a un reseed.
const List<Ruta> _kSeedRoutes = [
  Ruta(id: 1, nombre: 'Centro → Volcanes', startPoint: 'Centro', endPoint: 'Volcanes'),
  Ruta(id: 2, nombre: 'Escalinatas → Mercado', startPoint: 'Escalinatas', endPoint: 'Mercado'),
  Ruta(id: 3, nombre: 'Zócalo → Bienestar', startPoint: 'Zocalo', endPoint: 'Bienestar'),
];

class BootPage extends StatefulWidget {
  const BootPage({super.key});

  @override
  State<BootPage> createState() => _BootPageState();
}

class _BootPageState extends State<BootPage> {
  // Cada estado de boot se queda en pantalla este tiempo mínimo para que el
  // usuario alcance a leerlo. Útil mientras no tengamos un panel de logs.
  static const Duration _dwell = Duration(milliseconds: 1200);

  String _status = 'Iniciando...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _setStatus(String msg) async {
    if (!mounted) return;
    setState(() => _status = msg);
    await Future.delayed(_dwell);
  }

  Future<void> _boot() async {
    final appState = context.read<AppState>();
    final nav = Navigator.of(context);
    final api = ApiService();
    final auth = AuthService();

    debugPrint('boot: Loading seed routes (${_kSeedRoutes.length})');
    appState.setSeedRoutes(_kSeedRoutes);

    bool online = false;
    int? serverVersion;

    await _setStatus('Verificando conectividad...');
    try {
      final health = await api.check();
      online = health.ok;
      serverVersion = health.serverSchemaVersion;
      await _setStatus(online ? 'En línea.' : 'Sin respuesta — modo local.');
    } catch (e) {
      debugPrint('boot check error: $e');
      await _setStatus('Sin conexión — modo local.');
    }

    // Si el servidor publica un schema mayor al que conoce este APK, no hay
    // forma segura de interpretar su payload — entramos en solo-lectura
    // antes de tocar la red de nuevo.
    if (serverVersion != null && serverVersion > ApiBase.localdbversion) {
      appState.setReadOnlyMode(true);
      await _setStatus('Versión obsoleta — modo solo lectura.');
      online = false;
    }

    await _setStatus('Preparando base de datos...');
    try {
      await DatabaseHelper.instance.db;
      await appState.hydrateLastSyncAt();
    } catch (e) {
      debugPrint('boot db: $e');
    }

    await _setStatus('Restaurando sesión...');
    String? token;
    try {
      final session = await auth.restoreSession();
      if (session != null) {
        appState.setSession(
          userId: session.userId,
          email: session.email,
          nombre: session.nombre,
          token: session.token,
          municipio: session.municipio,
          role: session.role,
        );
        token = session.token;
      }
    } catch (e) {
      debugPrint('boot session: $e');
    }

    if (online && appState.needsSync) {
      // RAM solo tiene seed o el TTL expiró — pedir payload completo.
      await _setStatus('Sincronizando rutas...');
      try {
        final result = await api.sync(
          token: token,
          forceFullPayload: !appState.hasSyncedThisSession,
        );
        debugPrint('boot sync: upToDate=${result.upToDate}, count=${result.rutas.length}');
        if (result.rutas.isNotEmpty) {
          await appState.replaceRoutes(result.rutas);
          await _setStatus('Catálogo actualizado.');
        } else {
          await appState.stampSync();
          await _setStatus('Sin cambios en el catálogo.');
        }
      } on SchemaMismatchException {
        appState.setReadOnlyMode(true);
        await _setStatus('Versión obsoleta — modo solo lectura.');
      } on OfflineException {
        await _setStatus('Sin red — usando catálogo local.');
      } catch (e) {
        debugPrint('boot sync error: $e');
        await _setStatus('No se pudo sincronizar.');
      }
    } else if (!online) {
      await _setStatus('Sin conexión — modo local.');
    }

    if (!mounted) return;
    nav.pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/mascota/appicon.png',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                '¡CURO!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Para Tlaxcala, México',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 56),
              CircularProgressIndicator(
                color: scheme.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

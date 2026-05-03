import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';

/// Pill en la esquina inferior derecha que muestra el TTL restante.
/// Se actualiza cada ~30 segundos. Admins pueden tappear para forzar sync.
class SyncIndicator extends StatefulWidget {
  const SyncIndicator({super.key});

  @override
  State<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator> {
  Timer? _tick;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }



  Future<void> _forceSync() async {
    final appState = context.read<AppState>();
    setState(() => _syncing = true);
    try {
      final api = ApiService();
      await api.sync(
        token: appState.token,
        forceFullPayload: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo sincronizar.')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  String _formatRemaining(Duration? d) {
    if (d == null) return 'Expirado';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    if (m > 0) return '${m}m';
    return '<1m';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // No mostrar nada en modo solo-lectura
    if (appState.readOnlyMode) return const SizedBox.shrink();

    final remaining = appState.remainingtime;

    final isAdmin = appState.isAdmin;
    final cs = Theme.of(context).colorScheme;
    final color = isAdmin ? cs.primary : cs.outline;

    final label = _syncing
        ? 'Sincronizando...'
        : 'TTL: ${_formatRemaining(remaining)}';



    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      color: cs.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        // Admins siempre pueden; usuarios normales solo al expirar TTL
        onTap: !_syncing && (isAdmin || remaining == null) ? _forceSync : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
            color: color.withValues(alpha: 0.06),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_syncing)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: color),
                )
              else
                Icon(Icons.sync, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

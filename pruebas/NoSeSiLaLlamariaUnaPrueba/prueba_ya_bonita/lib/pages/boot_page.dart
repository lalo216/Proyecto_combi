// pages/boot_page.dart
// Primera pantalla, visible sólo durante el arranque inicial.
// Flujo:
//   1. Verifica schema_version local en SQLite
//   2. Intenta health check → sync con mechyserver
//   3. Si offline y BD vacía → siembra con SeedData como fallback
//   4. Navega a HomePage (reemplaza esta pantalla — no queda en el back-stack)

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/seed_data.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import 'home_page.dart';

class BootPage extends StatefulWidget {
  const BootPage({super.key});

  @override
  State<BootPage> createState() => _BootPageState();
}

class _BootPageState extends State<BootPage> {
  final _api = ApiService();
  final _db = DatabaseHelper.instance;

  String _status = 'Iniciando...';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    _setStatus('Verificando base de datos...');
    final currentVersion = await _db.getSchemaVersion();

    try {
      _setStatus('Conectando con el servidor...');
      final health = await _api.checkHealth();

      if (health == 'ok') {
        _setStatus('Sincronizando rutas...');
        final result = await _api.sync(currentVersion);
        if (result != null) {
          await _db.replaceAll(
            result.rutas,
            result.paradas,
            result.schemaVersion,
          );
          _setStatus('Rutas actualizadas desde el servidor.');
        } else {
          _setStatus('Datos al día.');
        }
      } else {
        _setStatus('Servidor degradado — usando datos locales.');
        if (currentVersion == 0) await SeedData.sembrar();
      }
    } on OfflineException {
      _setStatus('Sin conexión — usando datos locales.');
      if (currentVersion == 0) await SeedData.sembrar();
    } catch (e) {
      _setStatus('Error de red — usando datos locales.');
      if (currentVersion == 0) await SeedData.sembrar();
    }
    final auth = AuthService();
    final session = await auth.restoreSession();
    if (session != null && mounted) {
      context.read<AppState>().setUser(
        loggedIn: true,
        email: session['email'],
        role: session['role'],
        id: session['id'],
      );
      unawaited(context.read<AppState>().loadFavorites(_api, auth));
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  void _setStatus(String msg) {
    if (mounted) setState(() => _status = msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.directions_bus_filled,
                size: 80,
                color: Color(0xFFFF6D00),
              ),
              const SizedBox(height: 24),
              const Text(
                'Combis Chiautempan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tlaxcala, México',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 56),
              const CircularProgressIndicator(
                color: Color(0xFFFF6D00),
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _status,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
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

// pages/profile_page.dart
// Pantalla de perfil con dos vistas:
//   - Sin sesión: formulario de login / registro con toggle
//   - Con sesión: datos del usuario y botón de cerrar sesión

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import 'admin_page.dart';

enum _Modo { login, registro }

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  _Modo _modo = _Modo.login;
  bool _cargando = false;
  bool _ocultarPassword = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      if (_modo == _Modo.registro) {
        await _authService.register(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
        await _iniciarSesion();
      } else {
        await _iniciarSesion();
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _iniciarSesion() async {
    final datos = await _authService.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );
    if (mounted) {
      context.read<AppState>().setUser(
        loggedIn: true,
        email: datos['email'],
        role: datos['role'],
        id: datos['id'],
      );
    }
  }

  Future<void> _cerrarSesion() async {
    await _authService.logout();
    if (mounted) context.read<AppState>().clearUser();
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    return estado.isLoggedIn ? _buildPerfil(estado) : _buildFormAuth();
  }

  // --- Vista: usuario autenticado ---
  Widget _buildPerfil(AppState estado) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil'), centerTitle: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: cs.primaryContainer,
                child: Icon(
                  Icons.person,
                  size: 48,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                estado.userEmail ?? '',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Chip(
                label: Text(estado.userRole ?? 'usuario'),
                avatar: const Icon(Icons.verified_user_outlined, size: 16),
              ),
              const SizedBox(height: 48),
              if (estado.userRole == 'admin')
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminPage()),
                    ),
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Panel de administración'),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _cerrarSesion,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Vista: formulario de autenticación, se rifo el diseño la ia :/ ---
  Widget _buildFormAuth() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              children: [
                // Encabezado
                Icon(Icons.directions_bus_filled, size: 56, color: cs.primary),
                const SizedBox(height: 8),
                Text(
                  'Combis Chiautempan',
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Tlaxcala, México',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 36),

                // Toggle login / registro
                SegmentedButton<_Modo>(
                  segments: const [
                    ButtonSegment(
                      value: _Modo.login,
                      label: Text('Iniciar sesión'),
                      icon: Icon(Icons.login),
                    ),
                    ButtonSegment(
                      value: _Modo.registro,
                      label: Text('Registrarse'),
                      icon: Icon(Icons.person_add_outlined),
                    ),
                  ],
                  selected: {_modo},
                  onSelectionChanged: (seleccion) => setState(() {
                    _modo = seleccion.first;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 28),

                // Formulario
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Correo inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _ocultarPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _enviar(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultarPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            tooltip: _ocultarPassword ? 'Mostrar' : 'Ocultar',
                            onPressed: () =>
                                setState(() => _ocultarPassword = !_ocultarPassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          if (_modo == _Modo.registro && v.length < 8) {
                            return 'Mínimo 8 caracteres';
                          }
                          return null;
                        },
                      ),

                      // Mensaje de error
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.error_outline,
                                size: 16, color: cs.error),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                    color: cs.error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Botón principal
                      FilledButton(
                        onPressed: _cargando ? null : _enviar,
                        child: _cargando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _modo == _Modo.login
                                    ? 'Entrar'
                                    : 'Crear cuenta',
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

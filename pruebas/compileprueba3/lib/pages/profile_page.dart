import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import 'crearcuenta_page.dart';
import 'schema_check_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final AuthService _auth = AuthService();

  bool _busy = false;
  bool _ocultarPassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _auth.login(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      context.read<AppState>().setSession(
            userId: result.userId,
            email: result.email,
            nombre: result.nombre,
            token: result.token,
            municipio: result.municipio,
            role: result.role,
          );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    final appState = context.read<AppState>();
    await _auth.logout();
    if (!mounted) return;
    appState.clearSession();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return appState.isLoggedIn ? _buildProfile(appState) : _buildLogin();
  }

  Widget _buildLogin() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              children: [
              Image.asset(
              'assets/mascota/appicon.png',
              width: 140,
              height: 140,
              fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),
                Text(
                  'Curo',
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Tlaxcala, México',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 36),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
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
                        controller: _password,
                        obscureText: _ocultarPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultarPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            tooltip: _ocultarPassword ? 'Mostrar' : 'Ocultar',
                            onPressed: () => setState(
                              () => _ocultarPassword = !_ocultarPassword,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.error_outline, size: 16, color: cs.error),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _error!,
                                style: TextStyle(color: cs.error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busy ? null : _login,
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Entrar'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CrearCuentaPage(),
                          ),
                        ),
                        child: const Text('¿No tienes cuenta? Regístrate'),
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

  Widget _buildProfile(AppState appState) {
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
                appState.saludo,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              if (appState.userEmail != null) ...[
                const SizedBox(height: 4),
                Text(
                  appState.userEmail!,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 10),
              Chip(
                label: Text(appState.role ?? 'usuario'),
                avatar: const Icon(Icons.verified_user_outlined, size: 16),
              ),
              if (appState.isAdmin) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SchemaCheckPage()),
                  ),
                  icon: const Icon(Icons.storage_rounded),
                  label: const Text('Verificar Esquema'),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.tertiary,
                    foregroundColor: cs.onTertiary,
                  ),
                ),
              ],
              const SizedBox(height: 48),
              OutlinedButton.icon(
                onPressed: _logout,
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
}

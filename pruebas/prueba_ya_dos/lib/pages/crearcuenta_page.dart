// pages/crearcuenta_page.dart
// Formulario de registro: Nombre completo → Municipio → Correo → Contraseña.
// Después del POST /registrar.php, hace login automático para poblar AppState.
// La lista de municipios DEBE coincidir con el whitelist del servidor
// (registrar.php valida contra este mismo conjunto).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';

class CrearCuentaPage extends StatefulWidget {
  const CrearCuentaPage({super.key});

  @override
  State<CrearCuentaPage> createState() => _CrearCuentaPageState();
}

class _CrearCuentaPageState extends State<CrearCuentaPage> {
  static const List<String> _municipios = [
    'Chiautempan',
    'Apizaco',
    'Tlaxcala',
    'Santa Ana',
    'Contla',
  ];

  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _municipio;

  bool _cargando = false;
  bool _ocultarPassword = true;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_municipio == null) {
      setState(() => _error = 'Selecciona un municipio');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await _authService.register(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
        _nombreCtrl.text.trim(),
        _municipio!,
      );
      // Auto-login para que AppState quede poblado con nombre/municipio.
      final datos = await _authService.login(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (!mounted) return;
      context.read<AppState>().setUser(
        loggedIn: true,
        email: datos['email'],
        role: datos['role'],
        id: datos['id'],
        nombreCompleto: datos['nombre_completo'],
        municipio: datos['municipio'],
      );
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta'), centerTitle: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.person_add_alt_1, size: 48, color: cs.primary),
                const SizedBox(height: 8),
                Text(
                  'Únete a Combis Chiautempan',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                TextFormField(
                  controller: _nombreCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Requerido';
                    if (s.length < 2) return 'Nombre demasiado corto';
                    if (s.length > 100) return 'Nombre demasiado largo';
                    // Solo letras unicode y espacios — coincide con validación servidor.
                    if (!RegExp(r"^[\p{L} .'-]+$", unicode: true).hasMatch(s)) {
                      return 'Solo letras y espacios';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _municipio,
                  decoration: const InputDecoration(
                    labelText: 'Municipio',
                    prefixIcon: Icon(Icons.location_city_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _municipios
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _municipio = v),
                  validator: (v) => v == null ? 'Selecciona un municipio' : null,
                ),
                const SizedBox(height: 16),

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
                      onPressed: () =>
                          setState(() => _ocultarPassword = !_ocultarPassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (v.length < 8) return 'Mínimo 8 caracteres';
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
                const SizedBox(height: 24),

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
                      : const Text('Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

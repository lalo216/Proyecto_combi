import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../util/error_reporter.dart';

const List<String> kMunicipios = [
  'Chiautempan',
  'Tlaxcala',
  'Apizaco',
  'Santa Cruz Tlaxcala',
];

class CrearCuentaPage extends StatefulWidget {
  const CrearCuentaPage({super.key});

  @override
  State<CrearCuentaPage> createState() => _CrearCuentaPageState();
}

class _CrearCuentaPageState extends State<CrearCuentaPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nombre = TextEditingController();
  String _municipio = kMunicipios.first;
  bool _busy = false;

  final AuthService _auth = AuthService();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final result = await _auth.register(
        email: _email.text.trim(),
        password: _password.text,
        nombreCompleto: _nombre.text.trim(),
        municipio: _municipio,
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
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) reportError(context, e, hint: 'register');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email inválido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _municipio,
                  decoration: const InputDecoration(labelText: 'Municipio'),
                  items: kMunicipios
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _municipio = v!),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
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

import 'package:flutter/material.dart';

class CreditosPage extends StatelessWidget {
  const CreditosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créditos'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _TeamMemberTile('Lalo', cs, tt),
                _TeamMemberTile('Gael', cs, tt),
                _TeamMemberTile('Adriana', cs, tt),
                _TeamMemberTile('Martin', cs, tt),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _TeamMemberTile(String name, ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 20, color: cs.primary),
          const SizedBox(width: 12),
          Text(
            name,
            style: tt.bodyMedium,
          ),
        ],
      ),
    );
  }
}

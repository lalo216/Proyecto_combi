import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../external/lalo/mapa_ruta_page.dart';
import '../state/app_state.dart';

class SearchSurface extends StatefulWidget {
  final Widget body;
  const SearchSurface({super.key, required this.body});

  @override
  State<SearchSurface> createState() => _SearchSurfaceState();
}

class _SearchSurfaceState extends State<SearchSurface> {
  final _ctrlBusca = TextEditingController();
  final  _focus = FocusNode();
  bool _active = false;
  int? _expandedId;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus && !_active) {
        setState(() => _active = true);
      }
    });
  }

  @override
  void dispose() {
    _ctrlBusca.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _close() {
    _focus.unfocus();
    setState(() {
      _active = false;
      _ctrlBusca.clear();
      _expandedId = null;
    });
  }

  void _onResultTap(AppState appState, Ruta r) {
    appState.logQuery(_ctrlBusca.text);
    appState.logRouteOpened(r.id);
    setState(() => _expandedId = _expandedId == r.id ? null : r.id);
  }

  void _verEnMapa(int rutaId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MapaRutaPage(rutaId: rutaId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final results = _active ? appState.search(_ctrlBusca.text) : const <Ruta>[];

    return Stack(
      children: [
        Positioned.fill(child: widget.body),
        if (_active)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: const ColoredBox(color: Color(0x80000000)),
            ),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  elevation: _active ? 6 : 2,
                  borderRadius: BorderRadius.circular(28),
                  color: Theme.of(context).colorScheme.surface,
                  child: TextField(
                    controller: _ctrlBusca,
                    focusNode: _focus,
                    onChanged: (_) => setState(() => _expandedId = null),
                    decoration: InputDecoration(
                      hintText: 'Buscar ruta',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _active
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _close,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                if (_active)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(16),
                        color: Theme.of(context).colorScheme.surface,
                        child: results.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('Sin resultados'),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: results.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (ctx, i) {
                                  final r = results[i];
                                  final expanded = _expandedId == r.id;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ListTile(
                                        leading: _RutaShade(id: r.id),
                                        title: Text(r.nombre),
                                        trailing: Icon(
                                          expanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                        ),
                                        onTap: () => _onResultTap(appState, r),
                                      ),
                                      if (expanded)
                                        _OverviewCard(
                                          ruta: r,
                                          onVerEnMapa: () => _verEnMapa(r.id),
                                        ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RutaShade extends StatelessWidget {
  final int id;
  const _RutaShade({required this.id});

  @override
  Widget build(BuildContext context) {
    final shade = (id * 53) % 100;
    final v = (40 + (shade * 1.5)).clamp(40, 200).toInt();
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Color.fromARGB(255, v, v, v),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final Ruta ruta;
  final VoidCallback onVerEnMapa;
  const _OverviewCard({required this.ruta, required this.onVerEnMapa});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final isFav = appState.isLoggedIn && appState.isFavorito(ruta.id);

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                ruta.estimatedTime > 0
                    ? '${ruta.estimatedTime} min'
                    : 'Tiempo por definir',
                style: theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              if (appState.isLoggedIn)
                IconButton(
                  icon: Icon(isFav ? Icons.star : Icons.star_border),
                  color: isFav
                      ? Colors.amber.shade700
                      : theme.colorScheme.onSurfaceVariant,
                  tooltip: isFav ? 'Quitar de favoritos' : 'Agregar a favoritos',
                  onPressed: () => appState.toggleFavorito(ruta.id),
                ),
            ],
          ),
          if (ruta.horario.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Horario: ${ruta.horario}'),
            ),
          if (ruta.startPoint != null || ruta.endPoint != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Recorrido: ${ruta.startPoint ?? '—'} → ${ruta.endPoint ?? '—'}',
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onVerEnMapa,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Ver en mapa'),
          ),
        ],
      ),
    );
  }
}

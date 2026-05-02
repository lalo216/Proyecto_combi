import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../external/lalo/mapa_ruta_page.dart';
import '../state/app_state.dart';
import '../widgets/search_overlay.dart';
import 'mapa_usuario_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          _HomeBody(),
          MapaUsuarioPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Mapas'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return SearchSurface(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _FavoritosBlock(),
              SizedBox(height: 24),
              _RecientesBlock(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoritosBlock extends StatelessWidget {
  const _FavoritosBlock();

  @override
  Widget build(BuildContext context) {
    return Selector<AppState, bool>(
      selector: (_, s) => s.isLoggedIn,
      builder: (ctx, loggedIn, _) {
        if (!loggedIn) {
          return const _EmptyBlock(
            label: 'Favoritos',
            hint: 'Inicia sesión para guardar favoritos',
          );
        }
        return _RouteBlock(
          label: 'Favoritos',
          futureIds: ctx.read<AppState>().getFavoritos(),
        );
      },
    );
  }
}

class _RecientesBlock extends StatelessWidget {
  const _RecientesBlock();

  @override
  Widget build(BuildContext context) {
    return Selector<AppState, bool>(
      selector: (_, s) => s.isLoggedIn,
      builder: (ctx, loggedIn, _) {
        if (!loggedIn) {
          return const _EmptyBlock(
            label: 'Recientes',
            hint: 'Inicia sesión para ver tus rutas recientes',
          );
        }
        return _RouteBlock(
          label: 'Recientes',
          futureIds: ctx.read<AppState>().recentRouteIds(),
        );
      },
    );
  }
}

class _RouteBlock extends StatelessWidget {
  final String label;
  final Future<List<int>> futureIds;
  const _RouteBlock({required this.label, required this.futureIds});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FutureBuilder<List<int>>(
          future: futureIds,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            }
            final ids = snap.data ?? const [];
            if (ids.isEmpty) {
              return Text(
                'Ninguna todavía',
                style: Theme.of(ctx).textTheme.bodySmall,
              );
            }
            final appState = ctx.read<AppState>();
            return Column(
              children: [
                for (final id in ids)
                  Builder(builder: (ctx) {
                    final r = appState.routeById(id);
                    if (r == null) return const SizedBox.shrink();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(r.nombre),
                      dense: true,
                      onTap: () {
                        appState.logRouteOpened(r.id);
                        Navigator.of(ctx).push(
                          MaterialPageRoute(
                            builder: (_) => MapaRutaPage(rutaId: r.id),
                          ),
                        );
                      },
                    );
                  }),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  final String label;
  final String hint;
  const _EmptyBlock({required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(hint, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

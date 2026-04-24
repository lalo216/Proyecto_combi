import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home_page.dart';
import 'pages/routes_page.dart';
import 'pages/profile_page.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? true;
  runApp(CombisApp(initialDark: isDark));
}

class CombisApp extends StatefulWidget {
  final bool initialDark;
  const CombisApp({super.key, required this.initialDark});

  @override
  State<CombisApp> createState() => _CombisAppState();
}

class _CombisAppState extends State<CombisApp> {
  late bool _dark;

  @override
  void initState() {
    super.initState();
    _dark = widget.initialDark;
  }

  Future<void> _toggleTheme() async {
    setState(() => _dark = !_dark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6D00)),
        appBarTheme: const AppBarTheme(elevation: 0),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6D00),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Color(0xFFFF6D00),
          unselectedItemColor: Colors.white54,
        ),
      ),
      home: _MainNavigation(onToggleTheme: _toggleTheme, isDark: _dark),
    );
  }
}

class _MainNavigation extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const _MainNavigation({required this.onToggleTheme, required this.isDark});

  @override
  State<_MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<_MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    RoutesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${AppConfig.appName} v${AppConfig.appVersion}'),
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
            tooltip: widget.isDark ? 'Modo claro' : 'Modo oscuro',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus_outlined),
            activeIcon: Icon(Icons.directions_bus),
            label: 'Rutas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

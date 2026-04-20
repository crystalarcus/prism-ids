import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/prism_provider.dart';
import 'screens/nids_screen.dart';
import 'screens/hids_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PrismProvider()..connect(),
      child: const PrismApp(),
    ),
  );
}

class PrismApp extends StatelessWidget {
  const PrismApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<PrismProvider>().themeMode;
    final colors = Theme.of(context).colorScheme; // Access colorScheme here

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
        surface: const Color(0xFF1C1B1F),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.onSurfaceVariant.withValues(alpha: 0.1)),
        ),
        color: colors.surface.withValues(alpha: 0.02),
      ),
    );

    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.onSurfaceVariant.withValues(alpha: 0.05)),
        ),
        color: colors.surface,
      ),
    );

    return MaterialApp(
      title: 'Prism IDS',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: const MainNavigationScreen(),
    );
  }
  }
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const NidsScreen(),
    const HidsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: isWide ? null : AppBar(title: const Text('Prism IDS')),
      drawer: isWide
          ? null
          : Drawer(
              child: ListView(
                children: [
                  const DrawerHeader(child: Center(child: Text('PRISM IDS'))),
                  ...List.generate(
                    _screens.length,
                    (index) => ListTile(
                      selected: _selectedIndex == index,
                      leading: Icon(
                        [Icons.lan, Icons.terminal, Icons.settings][index],
                      ),
                      title: Text(['NIDS', 'HIDS', 'Settings'][index]),
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) =>
                  setState(() => _selectedIndex = index),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.security, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'PRISM',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.lan),
                  label: Text('NIDS'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.terminal),
                  label: Text('HIDS'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _screens),
          ),
        ],
      ),
    );
  }
}

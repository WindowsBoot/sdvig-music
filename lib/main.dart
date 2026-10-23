import 'package:flutter/material.dart';
import 'screens/library_page.dart';
import 'screens/search_page.dart';
import 'screens/settings_page.dart';
import 'state/player.dart';
import 'state/settings.dart';
import 'theme/app_theme.dart';
import 'widgets/mini_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await settings.load();
  await player.load();
  runApp(const SdvigApp());
}

class SdvigApp extends StatelessWidget {
  const SdvigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'SDVIG',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(settings),
        home: const Shell(),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;

  static const List<Widget> _pages = [
    SearchPage(),
    LibraryPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 800;
    final content = Column(
      children: [
        Expanded(child: IndexedStack(index: _i, children: _pages)),
        const MiniPlayer(),
      ],
    );

    if (wide) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: _i,
                onDestinationSelected: (v) => setState(() => _i = v),
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.search),
                    label: Text('Поиск'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.library_music),
                    label: Text('Библиотека'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.tune),
                    label: Text('Настройки'),
                  ),
                ],
              ),
              VerticalDivider(
                width: 1,
                color: Theme.of(context).dividerColor,
              ),
              Expanded(child: content),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(bottom: false, child: content),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Поиск'),
          NavigationDestination(
            icon: Icon(Icons.library_music),
            label: 'Библиотека',
          ),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Настройки'),
        ],
      ),
    );
  }
}

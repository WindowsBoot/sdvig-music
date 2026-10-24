import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'screens/home_page.dart';
import 'screens/library_page.dart';
import 'screens/search_page.dart';
import 'screens/settings_page.dart';
import 'state/app_bus.dart';
import 'state/player.dart';
import 'state/settings.dart';
import 'theme/app_theme.dart';
import 'widgets/mini_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  mk.MediaKit.ensureInitialized();
  await settings.load();
  await player.init();
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
        scaffoldMessengerKey: messengerKey,
        theme: buildTheme(settings),
        home: const Root(),
      ),
    );
  }
}

/// Корень приложения: интерфейс + анимированная заставка с логотипом.
class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  bool _ready = false;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: Shell()),
        if (!_gone)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _ready,
              child: AnimatedOpacity(
                opacity: _ready ? 0 : 1,
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOut,
                onEnd: () {
                  if (_ready && mounted) setState(() => _gone = true);
                },
                child: const _Splash(),
              ),
            ),
          ),
      ],
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (context, v, child) => Opacity(
            opacity: v,
            child: Transform.scale(scale: 0.85 + 0.15 * v, child: child),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Image.asset('assets/logo.png'),
            ),
          ),
        ),
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
    HomePage(),
    SearchPage(),
    LibraryPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    searchRequest.addListener(_onSearch);
    tabRequest.addListener(_onTab);
  }

  @override
  void dispose() {
    searchRequest.removeListener(_onSearch);
    tabRequest.removeListener(_onTab);
    super.dispose();
  }

  void _onSearch() {
    if (searchRequest.value != null) setState(() => _i = 1);
  }

  void _onTab() {
    final t = tabRequest.value;
    if (t == null) return;
    tabRequest.value = null;
    setState(() => _i = t);
  }

  Widget _stack() {
    return Stack(
      children: [
        for (var i = 0; i < _pages.length; i++)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: i != _i,
              child: TickerMode(
                enabled: i == _i,
                child: AnimatedOpacity(
                  opacity: i == _i ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: _pages[i],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 800;
    final content = Column(
      children: [
        Expanded(child: _stack()),
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
                    icon: Icon(Icons.home_rounded),
                    label: Text('Главная'),
                  ),
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
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Главная'),
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

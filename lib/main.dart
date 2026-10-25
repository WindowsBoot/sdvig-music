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
import 'widgets/common.dart';
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

class _ShellState extends State<Shell> with SingleTickerProviderStateMixin {
  int _i = 0;

  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
    value: 1,
  );

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
    _fade.dispose();
    super.dispose();
  }

  void _go(int i) {
    if (i == _i) return;
    setState(() => _i = i);
    _fade.forward(from: 0);
  }

  void _onSearch() {
    if (searchRequest.value != null) _go(1);
  }

  void _onTab() {
    final t = tabRequest.value;
    if (t == null) return;
    tabRequest.value = null;
    _go(t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: AnimatedBuilder(
                    animation: _fade,
                    builder: (context, child) {
                      final v = Curves.easeOutCubic.transform(_fade.value);
                      return Opacity(
                        opacity: v,
                        child: Transform.translate(
                          offset: Offset(0, 14 * (1 - v)),
                          child: child,
                        ),
                      );
                    },
                    child: IndexedStack(index: _i, children: _pages),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MiniPlayer(),
                        FloatNav(index: _i, onTap: _go),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../state/settings.dart';

ThemeData buildTheme(SettingsController s) {
  final dark = s.dark;
  final bg = dark ? Colors.black : Colors.white;
  final fg = dark ? Colors.white : Colors.black;
  final mid = dark ? const Color(0xFF7A7A7A) : const Color(0xFF8A8A8A);
  final accent = Color.lerp(mid, fg, s.accent)!;
  final panel = dark ? const Color(0xFF121212) : const Color(0xFFF1F1F1);

  final scheme = ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: accent,
    onPrimary: bg,
    secondary: accent,
    onSecondary: bg,
    error: accent,
    onError: bg,
    surface: bg,
    onSurface: fg,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    dividerColor: fg.withAlpha(30),
    sliderTheme: SliderThemeData(
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: SliderComponentShape.noOverlay,
      activeTrackColor: accent,
      inactiveTrackColor: fg.withAlpha(40),
      thumbColor: accent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: bg,
      indicatorColor: panel,
      height: 64,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: bg,
      indicatorColor: panel,
    ),
  );
}

Color panelColor(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return dark ? const Color(0xFF121212) : const Color(0xFFF1F1F1);
}

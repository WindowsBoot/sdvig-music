import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

void toast(String m) {
  final s = messengerKey.currentState;
  if (s == null) return;
  s.hideCurrentSnackBar();
  s.showSnackBar(SnackBar(
    content: Text(m),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 2),
  ));
}

/// Запрос на поиск из других экранов (например, "другие треки исполнителя").
final ValueNotifier<String?> searchRequest = ValueNotifier<String?>(null);

/// Запрос на переключение вкладки.
final ValueNotifier<int?> tabRequest = ValueNotifier<int?>(null);

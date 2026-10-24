import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  bool dark = true;
  double radius = 18;
  double accent = 1.0;
  double speed = 1.0;
  List<double> eq = [0, 0, 0, 0, 0];
  Set<String> disabledSources = {};
  List<String> recentQueries = [];

  SharedPreferences? _p;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final p = _p!;
    dark = p.getBool('dark') ?? true;
    radius = p.getDouble('radius') ?? 18;
    accent = p.getDouble('accent') ?? 1.0;
    speed = p.getDouble('speed') ?? 1.0;
    final e = p.getStringList('eq');
    if (e != null && e.length == 5) {
      eq = e.map((x) => double.tryParse(x) ?? 0.0).toList();
    }
    disabledSources = (p.getStringList('off') ?? <String>[]).toSet();
    recentQueries = p.getStringList('queries') ?? <String>[];
  }

  void _save() {
    final p = _p;
    if (p == null) return;
    p.setBool('dark', dark);
    p.setDouble('radius', radius);
    p.setDouble('accent', accent);
    p.setDouble('speed', speed);
    p.setStringList('eq', eq.map((x) => x.toString()).toList());
    p.setStringList('off', disabledSources.toList());
  }

  void setDark(bool v) {
    dark = v;
    _save();
    notifyListeners();
  }

  void setRadius(double v) {
    radius = v;
    _save();
    notifyListeners();
  }

  void setAccent(double v) {
    accent = v;
    _save();
    notifyListeners();
  }

  void setSpeed(double v) {
    speed = v;
    _save();
    notifyListeners();
  }

  void setEqBand(int i, double v) {
    eq = List<double>.from(eq)..[i] = v;
    _save();
    notifyListeners();
  }

  void setEq(List<double> v) {
    eq = List<double>.from(v);
    _save();
    notifyListeners();
  }

  void toggleSource(String name) {
    if (!disabledSources.remove(name)) disabledSources.add(name);
    _save();
    notifyListeners();
  }

  /// История запросов: без notifyListeners, чтобы не перерисовывать всё приложение.
  void addQuery(String q) {
    final s = q.trim();
    if (s.isEmpty) return;
    recentQueries = [s, ...recentQueries.where((x) => x != s)].take(8).toList();
    _p?.setStringList('queries', recentQueries);
  }

  void clearQueries() {
    recentQueries = [];
    _p?.setStringList('queries', recentQueries);
  }
}

final SettingsController settings = SettingsController();

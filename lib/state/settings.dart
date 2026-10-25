import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Режим звука: скорость, тон и фильтр mpv/ffmpeg.
class SoundMode {
  const SoundMode(this.id, this.label, this.rate, this.keepPitch, this.filter);

  final String id;
  final String label;
  final double? rate;
  final bool keepPitch;
  final String filter;
}

const List<SoundMode> kModes = [
  SoundMode('normal', 'Обычный', null, true, ''),
  SoundMode('slowed', 'Slowed + Reverb', 0.86, false,
      'aecho=0.8:0.9:45|80|120:0.4|0.3|0.2'),
  SoundMode('nightcore', 'Nightcore', 1.22, false, ''),
  SoundMode('8d', '8D', null, true, 'apulsator=mode=sine:hz=0.12:amount=1'),
  SoundMode('bass', 'Bass boost', null, true, 'bass=g=9:f=110'),
];

SoundMode modeById(String id) =>
    kModes.firstWhere((m) => m.id == id, orElse: () => kModes.first);

class SettingsController extends ChangeNotifier {
  bool dark = true;
  double radius = 18;
  double accent = 1.0;
  double speed = 1.0;
  String mode = 'normal';
  bool vinyl = false;
  bool autoRadio = true;
  String spotifyId = '';
  String spotifySecret = '';
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
    mode = p.getString('mode') ?? 'normal';
    vinyl = p.getBool('vinyl') ?? false;
    autoRadio = p.getBool('radio') ?? true;
    spotifyId = p.getString('sp_id') ?? '';
    spotifySecret = p.getString('sp_secret') ?? '';
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
    p.setString('mode', mode);
    p.setBool('vinyl', vinyl);
    p.setBool('radio', autoRadio);
    p.setString('sp_id', spotifyId);
    p.setString('sp_secret', spotifySecret);
    p.setStringList('eq', eq.map((x) => x.toString()).toList());
    p.setStringList('off', disabledSources.toList());
  }

  void _commit() {
    _save();
    notifyListeners();
  }

  void setDark(bool v) {
    dark = v;
    _commit();
  }

  void setRadius(double v) {
    radius = v;
    _commit();
  }

  void setAccent(double v) {
    accent = v;
    _commit();
  }

  void setSpeed(double v) {
    speed = v;
    _commit();
  }

  void setMode(String v) {
    mode = v;
    _commit();
  }

  void setVinyl(bool v) {
    vinyl = v;
    _commit();
  }

  void setAutoRadio(bool v) {
    autoRadio = v;
    _commit();
  }

  void setSpotify(String id, String secret) {
    spotifyId = id.trim();
    spotifySecret = secret.trim();
    _commit();
  }

  void setEqBand(int i, double v) {
    eq = List<double>.from(eq)..[i] = v;
    _commit();
  }

  void setEq(List<double> v) {
    eq = List<double>.from(v);
    _commit();
  }

  void toggleSource(String name) {
    if (!disabledSources.remove(name)) disabledSources.add(name);
    _commit();
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

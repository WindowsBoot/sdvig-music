import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';

/// Контроллер плеера. Сейчас воспроизведение имитируется таймером,
/// в части 2 сюда подключится реальный аудио-движок.
class PlayerController extends ChangeNotifier {
  PlayerController() {
    Timer.periodic(const Duration(milliseconds: 500), (_) => _tick());
  }

  final Random _rnd = Random();
  SharedPreferences? _p;

  Track? current;
  bool playing = false;
  bool shuffle = false;
  bool repeat = false;
  double position = 0;
  List<Track> queue = [];
  final Map<String, List<Track>> playlists = {'Избранное': <Track>[]};

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final raw = _p!.getString('playlists');
    if (raw != null) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        final loaded = <String, List<Track>>{};
        m.forEach((k, v) {
          loaded[k] = (v as List)
              .map((e) => Track.fromJson(e as Map<String, dynamic>))
              .toList();
        });
        playlists
          ..clear()
          ..addAll(loaded);
      } catch (_) {}
    }
    playlists.putIfAbsent('Избранное', () => <Track>[]);
  }

  void _save() {
    final data = playlists.map(
      (k, v) => MapEntry(k, v.map((t) => t.toJson()).toList()),
    );
    _p?.setString('playlists', jsonEncode(data));
  }

  void _tick() {
    final t = current;
    if (!playing || t == null) return;
    position += 0.5;
    if (position >= t.durationSec) {
      if (repeat) {
        position = 0;
      } else {
        next();
        return;
      }
    }
    notifyListeners();
  }

  void play(Track t, {List<Track>? inQueue}) {
    if (inQueue != null) queue = List<Track>.from(inQueue);
    current = t;
    position = 0;
    playing = true;
    notifyListeners();
  }

  void toggle() {
    if (current == null) return;
    playing = !playing;
    notifyListeners();
  }

  void seek(double s) {
    position = s;
    notifyListeners();
  }

  void next() {
    if (queue.isEmpty || current == null) return;
    var i = queue.indexWhere((t) => t.id == current!.id);
    if (shuffle && queue.length > 1) {
      int j;
      do {
        j = _rnd.nextInt(queue.length);
      } while (j == i);
      i = j;
    } else {
      i = (i + 1) % queue.length;
    }
    play(queue[i]);
  }

  void prev() {
    if (queue.isEmpty || current == null) return;
    if (position > 3) {
      seek(0);
      return;
    }
    var i = queue.indexWhere((t) => t.id == current!.id);
    i = (i - 1) < 0 ? queue.length - 1 : i - 1;
    play(queue[i]);
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    repeat = !repeat;
    notifyListeners();
  }

  void createPlaylist(String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    playlists.putIfAbsent(n, () => <Track>[]);
    _save();
    notifyListeners();
  }

  void deletePlaylist(String name) {
    if (name == 'Избранное') return;
    playlists.remove(name);
    _save();
    notifyListeners();
  }

  void addToPlaylist(String name, Track t) {
    final list = playlists.putIfAbsent(name, () => <Track>[]);
    if (!list.any((x) => x.id == t.id)) list.add(t);
    _save();
    notifyListeners();
  }

  void removeFromPlaylist(String name, Track t) {
    playlists[name]?.removeWhere((x) => x.id == t.id);
    _save();
    notifyListeners();
  }
}

final PlayerController player = PlayerController();

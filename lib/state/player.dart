import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import '../providers/music_provider.dart';
import 'app_bus.dart';
import 'settings.dart';

const String kFav = 'Избранное';

enum SdvigRepeat { off, all, one }

/// Плеер: реальное воспроизведение через media_kit (libmpv).
class PlayerController extends ChangeNotifier {
  final mk.Player _p = mk.Player();
  final Random _rnd = Random();
  SharedPreferences? _prefs;

  Track? current;
  List<Track> queue = [];
  int index = -1;
  bool playing = false;
  bool buffering = false;
  bool loading = false;
  Duration duration = Duration.zero;
  final ValueNotifier<Duration> pos = ValueNotifier<Duration>(Duration.zero);
  bool shuffle = false;
  SdvigRepeat repeat = SdvigRepeat.off;
  List<Track> recent = [];
  final Map<String, List<Track>> playlists = {kFav: <Track>[]};

  int _gen = 0;
  String _lastAf = '#';
  double _lastRate = -1;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadLists();
    _p.stream.playing.listen((v) {
      playing = v;
      notifyListeners();
    });
    _p.stream.buffering.listen((v) {
      buffering = v;
      notifyListeners();
    });
    _p.stream.duration.listen((v) {
      if (v > Duration.zero) {
        duration = v;
        notifyListeners();
      }
    });
    _p.stream.position.listen((v) {
      pos.value = v;
    });
    _p.stream.completed.listen((v) {
      if (v) _onCompleted();
    });
    _p.stream.error.listen((e) {
      loading = false;
      toast('Ошибка воспроизведения');
      notifyListeners();
    });
    settings.addListener(() {
      _applyAudio();
    });
  }

  // ---------- хранение ----------

  void _loadLists() {
    final p = _prefs!;
    try {
      final raw = p.getString('playlists');
      if (raw != null) {
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
      }
      final rr = p.getString('recent');
      if (rr != null) {
        recent = (jsonDecode(rr) as List)
            .map((e) => Track.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    playlists.putIfAbsent(kFav, () => <Track>[]);
  }

  void _savePlaylists() {
    final data = playlists.map(
      (k, v) => MapEntry(k, v.map((t) => t.toJson()).toList()),
    );
    _prefs?.setString('playlists', jsonEncode(data));
  }

  void _pushRecent(Track t) {
    recent = [t, ...recent.where((x) => x.id != t.id)].take(50).toList();
    _prefs?.setString(
      'recent',
      jsonEncode(recent.map((e) => e.toJson()).toList()),
    );
  }

  // ---------- воспроизведение ----------

  Future<void> _start(int i) async {
    if (i < 0 || i >= queue.length) return;
    final t = queue[i];
    final gen = ++_gen;
    index = i;
    current = t;
    loading = true;
    duration = Duration(seconds: t.durationSec);
    pos.value = Duration.zero;
    notifyListeners();
    try {
      final url = t.url ?? await ProviderRegistry.of(t.source).streamUrl(t);
      if (gen != _gen) return;
      await _p.open(mk.Media(url), play: true);
      await _applyAudio(force: true);
      _pushRecent(t);
    } catch (e) {
      if (gen == _gen) toast('Не удалось запустить: ${t.title}');
    } finally {
      if (gen == _gen) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void playFrom(List<Track> list, Track t) {
    queue = List<Track>.from(list);
    var i = queue.indexWhere((x) => x.id == t.id);
    if (i < 0) {
      queue = [t];
      i = 0;
    }
    _start(i);
  }

  void jumpTo(int i) => _start(i);

  void toggle() {
    if (current == null) return;
    _p.playOrPause();
  }

  void seek(Duration d) {
    _p.seek(d);
    pos.value = d;
  }

  void next() {
    if (queue.isEmpty) return;
    _start(_nextIndex(false));
  }

  int _nextIndex(bool auto) {
    if (shuffle && queue.length > 1) {
      int n;
      do {
        n = _rnd.nextInt(queue.length);
      } while (n == index);
      return n;
    }
    final n = index + 1;
    if (n >= queue.length) return -1;
    return n;
  }

  void _onCompleted() {
    if (repeat == SdvigRepeat.one) {
      _p.seek(Duration.zero);
      _p.play();
      return;
    }
    if (queue.isEmpty) return;
    var n = _nextIndex(true);
    if (n < 0) {
      if (repeat == SdvigRepeat.all) {
        n = 0;
      } else {
        _p.pause();
        _p.seek(Duration.zero);
        return;
      }
    }
    _start(n);
  }

  void prev() {
    if (queue.isEmpty) return;
    if (pos.value.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }
    final i = index - 1 < 0 ? queue.length - 1 : index - 1;
    _start(i);
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    repeat = SdvigRepeat.values[(repeat.index + 1) % SdvigRepeat.values.length];
    notifyListeners();
  }

  // ---------- очередь ----------

  void playNext(Track t) {
    if (current == null) {
      playFrom([t], t);
      return;
    }
    queue.insert(index + 1, t);
    notifyListeners();
  }

  void addToQueue(Track t) {
    if (current == null) {
      playFrom([t], t);
      return;
    }
    queue.add(t);
    notifyListeners();
  }

  void removeFromQueue(int i) {
    if (i < 0 || i >= queue.length || i == index) return;
    queue.removeAt(i);
    if (i < index) index--;
    notifyListeners();
  }

  // ---------- любимое и плейлисты ----------

  bool isLiked(Track t) => playlists[kFav]!.any((x) => x.id == t.id);

  void toggleLike(Track t) {
    final fav = playlists[kFav]!;
    if (fav.any((x) => x.id == t.id)) {
      fav.removeWhere((x) => x.id == t.id);
    } else {
      fav.insert(0, t);
    }
    _savePlaylists();
    notifyListeners();
  }

  void createPlaylist(String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    playlists.putIfAbsent(n, () => <Track>[]);
    _savePlaylists();
    notifyListeners();
  }

  void deletePlaylist(String name) {
    if (name == kFav) return;
    playlists.remove(name);
    _savePlaylists();
    notifyListeners();
  }

  void addToPlaylist(String name, Track t) {
    final list = playlists.putIfAbsent(name, () => <Track>[]);
    if (!list.any((x) => x.id == t.id)) list.add(t);
    _savePlaylists();
    notifyListeners();
  }

  void removeFromPlaylist(String name, Track t) {
    playlists[name]?.removeWhere((x) => x.id == t.id);
    _savePlaylists();
    notifyListeners();
  }

  // ---------- звук ----------

  String _eqFilter(List<double> g) {
    if (g.every((x) => x.abs() < 0.1)) return '';
    const freqs = [60, 250, 1000, 4000, 16000];
    final parts = <String>[];
    for (var i = 0; i < 5; i++) {
      if (g[i].abs() >= 0.1) {
        parts.add(
          'equalizer=f=${freqs[i]}:t=o:w=1:g=${g[i].toStringAsFixed(1)}',
        );
      }
    }
    return 'lavfi=[${parts.join(',')}]';
  }

  Future<void> _applyAudio({bool force = false}) async {
    final af = _eqFilter(settings.eq);
    if (force || af != _lastAf) {
      _lastAf = af;
      try {
        await (_p.platform as dynamic).setProperty('af', af);
      } catch (_) {}
    }
    if (force || settings.speed != _lastRate) {
      _lastRate = settings.speed;
      try {
        await _p.setRate(settings.speed);
      } catch (_) {}
    }
  }
}

final PlayerController player = PlayerController();

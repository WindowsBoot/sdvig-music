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

  // статистика
  final Map<String, int> _plays = {};
  final Map<String, Track> _statTracks = {};

  // таймер сна
  Timer? _sleepTimer;
  DateTime? sleepAt;

  int _gen = 0;
  String _lastAudioKey = '#';

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

  List<Track> _decodeTracks(dynamic v) => (v as List)
      .map((e) => Track.fromJson(e as Map<String, dynamic>))
      .toList();

  void _loadLists() {
    final p = _prefs!;
    try {
      final raw = p.getString('playlists');
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        final loaded = <String, List<Track>>{};
        m.forEach((k, v) {
          loaded[k] = _decodeTracks(v);
        });
        playlists
          ..clear()
          ..addAll(loaded);
      }
      final rr = p.getString('recent');
      if (rr != null) recent = _decodeTracks(jsonDecode(rr));
      final st = p.getString('stats');
      if (st != null) {
        for (final e in jsonDecode(st) as List) {
          final m = e as Map<String, dynamic>;
          final t = Track.fromJson(m['t'] as Map<String, dynamic>);
          _statTracks[t.id] = t;
          _plays[t.id] = (m['n'] as num).toInt();
        }
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

  void _countPlay(Track t) {
    _plays[t.id] = (_plays[t.id] ?? 0) + 1;
    _statTracks[t.id] = t;
    final list = _plays.entries
        .where((e) => _statTracks.containsKey(e.key))
        .map((e) => {'t': _statTracks[e.key]!.toJson(), 'n': e.value})
        .toList();
    _prefs?.setString('stats', jsonEncode(list));
  }

  // ---------- статистика ----------

  int get totalPlays => _plays.values.fold(0, (a, b) => a + b);

  int get totalMinutes {
    var s = 0;
    _plays.forEach((id, c) {
      final t = _statTracks[id];
      if (t != null) s += t.durationSec * c;
    });
    return s ~/ 60;
  }

  List<MapEntry<Track, int>> topTracks(int n) {
    final l = _plays.entries
        .where((e) => _statTracks.containsKey(e.key))
        .map((e) => MapEntry(_statTracks[e.key]!, e.value))
        .toList();
    l.sort((a, b) => b.value.compareTo(a.value));
    return l.take(n).toList();
  }

  List<MapEntry<String, int>> topArtists(int n) {
    final m = <String, int>{};
    _plays.forEach((id, c) {
      final t = _statTracks[id];
      if (t != null) m[t.artist] = (m[t.artist] ?? 0) + c;
    });
    final l = m.entries.toList();
    l.sort((a, b) => b.value.compareTo(a.value));
    return l.take(n).toList();
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
      _countPlay(t);
      _prefetch();
    } catch (e) {
      if (gen == _gen) toast('Полная версия не найдена: ${t.title}');
    } finally {
      if (gen == _gen) {
        loading = false;
        notifyListeners();
      }
    }
  }

  /// Заранее подбираем полную версию следующего трека из каталога.
  void _prefetch() {
    final n = index + 1;
    if (n >= queue.length) return;
    final t = queue[n];
    if (t.url != null) return;
    try {
      if (ProviderRegistry.of(t.source).isCatalog) {
        Resolver.fullUrl(t).catchError((Object _) => '');
      }
    } catch (_) {}
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
    var n = _nextIndex();
    if (n < 0) n = 0;
    _start(n);
  }

  int _nextIndex() {
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
    var n = _nextIndex();
    if (n < 0) {
      if (repeat == SdvigRepeat.all) {
        n = 0;
      } else if (settings.autoRadio && current != null) {
        _continueRadio(current!);
        return;
      } else {
        _p.pause();
        _p.seek(Duration.zero);
        return;
      }
    }
    _start(n);
  }

  /// Автоплей: когда очередь закончилась, подбираем продолжение по исполнителю.
  Future<void> _continueRadio(Track last) async {
    toast('Автоплей: подбираю продолжение');
    try {
      var list = await ProviderRegistry.deezer.search(last.artist);
      final ids = queue.map((e) => e.id).toSet();
      list = list.where((t) => !ids.contains(t.id)).take(12).toList();
      if (list.isEmpty) {
        _p.pause();
        return;
      }
      final start = queue.length;
      queue.addAll(list);
      _start(start);
    } catch (_) {
      _p.pause();
    }
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

  // ---------- таймер сна ----------

  void setSleep(Duration? d) {
    _sleepTimer?.cancel();
    if (d == null) {
      sleepAt = null;
    } else {
      sleepAt = DateTime.now().add(d);
      _sleepTimer = Timer(d, () {
        _p.pause();
        sleepAt = null;
        toast('Таймер сна: музыка остановлена');
        notifyListeners();
      });
    }
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

  String _filterChain() {
    final parts = <String>[];
    const freqs = [60, 250, 1000, 4000, 16000];
    final g = settings.eq;
    for (var i = 0; i < 5; i++) {
      if (g[i].abs() >= 0.1) {
        parts.add(
          'equalizer=f=${freqs[i]}:t=o:w=1:g=${g[i].toStringAsFixed(1)}',
        );
      }
    }
    final m = modeById(settings.mode);
    if (m.filter.isNotEmpty) parts.add(m.filter);
    if (parts.isEmpty) return '';
    return 'lavfi=[${parts.join(',')}]';
  }

  Future<void> _applyAudio({bool force = false}) async {
    final m = modeById(settings.mode);
    final af = _filterChain();
    final rate = m.rate ?? settings.speed;
    final key = '$af|$rate|${m.keepPitch}';
    if (!force && key == _lastAudioKey) return;
    _lastAudioKey = key;
    final dyn = _p.platform as dynamic;
    try {
      await dyn.setProperty('af', af);
    } catch (_) {}
    try {
      await dyn.setProperty('audio-pitch-correction', m.keepPitch ? 'yes' : 'no');
    } catch (_) {}
    try {
      await _p.setRate(rate);
    } catch (_) {}
  }
}

final PlayerController player = PlayerController();

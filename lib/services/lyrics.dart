import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track.dart';

class LrcLine {
  const LrcLine(this.t, this.text);

  final double t;
  final String text;
}

class Lyrics {
  const Lyrics(this.lines, this.synced);

  final List<LrcLine> lines;
  final bool synced;
}

/// Тексты песен из открытой базы LRCLIB (с синхронизацией по времени).
class LyricsService {
  static final Map<String, Lyrics?> _cache = {};
  static const Map<String, String> _h = {
    'User-Agent': 'SDVIG/0.3 (https://github.com/WindowsBoot/sdvig-music)',
  };

  static Future<Lyrics?> fetch(Track t) async {
    if (_cache.containsKey(t.id)) return _cache[t.id];
    Lyrics? res;
    try {
      res = await _load(t);
    } catch (_) {}
    _cache[t.id] = res;
    return res;
  }

  static Future<dynamic> _json(Uri u) async {
    final r = await http.get(u, headers: _h).timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) return null;
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  static String _clean(String s) => s
      .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static Future<Lyrics?> _load(Track t) async {
    var title = _clean(t.title);
    var artist = _clean(t.artist).replaceAll(RegExp(r'\s*-\s*Topic$'), '');
    final dash = title.indexOf(' - ');
    if (dash > 0) {
      artist = title.substring(0, dash).trim();
      title = title.substring(dash + 3).trim();
    }
    final qp = <String, String>{
      'artist_name': artist,
      'track_name': title,
      if (t.durationSec > 30) 'duration': '${t.durationSec}',
    };
    var j = await _json(Uri.https('lrclib.net', '/api/get', qp));
    if (j is! Map) {
      final s = await _json(
        Uri.https('lrclib.net', '/api/search', {'q': '$artist $title'}),
      );
      if (s is List && s.isNotEmpty && s.first is Map) j = s.first;
    }
    if (j is! Map) return null;
    final synced = (j['syncedLyrics'] ?? '').toString();
    if (synced.isNotEmpty) {
      final lines = <LrcLine>[];
      final re = RegExp(r'^\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)$');
      for (final raw in synced.split('\n')) {
        final m = re.firstMatch(raw.trim());
        if (m == null) continue;
        final text = m.group(3)!.trim();
        if (text.isEmpty) continue;
        final sec = int.parse(m.group(1)!) * 60 + double.parse(m.group(2)!);
        lines.add(LrcLine(sec, text));
      }
      if (lines.isNotEmpty) return Lyrics(lines, true);
    }
    final plain = (j['plainLyrics'] ?? '').toString();
    if (plain.isNotEmpty) {
      final lines = plain
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map((e) => LrcLine(-1, e))
          .toList();
      if (lines.isNotEmpty) return Lyrics(lines, false);
    }
    return null;
  }
}

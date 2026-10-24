import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/track.dart';

const Map<String, String> _headers = {'User-Agent': 'SDVIG/0.2'};

Future<dynamic> _getJson(Uri u) async {
  final r =
      await http.get(u, headers: _headers).timeout(const Duration(seconds: 12));
  if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
  return jsonDecode(utf8.decode(r.bodyBytes));
}

String _s(dynamic v) => v == null ? '' : v.toString();
int _i(dynamic v) => v is num ? v.toInt() : 0;
String? _nz(String v) => v.isEmpty ? null : v;

/// Контракт источника музыки. Каждый сервис - отдельная реализация.
abstract class MusicProvider {
  MusicSource get source;
  Future<List<Track>> search(String query);
  Future<List<Track>> trending() async => <Track>[];
  Future<String> streamUrl(Track t);
}

/// Audius: открытая платформа, полные треки без ключей.
class AudiusProvider extends MusicProvider {
  static const String _base = 'https://api.audius.co/v1';

  @override
  MusicSource get source => MusicSource.audius;

  List<Track> _map(dynamic data) {
    final out = <Track>[];
    if (data is! List) return out;
    for (final e in data) {
      if (e is! Map) continue;
      final id = _s(e['id']);
      if (id.isEmpty) continue;
      final user = e['user'];
      final art = e['artwork'];
      out.add(Track(
        id: 'audius:$id',
        title: _s(e['title']),
        artist: user is Map ? _s(user['name']) : '',
        durationSec: _i(e['duration']),
        source: MusicSource.audius,
        cover: art is Map ? _nz(_s(art['480x480'])) : null,
        url: '$_base/tracks/$id/stream?app_name=SDVIG',
      ));
    }
    return out;
  }

  @override
  Future<List<Track>> search(String query) async {
    if (query.trim().isEmpty) return trending();
    final u = Uri.parse('$_base/tracks/search').replace(queryParameters: {
      'query': query,
      'app_name': 'SDVIG',
      'limit': '25',
    });
    final j = await _getJson(u);
    return _map(j['data']);
  }

  @override
  Future<List<Track>> trending() async {
    final u = Uri.parse('$_base/tracks/trending').replace(queryParameters: {
      'app_name': 'SDVIG',
      'limit': '20',
    });
    final j = await _getJson(u);
    return _map(j['data']);
  }

  @override
  Future<String> streamUrl(Track t) async =>
      '$_base/tracks/${t.rawId}/stream?app_name=SDVIG';
}

/// Deezer: публичный поиск без ключа, воспроизводятся превью по 30 секунд.
class DeezerProvider extends MusicProvider {
  @override
  MusicSource get source => MusicSource.deezer;

  List<Track> _map(dynamic data) {
    final out = <Track>[];
    if (data is! List) return out;
    for (final e in data) {
      if (e is! Map) continue;
      final id = _s(e['id']);
      final preview = _s(e['preview']);
      if (id.isEmpty || preview.isEmpty) continue;
      final artist = e['artist'];
      final album = e['album'];
      out.add(Track(
        id: 'deezer:$id',
        title: _s(e['title']),
        artist: artist is Map ? _s(artist['name']) : '',
        durationSec: 30,
        source: MusicSource.deezer,
        cover: album is Map ? _nz(_s(album['cover_big'])) : null,
        url: preview,
      ));
    }
    return out;
  }

  @override
  Future<List<Track>> search(String query) async {
    if (query.trim().isEmpty) return trending();
    final u = Uri.https('api.deezer.com', '/search', {
      'q': query,
      'limit': '25',
    });
    final j = await _getJson(u);
    return _map(j['data']);
  }

  @override
  Future<List<Track>> trending() async {
    final u = Uri.https('api.deezer.com', '/chart/0/tracks', {'limit': '20'});
    final j = await _getJson(u);
    return _map(j['data']);
  }

  @override
  Future<String> streamUrl(Track t) async {
    final j = await _getJson(Uri.https('api.deezer.com', '/track/${t.rawId}'));
    final p = _s(j['preview']);
    if (p.isEmpty) throw Exception('no preview');
    return p;
  }
}

/// Apple Music (каталог iTunes): поиск без ключа, превью по 30 секунд.
class AppleProvider extends MusicProvider {
  @override
  MusicSource get source => MusicSource.appleMusic;

  @override
  Future<List<Track>> search(String query) async {
    if (query.trim().isEmpty) return <Track>[];
    final u = Uri.https('itunes.apple.com', '/search', {
      'term': query,
      'media': 'music',
      'entity': 'song',
      'limit': '25',
    });
    final j = await _getJson(u);
    final out = <Track>[];
    final data = j['results'];
    if (data is! List) return out;
    for (final e in data) {
      if (e is! Map) continue;
      final id = _s(e['trackId']);
      final preview = _s(e['previewUrl']);
      if (id.isEmpty || preview.isEmpty) continue;
      out.add(Track(
        id: 'apple:$id',
        title: _s(e['trackName']),
        artist: _s(e['artistName']),
        durationSec: 30,
        source: MusicSource.appleMusic,
        cover: _nz(_s(e['artworkUrl100']).replaceAll('100x100', '600x600')),
        url: preview,
      ));
    }
    return out;
  }

  @override
  Future<String> streamUrl(Track t) async {
    final j = await _getJson(
        Uri.https('itunes.apple.com', '/lookup', {'id': t.rawId}));
    final r = j['results'];
    if (r is List && r.isNotEmpty && r.first is Map) {
      final p = _s((r.first as Map)['previewUrl']);
      if (p.isNotEmpty) return p;
    }
    throw Exception('no preview');
  }
}

/// YouTube: неофициальный доступ, может ломаться при обновлениях сервиса.
class YouTubeProvider extends MusicProvider {
  final YoutubeExplode _yt = YoutubeExplode();

  @override
  MusicSource get source => MusicSource.youtubeMusic;

  @override
  Future<List<Track>> search(String query) async {
    if (query.trim().isEmpty) return <Track>[];
    final res = await _yt.search.search(query);
    final out = <Track>[];
    for (final v in res) {
      if (out.length >= 20) break;
      final d = v.duration;
      if (d == null || d.inMinutes > 15) continue;
      out.add(Track(
        id: 'yt:${v.id.value}',
        title: v.title,
        artist: v.author,
        durationSec: d.inSeconds,
        source: MusicSource.youtubeMusic,
        cover: v.thumbnails.highResUrl,
      ));
    }
    return out;
  }

  @override
  Future<String> streamUrl(Track t) async {
    final m = await _yt.videos.streamsClient.getManifest(t.rawId);
    final a = m.audioOnly.withHighestBitrate();
    return a.url.toString();
  }
}

class ProviderRegistry {
  static final AudiusProvider audius = AudiusProvider();
  static final DeezerProvider deezer = DeezerProvider();
  static final AppleProvider apple = AppleProvider();
  static final YouTubeProvider youtube = YouTubeProvider();

  /// Порядок важен: сначала источники с полными треками.
  static final List<MusicProvider> live = [youtube, audius, apple, deezer];

  static MusicProvider of(MusicSource s) {
    for (final p in live) {
      if (p.source == s) return p;
    }
    throw StateError('Нет провайдера для ${s.name}');
  }
}

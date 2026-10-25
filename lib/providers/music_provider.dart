import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/track.dart';
import '../state/settings.dart';

const Map<String, String> _headers = {'User-Agent': 'SDVIG/0.3'};

Future<dynamic> _getJson(Uri u, {Map<String, String>? headers}) async {
  final r = await http
      .get(u, headers: headers ?? _headers)
      .timeout(const Duration(seconds: 12));
  if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
  return jsonDecode(utf8.decode(r.bodyBytes));
}

String _s(dynamic v) => v == null ? '' : v.toString();
int _i(dynamic v) => v is num ? v.toInt() : 0;
String? _nz(String v) => v.isEmpty ? null : v;

/// Контракт источника музыки.
/// Каталоги (Deezer, Apple Music, Spotify) дают точные названия и обложки,
/// а полная версия находится через [Resolver] (YouTube, SoundCloud, Audius).
abstract class MusicProvider {
  MusicSource get source;
  bool get isCatalog => false;
  bool get enabled => true;
  Future<List<Track>> search(String query);
  Future<List<Track>> trending() async => <Track>[];
  Future<String> streamUrl(Track t);
}

/// Подбор полной версии трека по каталогу: ищем совпадение по названию,
/// исполнителю и длительности. Превью по 30 секунд не используются.
class Resolver {
  static final Map<String, String> _cache = {};
  static final RegExp _split = RegExp(r'[\s\-–—_/,&()\[\].:;!?"«»|]+');
  static const List<String> _bad = [
    'live',
    'cover',
    'karaoke',
    'remix',
    'slowed',
    'sped',
    'nightcore',
    'reverb',
    'instrumental',
    '8d',
    'ремикс',
    'кавер',
    'караоке',
  ];

  static List<String> _tok(String s) =>
      s.toLowerCase().split(_split).where((w) => w.length > 1).toList();

  static Track? _pick(Track want, List<Track> cand) {
    final wt = _tok(want.title);
    final wa = _tok(want.artist);
    if (wt.isEmpty) return null;
    final tol = max(12.0, want.durationSec * 0.08);
    final wl = want.title.toLowerCase();
    Track? best;
    double bestScore = -1;
    for (final c in cand) {
      final diff = (c.durationSec - want.durationSec).abs().toDouble();
      if (want.durationSec > 0 && diff > tol) continue;
      final hay = '${c.title} ${c.artist}'.toLowerCase();
      final tHit = wt.where((w) => hay.contains(w)).length / wt.length;
      if (tHit < 0.6) continue;
      final aHit =
          wa.isEmpty ? 1.0 : wa.where((w) => hay.contains(w)).length / wa.length;
      var score = tHit * 50 +
          aHit * 30 +
          (want.durationSec > 0 ? (1 - diff / tol) * 20 : 10);
      final cl = c.title.toLowerCase();
      for (final b in _bad) {
        if (cl.contains(b) && !wl.contains(b)) score -= 40;
      }
      if (score > bestScore) {
        bestScore = score;
        best = c;
      }
    }
    return bestScore >= 45 ? best : null;
  }

  static Future<String> fullUrl(Track t) async {
    final cached = _cache[t.id];
    if (cached != null) return cached;
    final q = '${t.artist} ${t.title}';
    final chain = <MusicProvider>[
      ProviderRegistry.youtube,
      ProviderRegistry.soundcloud,
      ProviderRegistry.audius,
    ];
    for (final p in chain) {
      try {
        final list = await p.search(q);
        final best = _pick(t, list);
        if (best != null) {
          final url = best.url ?? await p.streamUrl(best);
          _cache[t.id] = url;
          return url;
        }
      } catch (_) {}
    }
    throw Exception('Полная версия не найдена');
  }
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

/// Deezer: публичный каталог без ключа (полная длительность, обложки).
class DeezerProvider extends MusicProvider {
  @override
  MusicSource get source => MusicSource.deezer;

  @override
  bool get isCatalog => true;

  List<Track> _map(dynamic data) {
    final out = <Track>[];
    if (data is! List) return out;
    for (final e in data) {
      if (e is! Map) continue;
      final id = _s(e['id']);
      if (id.isEmpty) continue;
      final artist = e['artist'];
      final album = e['album'];
      out.add(Track(
        id: 'deezer:$id',
        title: _s(e['title']),
        artist: artist is Map ? _s(artist['name']) : '',
        durationSec: _i(e['duration']),
        source: MusicSource.deezer,
        cover: album is Map ? _nz(_s(album['cover_big'])) : null,
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
  Future<String> streamUrl(Track t) => Resolver.fullUrl(t);
}

/// Apple Music (каталог iTunes): точные названия и обложки без ключа.
class AppleProvider extends MusicProvider {
  @override
  MusicSource get source => MusicSource.appleMusic;

  @override
  bool get isCatalog => true;

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
      if (id.isEmpty) continue;
      out.add(Track(
        id: 'apple:$id',
        title: _s(e['trackName']),
        artist: _s(e['artistName']),
        durationSec: _i(e['trackTimeMillis']) ~/ 1000,
        source: MusicSource.appleMusic,
        cover: _nz(_s(e['artworkUrl100']).replaceAll('100x100', '600x600')),
      ));
    }
    return out;
  }

  @override
  Future<String> streamUrl(Track t) => Resolver.fullUrl(t);
}

/// Spotify: только каталог (нужны бесплатные ключи разработчика, вход не нужен).
class SpotifyProvider extends MusicProvider {
  String? _token;
  DateTime _exp = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  MusicSource get source => MusicSource.spotify;

  @override
  bool get isCatalog => true;

  @override
  bool get enabled =>
      settings.spotifyId.isNotEmpty && settings.spotifySecret.isNotEmpty;

  Future<String> _tok() async {
    if (_token != null && DateTime.now().isBefore(_exp)) return _token!;
    final basic = base64Encode(
      utf8.encode('${settings.spotifyId}:${settings.spotifySecret}'),
    );
    final r = await http
        .post(
          Uri.https('accounts.spotify.com', '/api/token'),
          headers: {
            'Authorization': 'Basic $basic',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: 'grant_type=client_credentials',
        )
        .timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) throw Exception('Spotify ${r.statusCode}');
    final j = jsonDecode(utf8.decode(r.bodyBytes));
    _token = _s(j['access_token']);
    _exp = DateTime.now().add(Duration(seconds: _i(j['expires_in']) - 60));
    return _token!;
  }

  @override
  Future<List<Track>> search(String query) async {
    if (query.trim().isEmpty) return <Track>[];
    final tok = await _tok();
    final j = await _getJson(
      Uri.https('api.spotify.com', '/v1/search', {
        'q': query,
        'type': 'track',
        'limit': '25',
      }),
      headers: {'Authorization': 'Bearer $tok'},
    );
    final out = <Track>[];
    final tracks = j['tracks'];
    final items = tracks is Map ? tracks['items'] : null;
    if (items is! List) return out;
    for (final e in items) {
      if (e is! Map) continue;
      final id = _s(e['id']);
      if (id.isEmpty) continue;
      final artists = e['artists'];
      final names = <String>[];
      if (artists is List) {
        for (final a in artists) {
          if (a is Map) names.add(_s(a['name']));
        }
      }
      final album = e['album'];
      String cover = '';
      if (album is Map) {
        final imgs = album['images'];
        if (imgs is List && imgs.isNotEmpty && imgs.first is Map) {
          cover = _s((imgs.first as Map)['url']);
        }
      }
      out.add(Track(
        id: 'spotify:$id',
        title: _s(e['name']),
        artist: names.join(', '),
        durationSec: _i(e['duration_ms']) ~/ 1000,
        source: MusicSource.spotify,
        cover: _nz(cover),
      ));
    }
    return out;
  }

  @override
  Future<String> streamUrl(Track t) => Resolver.fullUrl(t);
}

/// SoundCloud: неофициальный анонимный доступ (без входа). Превью (SNIP) пропускаются.
class SoundCloudProvider extends MusicProvider {
  String? _clientId;

  @override
  MusicSource get source => MusicSource.soundcloud;

  Future<String> _cid() async {
    final c = _clientId;
    if (c != null) return c;
    final page = await http
        .get(Uri.https('soundcloud.com', '/'), headers: _headers)
        .timeout(const Duration(seconds: 12));
    final html = utf8.decode(page.bodyBytes, allowMalformed: true);
    final scripts = RegExp(r'src="(https://a-v2\.sndcdn\.com/assets/[^"]+\.js)"')
        .allMatches(html)
        .map((m) => m.group(1)!)
        .toList();
    for (final u in scripts.reversed) {
      try {
        final r = await http
            .get(Uri.parse(u), headers: _headers)
            .timeout(const Duration(seconds: 12));
        final m = RegExp(r'client_id:"([a-zA-Z0-9]{32})"').firstMatch(r.body);
        if (m != null) {
          _clientId = m.group(1);
          return _clientId!;
        }
      } catch (_) {}
    }
    throw Exception('SoundCloud: нет client_id');
  }

  @override
  Future<List<Track>> search(String query) async {
    if (query.trim().isEmpty) return <Track>[];
    try {
      final cid = await _cid();
      final j = await _getJson(
        Uri.https('api-v2.soundcloud.com', '/search/tracks', {
          'q': query,
          'client_id': cid,
          'limit': '25',
        }),
      );
      final out = <Track>[];
      final col = j['collection'];
      if (col is! List) return out;
      for (final e in col) {
        if (e is! Map) continue;
        final policy = _s(e['policy']);
        if (policy == 'SNIP' || policy == 'BLOCK') continue;
        final id = _s(e['id']);
        if (id.isEmpty) continue;
        final user = e['user'];
        var art = _s(e['artwork_url']);
        if (art.isEmpty && user is Map) art = _s(user['avatar_url']);
        final dur = e['full_duration'] ?? e['duration'];
        out.add(Track(
          id: 'sc:$id',
          title: _s(e['title']),
          artist: user is Map ? _s(user['username']) : '',
          durationSec: _i(dur) ~/ 1000,
          source: MusicSource.soundcloud,
          cover: _nz(art.replaceAll('-large', '-t500x500')),
        ));
      }
      return out;
    } catch (e) {
      _clientId = null;
      rethrow;
    }
  }

  @override
  Future<String> streamUrl(Track t) async {
    final cid = await _cid();
    final tr = await _getJson(
      Uri.https('api-v2.soundcloud.com', '/tracks/${t.rawId}', {
        'client_id': cid,
      }),
    );
    final auth = _s(tr['track_authorization']);
    final media = tr['media'];
    final list = media is Map ? media['transcodings'] : null;
    String? prog;
    String? hls;
    if (list is List) {
      for (final c in list) {
        if (c is! Map) continue;
        final fmt = c['format'];
        final proto = fmt is Map ? _s(fmt['protocol']) : '';
        final u = _s(c['url']);
        if (proto == 'progressive') prog ??= u;
        if (proto == 'hls') hls ??= u;
      }
    }
    final pick = prog ?? hls;
    if (pick == null) throw Exception('нет потока');
    final u = Uri.parse(pick).replace(queryParameters: {
      'client_id': cid,
      if (auth.isNotEmpty) 'track_authorization': auth,
    });
    final j = await _getJson(u);
    final url = _s(j['url']);
    if (url.isEmpty) throw Exception('нет ссылки');
    return url;
  }
}

/// YouTube: неофициальный анонимный доступ, может ломаться при обновлениях сервиса.
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
  static final SpotifyProvider spotify = SpotifyProvider();
  static final SoundCloudProvider soundcloud = SoundCloudProvider();
  static final YouTubeProvider youtube = YouTubeProvider();

  static final List<MusicProvider> live = [
    deezer,
    apple,
    spotify,
    youtube,
    soundcloud,
    audius,
  ];

  static MusicProvider of(MusicSource s) {
    for (final p in live) {
      if (p.source == s) return p;
    }
    throw StateError('Нет провайдера для ${s.name}');
  }
}

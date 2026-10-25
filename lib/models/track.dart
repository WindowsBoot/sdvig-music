enum MusicSource {
  soundcloud('SoundCloud', true, 'неофициально'),
  youtubeMusic('YouTube', true, 'неофициально'),
  yandex('Яндекс Музыка', false, ''),
  vk('VK Музыка', false, ''),
  spotify('Spotify', true, 'каталог, нужен ключ'),
  appleMusic('Apple Music', true, 'каталог → полная версия'),
  deezer('Deezer', true, 'каталог → полная версия'),
  audius('Audius', true, 'полные треки'),
  local('Мои файлы', false, '');

  const MusicSource(this.label, this.live, this.note);
  final String label;
  final bool live;
  final String note;
}

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.durationSec,
    required this.source,
    this.cover,
    this.url,
  });

  final String id;
  final String title;
  final String artist;
  final int durationSec;
  final MusicSource source;
  final String? cover;
  final String? url;

  int get seed => id.codeUnits.fold(7, (a, b) => (a * 31 + b) & 0x7fffffff);

  String get rawId => id.contains(':') ? id.substring(id.indexOf(':') + 1) : id;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'dur': durationSec,
        'source': source.name,
        'cover': cover,
      };

  factory Track.fromJson(Map<String, dynamic> j) => Track(
        id: j['id'] as String,
        title: j['title'] as String,
        artist: j['artist'] as String,
        durationSec: (j['dur'] as num?)?.toInt() ?? 0,
        source: MusicSource.values.firstWhere(
          (s) => s.name == j['source'],
          orElse: () => MusicSource.local,
        ),
        cover: j['cover'] as String?,
      );
}

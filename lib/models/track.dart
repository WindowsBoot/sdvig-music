enum MusicSource {
  soundcloud('SoundCloud'),
  youtubeMusic('YouTube Music'),
  yandex('Яндекс Музыка'),
  vk('VK Музыка'),
  spotify('Spotify'),
  appleMusic('Apple Music'),
  deezer('Deezer'),
  local('Мои файлы');

  const MusicSource(this.label);
  final String label;
}

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.durationSec,
    required this.source,
  });

  final String id;
  final String title;
  final String artist;
  final int durationSec;
  final MusicSource source;

  int get seed => id.codeUnits.fold(7, (a, b) => (a * 31 + b) & 0x7fffffff);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'dur': durationSec,
        'source': source.name,
      };

  factory Track.fromJson(Map<String, dynamic> j) => Track(
        id: j['id'] as String,
        title: j['title'] as String,
        artist: j['artist'] as String,
        durationSec: j['dur'] as int,
        source: MusicSource.values.firstWhere(
          (s) => s.name == j['source'],
          orElse: () => MusicSource.local,
        ),
      );
}

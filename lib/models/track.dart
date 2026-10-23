enum MusicSource {
  soundcloud,
  youtubeMusic,
  yandex,
  vk,
  spotify,
  appleMusic,
  deezer,
  local,
}

extension MusicSourceX on MusicSource {
  String get label {
    switch (this) {
      case MusicSource.soundcloud:
        return 'SoundCloud';
      case MusicSource.youtubeMusic:
        return 'YouTube Music';
      case MusicSource.yandex:
        return 'Яндекс Музыка';
      case MusicSource.vk:
        return 'VK Музыка';
      case MusicSource.spotify:
        return 'Spotify';
      case MusicSource.appleMusic:
        return 'Apple Music';
      case MusicSource.deezer:
        return 'Deezer';
      case MusicSource.local:
        return 'Мои файлы';
    }
  }
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

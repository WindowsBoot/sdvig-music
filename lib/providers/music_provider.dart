import '../data/demo.dart';
import '../models/track.dart';

/// Контракт источника музыки. Для каждого сервиса будет своя реализация
/// (SoundCloud, YouTube Music, Яндекс, VK, Spotify, Apple Music, Deezer). Пока - демо-данные.
abstract class MusicProvider {
  MusicSource get source;
  Future<List<Track>> search(String query);
}

class DemoProvider implements MusicProvider {
  DemoProvider(this.source);

  @override
  final MusicSource source;

  @override
  Future<List<Track>> search(String query) async {
    final q = query.trim().toLowerCase();
    final all = demoTracks.where((t) => t.source == source);
    if (q.isEmpty) return all.toList();
    return all
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q))
        .toList();
  }
}

class ProviderRegistry {
  static final List<MusicProvider> all = [
    DemoProvider(MusicSource.soundcloud),
    DemoProvider(MusicSource.youtubeMusic),
    DemoProvider(MusicSource.yandex),
    DemoProvider(MusicSource.vk),
    DemoProvider(MusicSource.spotify),
    DemoProvider(MusicSource.appleMusic),
    DemoProvider(MusicSource.deezer),
  ];
}

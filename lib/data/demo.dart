import '../models/track.dart';

const _titles = [
  'Night Drive',
  'Static Bloom',
  'Paper Moon',
  'Low Tide',
  'Glass Hours',
  'Afterglow',
  'Monochrome',
  'Slow Signal',
  'Velvet Noise',
  'Ghost Frequency',
];

const _artists = [
  'Echo Unit',
  'Nova Lane',
  'Hollow Park',
  'Mira Vale',
  'Kiln',
  'Sable',
  'Orbit Kids',
  'Lumen',
];

List<Track> _build() {
  final out = <Track>[];
  var n = 0;
  for (final s in MusicSource.values.where((s) => s != MusicSource.local)) {
    for (var i = 0; i < 4; i++) {
      final k = (n * 3 + i) % _titles.length;
      out.add(Track(
        id: '${s.name}-$i',
        title: _titles[k],
        artist: _artists[(k + i) % _artists.length],
        durationSec: 150 + ((k * 37 + i * 53) % 120),
        source: s,
      ));
    }
    n++;
  }
  return out;
}

final List<Track> demoTracks = _build();

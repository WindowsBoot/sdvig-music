import 'package:flutter/material.dart';
import '../models/track.dart';
import '../providers/music_provider.dart';
import '../state/app_bus.dart';
import '../state/player.dart';
import '../state/settings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Track> _audius = [];
  List<Track> _deezer = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await Future.wait<List<Track>>([
      ProviderRegistry.audius.trending().catchError((Object _) => <Track>[]),
      ProviderRegistry.deezer.trending().catchError((Object _) => <Track>[]),
    ]);
    if (!mounted) return;
    setState(() {
      _audius = r[0];
      _deezer = r[1];
      _loading = false;
    });
  }

  void _playMix() {
    final list = [..._audius, ..._deezer]..shuffle();
    if (list.isEmpty) {
      toast('Нет подборок: проверь интернет или VPN');
      return;
    }
    player.playFrom(list, list.first);
  }

  void _playList(List<Track> list, String empty) {
    if (list.isEmpty) {
      toast(empty);
      return;
    }
    player.playFrom(list, list.first);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _loading = true);
        await _load();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/logo_mark.png',
                    width: 40,
                    height: 40,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'SDVIG',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  ),
                ),
              ],
            ),
          ),
          FadeSlideIn(child: _hero(context)),
          const SizedBox(height: 14),
          ListenableBuilder(
            listenable: player,
            builder: (context, _) {
              final fav = player.playlists[kFav] ?? <Track>[];
              return Row(
                children: [
                  Expanded(
                    child: FadeSlideIn(
                      index: 1,
                      child: _QuickTile(
                        icon: Icons.favorite,
                        title: 'Любимое',
                        subtitle: '${fav.length} треков',
                        onTap: () => _playList(fav, 'В любимом пока пусто'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FadeSlideIn(
                      index: 2,
                      child: _QuickTile(
                        icon: Icons.history,
                        title: 'Недавнее',
                        subtitle: '${player.recent.length} треков',
                        onTap: () =>
                            _playList(player.recent, 'История пока пуста'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          if (_loading) ...[
            const _SectionTitle('В тренде', 'загружаем подборки'),
            _skeleton(context),
          ] else if (_audius.isEmpty && _deezer.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Не удалось загрузить подборки.\nПроверь интернет или VPN.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurface.withAlpha(140)),
                  ),
                  const SizedBox(height: 12),
                  Pill(
                    label: 'Повторить',
                    selected: true,
                    onTap: () {
                      setState(() => _loading = true);
                      _load();
                    },
                  ),
                ],
              ),
            )
          else ...[
            if (_audius.isNotEmpty)
              _carousel('В тренде на Audius', 'полные треки', _audius),
            if (_deezer.isNotEmpty)
              _carousel('Чарт Deezer', 'превью 30 с', _deezer),
          ],
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Pressable(
      onTap: _playMix,
      scale: 0.98,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: cs.onSurface,
          borderRadius: BorderRadius.circular(settings.radius * 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _RingsPainter(cs.surface.withAlpha(45)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Слушать\nмикс',
                          style: TextStyle(
                            fontSize: 32,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            color: cs.surface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Подборка из трендов',
                          style: TextStyle(color: cs.surface.withAlpha(170)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: cs.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 40,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeleton(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => Container(
          width: 148,
          decoration: BoxDecoration(
            color: panelColor(context),
            borderRadius: BorderRadius.circular(settings.radius),
          ),
        ),
      ),
    );
  }

  Widget _carousel(String title, String subtitle, List<Track> tracks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title, subtitle),
          SizedBox(
            height: 214,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tracks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final t = tracks[i];
                return FadeSlideIn(
                  index: i,
                  child: Pressable(
                    onTap: () => player.playFrom(tracks, t),
                    scale: 0.96,
                    child: SizedBox(
                      width: 148,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Cover(track: t, size: 148, radius: settings.radius),
                          const SizedBox(height: 8),
                          Text(
                            t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            t.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(140),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 10),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(120)),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Pressable(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: panelColor(context),
          borderRadius: BorderRadius.circular(settings.radius),
          border: Border.all(color: cs.onSurface.withAlpha(25)),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(130),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final center = Offset(s.width * 0.85, s.height * 0.3);
    for (var i = 1; i <= 9; i++) {
      c.drawCircle(center, s.width * 0.09 * i, p);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => old.color != color;
}

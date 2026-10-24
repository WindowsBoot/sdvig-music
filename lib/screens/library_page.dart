import 'package:flutter/material.dart';
import '../models/track.dart';
import '../state/player.dart';
import '../state/settings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/track_tile.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([player, settings]),
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'БИБЛИОТЕКА',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      final n = await askPlaylistName(context);
                      if (n != null) player.createPlaylist(n);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  for (final e in const ['Любимое', 'Недавнее', 'Плейлисты']
                      .asMap()
                      .entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Pill(
                        label: e.value,
                        selected: _tab == e.key,
                        onTap: () => setState(() => _tab = e.key),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey<int>(_tab),
                  child: _content(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _content(BuildContext context) {
    if (_tab == 0) {
      return _trackList(
        context,
        player.playlists[kFav] ?? <Track>[],
        'Нажми сердечко у трека, чтобы он появился здесь.',
      );
    }
    if (_tab == 1) {
      return _trackList(context, player.recent, 'История прослушивания пуста.');
    }
    return _playlists(context);
  }

  Widget _trackList(BuildContext context, List<Track> tracks, String empty) {
    final cs = Theme.of(context).colorScheme;
    if (tracks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            empty,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurface.withAlpha(130)),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: tracks.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Pill(
                  label: 'Слушать',
                  selected: true,
                  onTap: () => player.playFrom(tracks, tracks.first),
                ),
                const SizedBox(width: 8),
                Pill(
                  label: 'Перемешать',
                  selected: false,
                  onTap: () {
                    final l = List<Track>.from(tracks)..shuffle();
                    player.playFrom(l, l.first);
                  },
                ),
              ],
            ),
          );
        }
        return FadeSlideIn(
          index: i - 1,
          child: TrackTile(track: tracks[i - 1], queue: tracks),
        );
      },
    );
  }

  Widget _playlists(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text(
            'Плейлисты хранятся на устройстве, вход в аккаунт не нужен.',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(130)),
          ),
        ),
        for (final e in player.playlists.entries)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: panelColor(context),
              borderRadius: BorderRadius.circular(settings.radius),
            ),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(
                  e.key,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('${e.value.length} треков'),
                children: [
                  if (e.value.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Пока пусто. Добавляй треки из поиска.'),
                    ),
                  for (final t in e.value)
                    ListTile(
                      leading: Cover(
                        track: t,
                        size: 44,
                        radius: settings.radius / 2,
                      ),
                      title: Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('${t.artist} · ${t.source.label}'),
                      onTap: () => player.playFrom(e.value, t),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => player.removeFromPlaylist(e.key, t),
                      ),
                    ),
                  if (e.key != kFav)
                    ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: const Text('Удалить плейлист'),
                      onTap: () => player.deletePlaylist(e.key),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

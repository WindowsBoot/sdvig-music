import 'package:flutter/material.dart';
import '../state/player.dart';
import '../state/settings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/gen_cover.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: Listenable.merge([player, settings]),
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      'БИБЛИОТЕКА',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 5,
                      ),
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
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                'Плейлисты хранятся на устройстве - вход в аккаунт не нужен.',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withAlpha(130),
                ),
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
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
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
                          leading: GenCover(
                            seed: t.seed,
                            size: 44,
                            radius: settings.radius / 2,
                          ),
                          title: Text(t.title),
                          subtitle: Text('${t.artist} · ${t.source.label}'),
                          onTap: () => player.play(t, inQueue: e.value),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                player.removeFromPlaylist(e.key, t),
                          ),
                        ),
                      if (e.key != 'Избранное')
                        ListTile(
                          leading: const Icon(Icons.delete_outline),
                          title: const Text('Удалить плейлист'),
                          onTap: () => player.deletePlaylist(e.key),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(settings.radius),
                border: Border.all(color: cs.onSurface.withAlpha(40)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.folder_open),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Свои файлы с устройства: добавим в части 2',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

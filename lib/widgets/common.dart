import 'package:flutter/material.dart';
import '../models/track.dart';
import '../state/player.dart';

String fmtTime(double s) {
  final t = s.floor();
  return '${t ~/ 60}:${(t % 60).toString().padLeft(2, '0')}';
}

Future<String?> askPlaylistName(BuildContext context) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Новый плейлист'),
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Название'),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, c.text),
          child: const Text('Создать'),
        ),
      ],
    ),
  );
}

void showAddToPlaylist(BuildContext context, Track t) {
  final messenger = ScaffoldMessenger.of(context);
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: ListenableBuilder(
        listenable: player,
        builder: (_, __) => ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'ДОБАВИТЬ В ПЛЕЙЛИСТ',
                style: TextStyle(fontSize: 12, letterSpacing: 2),
              ),
            ),
            for (final name in player.playlists.keys)
              ListTile(
                leading: const Icon(Icons.queue_music),
                title: Text(name),
                onTap: () {
                  player.addToPlaylist(name, t);
                  Navigator.pop(ctx);
                  messenger.showSnackBar(
                    SnackBar(content: Text('Добавлено в «$name»')),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Новый плейлист'),
              onTap: () async {
                final n = await askPlaylistName(ctx);
                if (n != null && n.trim().isNotEmpty) {
                  player.createPlaylist(n);
                  player.addToPlaylist(n.trim(), t);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

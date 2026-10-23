import 'package:flutter/material.dart';
import '../state/player.dart';
import '../state/settings.dart';
import '../widgets/common.dart';
import '../widgets/gen_cover.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'СЕЙЧАС ИГРАЕТ',
          style: TextStyle(fontSize: 12, letterSpacing: 3),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([player, settings]),
          builder: (context, _) {
            final t = player.current;
            if (t == null) return const SizedBox.shrink();
            final dur = t.durationSec.toDouble();
            final accentOn = cs.primary;
            final dim = cs.onSurface.withAlpha(110);
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Expanded(
                        child: Center(
                          child: GenCover(
                            seed: t.seed,
                            radius: settings.radius * 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${t.artist} · ${t.source.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: cs.onSurface.withAlpha(150)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: player.position.clamp(0.0, dur).toDouble(),
                        max: dur,
                        onChanged: player.seek,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            fmtTime(player.position),
                            style: TextStyle(fontSize: 12, color: dim),
                          ),
                          Text(
                            fmtTime(dur),
                            style: TextStyle(fontSize: 12, color: dim),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.shuffle,
                              color: player.shuffle ? accentOn : dim,
                            ),
                            onPressed: player.toggleShuffle,
                          ),
                          IconButton(
                            iconSize: 36,
                            icon: const Icon(Icons.skip_previous),
                            onPressed: player.prev,
                          ),
                          IconButton.filled(
                            iconSize: 40,
                            style: IconButton.styleFrom(
                              backgroundColor: cs.onSurface,
                              foregroundColor: cs.surface,
                            ),
                            icon: Icon(
                              player.playing ? Icons.pause : Icons.play_arrow,
                            ),
                            onPressed: player.toggle,
                          ),
                          IconButton(
                            iconSize: 36,
                            icon: const Icon(Icons.skip_next),
                            onPressed: player.next,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.repeat,
                              color: player.repeat ? accentOn : dim,
                            ),
                            onPressed: player.toggleRepeat,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: () => showAddToPlaylist(context, t),
                            icon: const Icon(Icons.playlist_add),
                            label: const Text('В плейлист'),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Скачивание появится в части 2'),
                              ),
                            ),
                            icon: const Icon(Icons.download),
                            label: const Text('Скачать'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

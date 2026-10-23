import 'package:flutter/material.dart';
import '../screens/player_screen.dart';
import '../state/player.dart';
import '../state/settings.dart';
import '../theme/app_theme.dart';
import 'gen_cover.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final t = player.current;
        if (t == null) return const SizedBox.shrink();
        final cs = Theme.of(context).colorScheme;
        final progress = (player.position / t.durationSec).clamp(0.0, 1.0);
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PlayerScreen()),
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            decoration: BoxDecoration(
              color: panelColor(context),
              borderRadius: BorderRadius.circular(settings.radius),
              border: Border.all(color: cs.onSurface.withAlpha(30)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 4, 6),
                  child: Row(
                    children: [
                      GenCover(
                        seed: t.seed,
                        size: 44,
                        radius: settings.radius / 2,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                color: cs.onSurface.withAlpha(140),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          player.playing ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: player.toggle,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: player.next,
                      ),
                    ],
                  ),
                ),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 2,
                  backgroundColor: cs.onSurface.withAlpha(30),
                  color: cs.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

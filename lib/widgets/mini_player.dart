import 'package:flutter/material.dart';
import '../screens/player_screen.dart';
import '../state/player.dart';
import '../state/settings.dart';
import 'common.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final t = player.current;
        final cs = Theme.of(context).colorScheme;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          transitionBuilder: (child, anim) => SizeTransition(
            sizeFactor: anim,
            axisAlignment: -1,
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: t == null
              ? const SizedBox.shrink(key: ValueKey<String>('none'))
              : Padding(
                  key: const ValueKey<String>('mini'),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => openPlayer(context),
                    onVerticalDragEnd: (d) {
                      if ((d.primaryVelocity ?? 0) < -200) openPlayer(context);
                    },
                    child: GlassBox(
                      radius: 26,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 4, 6),
                            child: Row(
                              children: [
                                Hero(
                                  tag: 'cover',
                                  child: Cover(
                                    track: t,
                                    size: 46,
                                    radius: settings.radius / 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
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
                                Pressable(
                                  onTap: player.toggle,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: (player.loading || player.buffering)
                                        ? const SizedBox(
                                            width: 26,
                                            height: 26,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            transitionBuilder: (c, a) =>
                                                ScaleTransition(
                                              scale: a,
                                              child: c,
                                            ),
                                            child: Icon(
                                              player.playing
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                              key: ValueKey<bool>(
                                                player.playing,
                                              ),
                                              size: 30,
                                            ),
                                          ),
                                  ),
                                ),
                                Pressable(
                                  onTap: player.next,
                                  child: const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Icon(
                                      Icons.skip_next_rounded,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ValueListenableBuilder<Duration>(
                            valueListenable: player.pos,
                            builder: (context, p, _) {
                              final total = player.duration.inMilliseconds;
                              final v = total <= 0
                                  ? 0.0
                                  : (p.inMilliseconds / total).clamp(0.0, 1.0);
                              return LinearProgressIndicator(
                                value: v,
                                minHeight: 2,
                                backgroundColor: cs.onSurface.withAlpha(30),
                                color: cs.primary,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

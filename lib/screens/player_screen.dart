import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../models/track.dart';
import '../state/player.dart';
import '../state/settings.dart';
import '../widgets/common.dart';
import '../widgets/eq_sheet.dart';
import '../widgets/lyrics_view.dart';
import '../widgets/queue_sheet.dart';

void openPlayer(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => const PlayerScreen(),
      transitionsBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    ),
  );
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );
  bool _lyrics = false;

  @override
  void initState() {
    super.initState();
    player.addListener(_sync);
    settings.addListener(_sync);
    _sync();
  }

  void _sync() {
    if (!mounted) return;
    if (player.playing && settings.vinyl) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      if (_spin.isAnimating) _spin.stop();
    }
  }

  @override
  void dispose() {
    player.removeListener(_sync);
    settings.removeListener(_sync);
    _spin.dispose();
    super.dispose();
  }

  Widget _vinyl(Track t, ColorScheme cs) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: Cover(track: t, radius: 9999)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black.withAlpha(120), width: 10),
              ),
            ),
          ),
          FractionallySizedBox(
            widthFactor: 0.16,
            child: AspectRatio(
              aspectRatio: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.onSurface.withAlpha(90), width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _art(Track t, ColorScheme cs) {
    if (settings.vinyl) {
      return RotationTransition(
        turns: _spin,
        child: KeyedSubtree(key: ValueKey<String>('v-${t.id}'), child: _vinyl(t, cs)),
      );
    }
    return Cover(
      key: ValueKey<String>(t.id),
      track: t,
      radius: settings.radius * 1.4,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([player, settings]),
        builder: (context, _) {
          final t = player.current;
          if (t == null) return const SizedBox.shrink();
          final cs = Theme.of(context).colorScheme;
          final dim = cs.onSurface.withAlpha(120);
          final busy = player.loading || player.buffering;
          final repeatIcon = player.repeat == SdvigRepeat.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded;
          return Stack(
            fit: StackFit.expand,
            children: [
              _Backdrop(track: t),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 32,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'СЕЙЧАС ИГРАЕТ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        letterSpacing: 3,
                                        color: dim,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      t.source.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => showTrackMenu(context, t),
                              ),
                            ],
                          ),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              child: _lyrics
                                  ? KeyedSubtree(
                                      key: const ValueKey<String>('lyrics'),
                                      child: LyricsView(track: t),
                                    )
                                  : Center(
                                      key: const ValueKey<String>('art'),
                                      child: AnimatedScale(
                                        scale: player.playing ? 1 : 0.9,
                                        duration:
                                            const Duration(milliseconds: 450),
                                        curve: Curves.easeOutBack,
                                        child: Hero(
                                          tag: 'cover',
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 400,
                                            ),
                                            child: _art(t, cs),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Column(
                                    key: ValueKey<String>('meta-${t.id}'),
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        t.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: cs.onSurface.withAlpha(160),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Pressable(
                                onTap: () => player.toggleLike(t),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    transitionBuilder: (c, a) =>
                                        ScaleTransition(scale: a, child: c),
                                    child: Icon(
                                      player.isLiked(t)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      key: ValueKey<bool>(player.isLiked(t)),
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const SeekBar(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Pressable(
                                onTap: player.toggleShuffle,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Icon(
                                    Icons.shuffle_rounded,
                                    color: player.shuffle ? cs.onSurface : dim,
                                  ),
                                ),
                              ),
                              Pressable(
                                onTap: player.prev,
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.skip_previous_rounded,
                                    size: 42,
                                  ),
                                ),
                              ),
                              Pressable(
                                onTap: player.toggle,
                                scale: 0.9,
                                child: Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: cs.onSurface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: busy
                                        ? SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              color: cs.surface,
                                            ),
                                          )
                                        : AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 200,
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
                                              size: 44,
                                              color: cs.surface,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              Pressable(
                                onTap: player.next,
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.skip_next_rounded, size: 42),
                                ),
                              ),
                              Pressable(
                                onTap: player.toggleRepeat,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Icon(
                                    repeatIcon,
                                    color: player.repeat == SdvigRepeat.off
                                        ? dim
                                        : cs.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _Action(
                                icon: Icons.lyrics_rounded,
                                label: 'Текст',
                                on: _lyrics,
                                onTap: () => setState(() => _lyrics = !_lyrics),
                              ),
                              _Action(
                                icon: Icons.tune_rounded,
                                label: 'Звук',
                                onTap: () => showEqSheet(context),
                              ),
                              _Action(
                                icon: Icons.bedtime_rounded,
                                label: player.sleepAt == null ? 'Сон' : 'Сон ✓',
                                on: player.sleepAt != null,
                                onTap: () => showSleepSheet(context),
                              ),
                              _Action(
                                icon: Icons.queue_music_rounded,
                                label: 'Очередь',
                                onTap: () => showQueueSheet(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.on = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final col = on ? cs.onSurface : cs.onSurface.withAlpha(150);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on ? cs.onSurface.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: col),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: col)),
          ],
        ),
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final url = track.cover;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      child: Stack(
        key: ValueKey<String>('bd-${track.id}'),
        fit: StackFit.expand,
        children: [
          if (url != null)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
            ),
          Container(color: bg.withAlpha(dark ? 205 : 215)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bg.withAlpha(0), bg],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

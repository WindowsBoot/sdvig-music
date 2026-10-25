import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../models/track.dart';
import '../state/app_bus.dart';
import '../state/player.dart';
import '../state/settings.dart';
import '../theme/app_theme.dart';
import 'gen_cover.dart';

/// Нижний отступ списков под плавающую навигацию и мини-плеер.
const double kBottomPad = 200;

String fmtDur(Duration d) {
  final s = d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Плавное появление со сдвигом (для элементов списков).
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ms = 360 + (index > 12 ? 12 : index) * 45;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOutCubic,
      builder: (context, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

/// Кнопка с "пружинящим" нажатием.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.92,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Чёрно-белая "таблетка" вместо стандартных чипов.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Pressable(
      onTap: onTap,
      scale: 0.95,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? cs.onSurface : panelColor(context),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: cs.onSurface.withAlpha(selected ? 0 : 35),
          ),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? cs.surface : cs.onSurface,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

/// Обложка: картинка из сети с плавным появлением, иначе генеративная.
class Cover extends StatelessWidget {
  const Cover({super.key, required this.track, this.size, this.radius = 12});

  final Track track;
  final double? size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = track.cover;
    final inner = Stack(
      fit: StackFit.expand,
      children: [
        GenCover(seed: track.seed, radius: 0),
        if (url != null)
          Image.network(
            url,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (c, e, s) => const SizedBox.shrink(),
            frameBuilder: (context, child, frame, sync) => AnimatedOpacity(
              opacity: (frame == null && !sync) ? 0 : 1,
              duration: const Duration(milliseconds: 350),
              child: child,
            ),
          ),
      ],
    );
    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: inner,
    );
    if (size == null) return AspectRatio(aspectRatio: 1, child: clipped);
    return SizedBox(width: size, height: size, child: clipped);
  }
}

/// Полоса перемотки.
class SeekBar extends StatefulWidget {
  const SeekBar({super.key});

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final dim = Theme.of(context).colorScheme.onSurface.withAlpha(120);
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: player.pos,
          builder: (context, p, __) {
            final maxMs = player.duration.inMilliseconds <= 0
                ? 1.0
                : player.duration.inMilliseconds.toDouble();
            final cur =
                (_drag ?? p.inMilliseconds.toDouble()).clamp(0.0, maxMs).toDouble();
            return Column(
              children: [
                Slider(
                  value: cur,
                  max: maxMs,
                  onChangeStart: (v) => setState(() => _drag = v),
                  onChanged: (v) => setState(() => _drag = v),
                  onChangeEnd: (v) {
                    player.seek(Duration(milliseconds: v.round()));
                    setState(() => _drag = null);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        fmtDur(Duration(milliseconds: cur.round())),
                        style: TextStyle(fontSize: 12, color: dim),
                      ),
                      Text(
                        fmtDur(player.duration),
                        style: TextStyle(fontSize: 12, color: dim),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
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
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
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
                  toast('Добавлено в «$name»');
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
                  toast('Добавлено в «${n.trim()}»');
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// Меню трека (как в VK X: далее, в очередь, в плейлист, по исполнителю).
void showTrackMenu(BuildContext context, Track t) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ListenableBuilder(
        listenable: player,
        builder: (context, _) {
          final liked = player.isLiked(t);
          final cs = Theme.of(context).colorScheme;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: panelColor(context),
                  borderRadius: BorderRadius.circular(settings.radius),
                ),
                child: Row(
                  children: [
                    Cover(track: t, size: 56, radius: settings.radius / 2),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            t.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: cs.onSurface.withAlpha(140)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => player.toggleLike(t),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (c, a) =>
                            ScaleTransition(scale: a, child: c),
                        child: Icon(
                          liked ? Icons.favorite : Icons.favorite_border,
                          key: ValueKey<bool>(liked),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.playlist_play),
                title: const Text('Слушать следующим'),
                onTap: () {
                  Navigator.pop(ctx);
                  player.playNext(t);
                  toast('Добавлено следующим');
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_music),
                title: const Text('Добавить в конец очереди'),
                onTap: () {
                  Navigator.pop(ctx);
                  player.addToQueue(t);
                  toast('Добавлено в очередь');
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Добавить в плейлист'),
                onTap: () {
                  Navigator.pop(ctx);
                  showAddToPlaylist(context, t);
                },
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Поиск по исполнителю'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  searchRequest.value = t.artist;
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(
                  t.source.note.isEmpty
                      ? t.source.label
                      : '${t.source.label} · ${t.source.note}',
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}


/// Стеклянная панель с размытием фона.
class GlassBox extends StatelessWidget {
  const GlassBox({super.key, required this.child, this.radius = 28});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: (dark ? Colors.black : Colors.white).withAlpha(175),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: cs.onSurface.withAlpha(38)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Танцующие полоски: показывают, что трек играет.
class Bars extends StatefulWidget {
  const Bars({super.key, required this.active, this.size = 16});

  final bool active;
  final double size;

  @override
  State<Bars> createState() => _BarsState();
}

class _BarsState extends State<Bars> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant Bars old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final sz = widget.size;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * 2 * math.pi;
        final hs = <double>[
          0.5 + 0.5 * math.sin(t),
          0.5 + 0.5 * math.sin(t + 1.6),
          0.5 + 0.5 * math.sin(t + 3.1),
        ];
        return SizedBox(
          width: sz,
          height: sz,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final h in hs)
                Container(
                  width: sz / 4,
                  height: sz * (0.2 + 0.8 * (widget.active ? h : 0.0)),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Плавающая навигация со скользящим индикатором.
class FloatNav extends StatelessWidget {
  const FloatNav({super.key, required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const List<IconData> _icons = [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.library_music_rounded,
    Icons.tune_rounded,
  ];
  static const List<String> _labels = ['Главная', 'Поиск', 'Моё', 'Ещё'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlassBox(
      radius: 30,
      child: SizedBox(
        height: 64,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth / 4;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  left: index * w + 6,
                  top: 6,
                  bottom: 6,
                  width: w - 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.onSurface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < 4; i++)
                      Expanded(
                        child: Pressable(
                          onTap: () => onTap(i),
                          scale: 0.9,
                          child: SizedBox(
                            height: 64,
                            child: TweenAnimationBuilder<Color?>(
                              tween: ColorTween(
                                end: i == index
                                    ? cs.surface
                                    : cs.onSurface.withAlpha(170),
                              ),
                              duration: const Duration(milliseconds: 250),
                              builder: (context, col, _) => Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_icons[i], size: 24, color: col),
                                  const SizedBox(height: 2),
                                  Text(
                                    _labels[i],
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: col,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

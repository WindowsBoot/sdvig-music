import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/lyrics.dart';
import '../state/player.dart';

/// Текст песни: строки подсвечиваются по времени, нажатие на строку перематывает.
class LyricsView extends StatefulWidget {
  const LyricsView({super.key, required this.track});

  final Track track;

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  static const double _h = 64;
  final ScrollController _sc = ScrollController();
  late Future<Lyrics?> _f;
  String _forId = '';
  int _idx = -1;

  @override
  void initState() {
    super.initState();
    _forId = widget.track.id;
    _f = LyricsService.fetch(widget.track);
  }

  @override
  void didUpdateWidget(covariant LyricsView old) {
    super.didUpdateWidget(old);
    if (widget.track.id != _forId) {
      _forId = widget.track.id;
      _idx = -1;
      _f = LyricsService.fetch(widget.track);
    }
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<Lyrics?>(
      future: _f,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final ly = snap.data;
        if (ly == null) {
          return Center(
            child: Text(
              'Текст не найден',
              style: TextStyle(color: cs.onSurface.withAlpha(140)),
            ),
          );
        }
        if (!ly.synced) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            children: [
              for (final l in ly.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    l.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          );
        }
        return LayoutBuilder(
          builder: (context, c) {
            final pad = (c.maxHeight / 2 - _h / 2).clamp(0.0, 400.0);
            return ValueListenableBuilder<Duration>(
              valueListenable: player.pos,
              builder: (context, p, _) {
                final secs = p.inMilliseconds / 1000.0;
                var idx = -1;
                for (var i = 0; i < ly.lines.length; i++) {
                  if (ly.lines[i].t <= secs) {
                    idx = i;
                  } else {
                    break;
                  }
                }
                if (idx != _idx) {
                  _idx = idx;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_sc.hasClients || idx < 0) return;
                    final target = (idx * _h).clamp(
                      0.0,
                      _sc.position.maxScrollExtent,
                    );
                    _sc.animateTo(
                      target,
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                    );
                  });
                }
                return ListView.builder(
                  controller: _sc,
                  padding: EdgeInsets.symmetric(vertical: pad),
                  itemExtent: _h,
                  itemCount: ly.lines.length,
                  itemBuilder: (context, i) {
                    final on = i == idx;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => player.seek(
                        Duration(milliseconds: (ly.lines[i].t * 1000).round()),
                      ),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            fontSize: on ? 22 : 17,
                            fontWeight: on ? FontWeight.w900 : FontWeight.w600,
                            color: cs.onSurface.withAlpha(on ? 255 : 100),
                          ),
                          child: Text(
                            ly.lines[i].text,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

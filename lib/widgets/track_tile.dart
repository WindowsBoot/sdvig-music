import 'package:flutter/material.dart';
import '../models/track.dart';
import '../state/player.dart';
import '../state/settings.dart';
import 'common.dart';

class TrackTile extends StatelessWidget {
  const TrackTile({super.key, required this.track, required this.queue});

  final Track track;
  final List<Track> queue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final cur = player.current?.id == track.id;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Stack(
            alignment: Alignment.center,
            children: [
              Cover(track: track, size: 54, radius: settings.radius / 2),
              if (cur)
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(150),
                    borderRadius: BorderRadius.circular(settings.radius / 2),
                  ),
                  child: Center(
                    child: Bars(active: player.playing, size: 20),
                  ),
                ),
            ],
          ),
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: cur ? cs.primary : null,
            ),
          ),
          subtitle: Text(
            '${track.artist} · ${track.source.label}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => showTrackMenu(context, track),
          ),
          onTap: () => player.playFrom(queue, track),
        );
      },
    );
  }
}

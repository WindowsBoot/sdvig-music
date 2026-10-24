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
          leading: Cover(track: track, size: 52, radius: settings.radius / 2),
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: cur ? cs.primary : null,
            ),
          ),
          subtitle: Row(
            children: [
              if (cur && player.playing)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.graphic_eq, size: 14),
                ),
              Expanded(
                child: Text(
                  '${track.artist} · ${track.source.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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

import 'package:flutter/material.dart';
import '../state/player.dart';
import '../state/settings.dart';
import 'common.dart';

void showQueueSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, controller) => ListenableBuilder(
        listenable: player,
        builder: (context, _) {
          final cs = Theme.of(context).colorScheme;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'ДАЛЕЕ · ${player.queue.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: player.queue.length,
                  itemBuilder: (context, i) {
                    final t = player.queue[i];
                    final cur = i == player.index;
                    return ListTile(
                      leading: Cover(
                        track: t,
                        size: 46,
                        radius: settings.radius / 2,
                      ),
                      title: Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: cur ? cs.primary : null,
                        ),
                      ),
                      subtitle: Text(
                        t.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: cur
                          ? const Icon(Icons.graphic_eq)
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => player.removeFromQueue(i),
                            ),
                      onTap: () => player.jumpTo(i),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import '../models/track.dart';
import '../providers/music_provider.dart';
import '../state/player.dart';
import '../state/settings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/gen_cover.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _c = TextEditingController();
  final Set<MusicSource> _only = {};
  List<Track> _results = [];
  bool _loading = true;
  int _req = 0;
  String _off = '';

  @override
  void initState() {
    super.initState();
    settings.addListener(_onSettings);
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    settings.removeListener(_onSettings);
    _c.dispose();
    super.dispose();
  }

  void _onSettings() {
    final k = settings.disabledSources.toList()..sort();
    final s = k.join(',');
    if (s != _off) {
      _off = s;
      _run();
    }
  }

  Future<void> _run() async {
    final id = ++_req;
    final active = ProviderRegistry.all.where((p) =>
        !settings.disabledSources.contains(p.source.name) &&
        (_only.isEmpty || _only.contains(p.source)));
    final lists = await Future.wait(active.map((p) => p.search(_c.text)));
    final out = <Track>[];
    var i = 0;
    var more = true;
    while (more) {
      more = false;
      for (final l in lists) {
        if (i < l.length) {
          out.add(l[i]);
          more = true;
        }
      }
      i++;
    }
    if (!mounted || id != _req) return;
    setState(() {
      _results = out;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Text(
            'SDVIG',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _c,
            onChanged: (_) => _run(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Поиск по всем сервисам',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: panelColor(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(settings.radius),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final p in ProviderRegistry.all)
                if (!settings.disabledSources.contains(p.source.name))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(p.source.label),
                      selected: _only.contains(p.source),
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _only.add(p.source);
                          } else {
                            _only.remove(p.source);
                          }
                        });
                        _run();
                      },
                    ),
                  ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
                  ? Center(
                      child: Text(
                        'Ничего не найдено',
                        style: TextStyle(color: cs.onSurface.withAlpha(120)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final t = _results[i];
                        return ListTile(
                          leading: GenCover(
                            seed: t.seed,
                            size: 52,
                            radius: settings.radius / 2,
                          ),
                          title: Text(
                            t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${t.artist} · ${t.source.label}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.playlist_add),
                            onPressed: () => showAddToPlaylist(context, t),
                          ),
                          onTap: () => player.play(t, inQueue: _results),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

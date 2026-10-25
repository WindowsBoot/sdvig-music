import 'dart:async';
import 'package:flutter/material.dart';
import '../models/track.dart';
import '../providers/music_provider.dart';
import '../state/app_bus.dart';
import '../state/settings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/track_tile.dart';

const List<String> _popular = [
  'lofi',
  'phonk',
  'synthwave',
  'jazz',
  'hip hop',
  'ambient',
];

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _c = TextEditingController();
  final Set<MusicSource> _only = {};
  List<Track> _results = [];
  List<String> _failed = [];
  bool _loading = false;
  bool _searched = false;
  int _req = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    searchRequest.addListener(_onRequest);
  }

  @override
  void dispose() {
    searchRequest.removeListener(_onRequest);
    _debounce?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _onRequest() {
    final q = searchRequest.value;
    if (q == null) return;
    searchRequest.value = null;
    _c.text = q;
    _run();
  }

  void _onChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _run);
  }

  Future<void> _run() async {
    final q = _c.text.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _failed = [];
        _searched = false;
        _loading = false;
      });
      return;
    }
    final id = ++_req;
    setState(() {
      _loading = true;
      _searched = true;
    });
    final failed = <String>[];
    final providers = ProviderRegistry.live
        .where((p) =>
            p.enabled &&
            !settings.disabledSources.contains(p.source.name) &&
            (_only.isEmpty || _only.contains(p.source)))
        .toList();
    final lists = await Future.wait<List<Track>>(
      providers.map(
        (p) => p.search(q).catchError((Object _) {
          failed.add(p.source.label);
          return <Track>[];
        }),
      ),
    );
    final out = <Track>[];
    final seen = <String>{};
    // сначала каталоги (точные названия), затем прямые источники
    for (final catalogFirst in [true, false]) {
      final group = <List<Track>>[];
      for (var k = 0; k < providers.length; k++) {
        if (providers[k].isCatalog == catalogFirst) group.add(lists[k]);
      }
      for (var i = 0;; i++) {
        var any = false;
        for (final l in group) {
          if (i < l.length) {
            any = true;
            final t = l[i];
            final key =
                '${t.title.toLowerCase().trim()}|${t.artist.toLowerCase().trim()}';
            if (seen.add(key)) out.add(t);
          }
        }
        if (!any) break;
      }
    }
    if (!mounted || id != _req) return;
    settings.addQuery(q);
    setState(() {
      _results = out;
      _failed = failed;
      _loading = false;
    });
  }

  void _useQuery(String q) {
    _c.text = q;
    _run();
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
            'ПОИСК',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: TextField(
            controller: _c,
            onChanged: _onChanged,
            onSubmitted: (_) => _run(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Трек, исполнитель, альбом',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _c.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _c.clear();
                        _run();
                      },
                    ),
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
              for (final p in ProviderRegistry.live)
                if (p.enabled && !settings.disabledSources.contains(p.source.name))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Pill(
                      label: p.source.label,
                      selected: _only.contains(p.source),
                      onTap: () {
                        setState(() {
                          if (_only.contains(p.source)) {
                            _only.remove(p.source);
                          } else {
                            _only.add(p.source);
                          }
                        });
                        _run();
                      },
                    ),
                  ),
            ],
          ),
        ),
        if (_failed.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Text(
              'Не ответили: ${_failed.join(', ')}',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(120)),
            ),
          ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _body(context),
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!_searched) {
      return ListView(
        key: const ValueKey<String>('suggest'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, kBottomPad),
        children: [
          if (settings.recentQueries.isNotEmpty) ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'НЕДАВНИЕ ЗАПРОСЫ',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    settings.clearQueries();
                    setState(() {});
                  },
                ),
              ],
            ),
            for (final q in settings.recentQueries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history),
                title: Text(q),
                onTap: () => _useQuery(q),
              ),
            const SizedBox(height: 16),
          ],
          const Text(
            'ПОПУЛЯРНОЕ',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final q in _popular)
                Pill(label: q, selected: false, onTap: () => _useQuery(q)),
            ],
          ),
        ],
      );
    }
    if (_loading && _results.isEmpty) {
      return const Center(
        key: ValueKey<String>('loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (_results.isEmpty) {
      return Center(
        key: const ValueKey<String>('empty'),
        child: Text(
          'Ничего не найдено',
          style: TextStyle(color: cs.onSurface.withAlpha(120)),
        ),
      );
    }
    return ListView.builder(
      key: ValueKey<int>(_req),
      padding: const EdgeInsets.only(bottom: kBottomPad),
      itemCount: _results.length,
      itemBuilder: (context, i) => FadeSlideIn(
        index: i,
        child: TrackTile(track: _results[i], queue: _results),
      ),
    );
  }
}

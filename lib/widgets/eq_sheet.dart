import 'package:flutter/material.dart';
import '../state/player.dart';
import '../state/settings.dart';
import 'common.dart';

const Map<String, List<double>> _presets = {
  'Flat': [0, 0, 0, 0, 0],
  'Bass': [6, 4, 0, -1, -2],
  'Vocal': [-2, 0, 4, 3, -1],
  'Treble': [-2, -1, 0, 4, 6],
  'Loud': [5, 2, -1, 2, 5],
};

const List<String> _bands = ['60 Гц', '250 Гц', '1 кГц', '4 кГц', '16 кГц'];

bool _same(List<double> a, List<double> b) {
  for (var i = 0; i < a.length; i++) {
    if ((a[i] - b[i]).abs() > 0.05) return false;
  }
  return true;
}

class _H extends StatelessWidget {
  const _H(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 3,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

void showEqSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          final cs = Theme.of(context).colorScheme;
          final m = modeById(settings.mode);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _H('РЕЖИМ ЗВУКА'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in kModes)
                      Pill(
                        label: e.label,
                        selected: settings.mode == e.id,
                        onTap: () => settings.setMode(e.id),
                      ),
                  ],
                ),
                const _H('ЭКВАЛАЙЗЕР'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in _presets.entries)
                      Pill(
                        label: e.key,
                        selected: _same(settings.eq, e.value),
                        onTap: () => settings.setEq(e.value),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 190,
                  child: Row(
                    children: [
                      for (var i = 0; i < 5; i++)
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${settings.eq[i].round()}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Expanded(
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: Slider(
                                    value: settings.eq[i],
                                    min: -12,
                                    max: 12,
                                    onChanged: (v) => settings.setEqBand(i, v),
                                  ),
                                ),
                              ),
                              Text(
                                _bands[i],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withAlpha(140),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Text('Скорость'),
                    Expanded(
                      child: Slider(
                        value: settings.speed,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        onChanged: m.rate == null ? settings.setSpeed : null,
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        'x${(m.rate ?? settings.speed).toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Режимы и эквалайзер работают через mpv: на некоторых устройствах часть фильтров может быть недоступна.',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

void showSleepSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ListenableBuilder(
        listenable: player,
        builder: (context, _) {
          final at = player.sleepAt;
          final left = at == null
              ? null
              : at.difference(DateTime.now()).inMinutes + 1;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _H('ТАЙМЕР СНА'),
                if (left != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('Остановлю музыку примерно через $left мин.'),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in const [10, 15, 30, 45, 60, 90])
                      Pill(
                        label: '$m мин',
                        selected: false,
                        onTap: () {
                          player.setSleep(Duration(minutes: m));
                          Navigator.pop(ctx);
                        },
                      ),
                    Pill(
                      label: 'Выключить',
                      selected: at == null,
                      onTap: () {
                        player.setSleep(null);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

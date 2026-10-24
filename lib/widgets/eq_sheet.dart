import 'package:flutter/material.dart';
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
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'АУДИОЭФФЕКТЫ',
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Скорость'),
                    Expanded(
                      child: Slider(
                        value: settings.speed,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        onChanged: settings.setSpeed,
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        'x${settings.speed.toStringAsFixed(1)}',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Эквалайзер работает через mpv: на некоторых устройствах фильтры могут быть недоступны.',
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

import 'package:flutter/material.dart';
import '../models/track.dart';
import '../state/settings.dart';
import '../theme/app_theme.dart';
import '../widgets/gen_cover.dart';

const Map<String, List<double>> _presets = {
  'Flat': [0, 0, 0, 0, 0],
  'Bass': [6, 4, 0, -1, -2],
  'Vocal': [-2, 0, 4, 3, -1],
  'Treble': [-2, -1, 0, 4, 6],
  'Loud': [5, 2, -1, 2, 5],
};

const List<String> _bands = ['60 Гц', '250 Гц', '1 кГц', '4 кГц', '16 кГц'];

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            const Text(
              'НАСТРОЙКИ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 5,
              ),
            ),
            const _Label('Оформление'),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Чёрная'),
                  icon: Icon(Icons.dark_mode),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Белая'),
                  icon: Icon(Icons.light_mode),
                ),
              ],
              selected: {settings.dark},
              onSelectionChanged: (s) => settings.setDark(s.first),
            ),
            const SizedBox(height: 12),
            _SliderRow(
              label: 'Скругление',
              value: settings.radius,
              min: 0,
              max: 32,
              display: '${settings.radius.round()}',
              onChanged: settings.setRadius,
            ),
            _SliderRow(
              label: 'Яркость акцента',
              value: settings.accent,
              min: 0,
              max: 1,
              display: '${(settings.accent * 100).round()}%',
              onChanged: settings.setAccent,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final seed in [11, 24, 37])
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GenCover(
                      seed: seed,
                      size: 72,
                      radius: settings.radius,
                    ),
                  ),
              ],
            ),
            const _Label('Эквалайзер'),
            Wrap(
              spacing: 8,
              children: [
                for (final e in _presets.entries)
                  ActionChip(
                    label: Text(e.key),
                    onPressed: () => settings.setEq(e.value),
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
            Text(
              'Эквалайзер начнёт влиять на звук после подключения аудио-движка (часть 2).',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withAlpha(120),
              ),
            ),
            const _Label('Источники музыки'),
            for (final s in MusicSource.values.where((s) => s != MusicSource.local))
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.label),
                value: !settings.disabledSources.contains(s.name),
                onChanged: (_) => settings.toggleSource(s.name),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: panelColor(context),
                borderRadius: BorderRadius.circular(settings.radius),
              ),
              child: const Text(
                'SDVIG v0.1 · часть 1: интерфейс, демо-данные',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 40, child: Text(display, textAlign: TextAlign.right)),
      ],
    );
  }
}

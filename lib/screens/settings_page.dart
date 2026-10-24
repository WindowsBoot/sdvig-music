import 'package:flutter/material.dart';
import '../models/track.dart';
import '../state/settings.dart';
import '../theme/app_theme.dart';
import '../widgets/eq_sheet.dart';
import '../widgets/gen_cover.dart';

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
            const _Label('Звук'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tune_rounded),
              title: const Text('Эквалайзер и скорость'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showEqSheet(context),
            ),
            const _Label('Источники музыки'),
            for (final s in MusicSource.values.where((s) => s != MusicSource.local))
              if (s.live)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.label),
                  subtitle: Text(s.note),
                  value: !settings.disabledSources.contains(s.name),
                  onChanged: (_) => settings.toggleSource(s.name),
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: false,
                  title: Text(s.label),
                  trailing: const Text('скоро'),
                ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: panelColor(context),
                borderRadius: BorderRadius.circular(settings.radius),
              ),
              child: Text(
                'SDVIG v0.2 · реальный звук и поиск: Audius, YouTube, Apple Music, Deezer',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withAlpha(170),
                ),
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

import 'package:flutter/material.dart';
import '../models/track.dart';
import '../state/settings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/eq_sheet.dart';
import '../widgets/gen_cover.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _idC =
      TextEditingController(text: settings.spotifyId);
  late final TextEditingController _secC =
      TextEditingController(text: settings.spotifySecret);

  @override
  void dispose() {
    _idC.dispose();
    _secC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dim = cs.onSurface.withAlpha(130);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, kBottomPad),
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Винил в плеере'),
              subtitle: const Text('Круглая обложка вращается, пока играет трек'),
              value: settings.vinyl,
              onChanged: settings.setVinyl,
            ),
            const SizedBox(height: 4),
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
              title: const Text('Режимы, эквалайзер и скорость'),
              subtitle: Text(modeById(settings.mode).label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showEqSheet(context),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Автоплей'),
              subtitle: const Text('Когда очередь закончилась, подобрать продолжение'),
              value: settings.autoRadio,
              onChanged: settings.setAutoRadio,
            ),
            const _Label('Источники музыки'),
            Text(
              'Играют только полные версии. Каталоги (Deezer, Apple Music, Spotify) '
              'подсказывают точный трек, а звук берётся из YouTube, SoundCloud или Audius. '
              'Вход в аккаунты не нужен.',
              style: TextStyle(fontSize: 12, color: dim),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 12),
            Text(
              'Spotify (необязательно): бесплатные ключи с developer.spotify.com. '
              'Вход в аккаунт не нужен, ключи используются только для поиска по каталогу.',
              style: TextStyle(fontSize: 12, color: dim),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _idC,
              decoration: const InputDecoration(labelText: 'Spotify Client ID'),
              onChanged: (v) => settings.setSpotify(v, _secC.text),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _secC,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Spotify Client Secret',
              ),
              onChanged: (v) => settings.setSpotify(_idC.text, v),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: panelColor(context),
                borderRadius: BorderRadius.circular(settings.radius),
              ),
              child: Text(
                'SDVIG v0.3 · полные версии, тексты песен, режимы звука, таймер сна, статистика',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(170)),
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

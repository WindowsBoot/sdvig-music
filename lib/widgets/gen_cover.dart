import 'dart:math';
import 'package:flutter/material.dart';

/// Генеративная чёрно-белая обложка (без картинок из сети).
class GenCover extends StatelessWidget {
  const GenCover({super.key, required this.seed, this.size, this.radius = 12});

  final int seed;
  final double? size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        painter: _CoverPainter(seed, cs.surface, cs.onSurface),
        child: const SizedBox.expand(),
      ),
    );
    if (size == null) return AspectRatio(aspectRatio: 1, child: w);
    return SizedBox(width: size, height: size, child: w);
  }
}

class _CoverPainter extends CustomPainter {
  _CoverPainter(this.seed, this.ink, this.paper);

  final int seed;
  final Color ink;
  final Color paper;

  @override
  void paint(Canvas c, Size s) {
    final r = Random(seed);
    c.drawRect(Offset.zero & s, Paint()..color = paper);
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, s.width * 0.012);
    final fill = Paint()..color = ink;

    switch (seed % 3) {
      case 0:
        final center = Offset(
          s.width * (0.3 + 0.4 * r.nextDouble()),
          s.height * (0.3 + 0.4 * r.nextDouble()),
        );
        for (var i = 1; i <= 14; i++) {
          c.drawCircle(center, s.width * 0.07 * i, stroke);
        }
        break;
      case 1:
        final n = 10 + r.nextInt(14);
        final shift = s.width * (0.2 + 0.5 * r.nextDouble());
        for (var i = 0; i < n; i++) {
          final x = s.width * i / n;
          c.drawLine(Offset(x, 0), Offset(x + shift, s.height), stroke);
        }
        break;
      default:
        c.drawCircle(
          Offset(s.width * 0.5, s.height * 0.42),
          s.width * (0.18 + 0.1 * r.nextDouble()),
          fill,
        );
        final n = 6 + r.nextInt(6);
        for (var i = 0; i < n; i++) {
          final y = s.height * (0.62 + 0.34 * i / n);
          c.drawLine(Offset(s.width * 0.12, y), Offset(s.width * 0.88, y), stroke);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _CoverPainter old) =>
      old.seed != seed || old.ink != ink || old.paper != paper;
}

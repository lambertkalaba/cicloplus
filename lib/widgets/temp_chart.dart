import 'package:flutter/material.dart';

import '../models/day_entry.dart';
import '../theme/app_theme.dart';

/// Gráfica de temperatura basal + marcas de periodo a lo largo de los
/// últimos días con datos, dibujada con CustomPainter (equivalente al
/// SVG `buildChartSvg` del prototipo, sin depender de paquetes de
/// gráficas externos).
class TempChart extends StatelessWidget {
  final Map<String, DayEntry> data;
  final bool big;

  const TempChart({super.key, required this.data, this.big = false});

  @override
  Widget build(BuildContext context) {
    final keys = data.keys.toList()..sort();
    final last30 = keys.length > 30 ? keys.sublist(keys.length - 30) : keys;

    if (last30.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'Registra tu temperatura basal en algunos días para ver la gráfica.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      );
    }

    final height = big ? 220.0 : 150.0;
    final pointGap = big ? 46.0 : null;
    final double minWidth =
        big ? (34 * 2 + (last30.length - 1) * (pointGap ?? 0)).toDouble() : 320.0;

    final chart = CustomPaint(
      size: Size(minWidth < 320.0 ? 320.0 : minWidth, height),
      painter: _TempChartPainter(keys: last30, data: data, big: big),
    );

    if (big) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: chart,
      );
    }
    return SizedBox(width: double.infinity, height: height, child: chart);
  }
}

class _TempChartPainter extends CustomPainter {
  final List<String> keys;
  final Map<String, DayEntry> data;
  final bool big;

  _TempChartPainter({required this.keys, required this.data, required this.big});

  @override
  void paint(Canvas canvas, Size size) {
    final padding = big ? 34.0 : 24.0;
    final width = size.width;
    final height = size.height - 20; // deja espacio para etiquetas arriba

    final temps = <double>[];
    for (final k in keys) {
      final t = data[k]!.temp;
      if (t != null) temps.add(t);
    }
    final minT = temps.isNotEmpty ? (temps.reduce((a, b) => a < b ? a : b) - 0.2) : 36.0;
    final maxT = temps.isNotEmpty ? (temps.reduce((a, b) => a > b ? a : b) + 0.2) : 37.0;
    final range = (maxT - minT) == 0 ? 1.0 : (maxT - minT);
    final stepX = keys.length > 1 ? (width - padding * 2) / (keys.length - 1) : 0.0;

    // Línea base
    final basePaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(padding, height - padding),
      Offset(width - padding, height - padding),
      basePaint,
    );

    final points = <Offset>[];
    final pointTemps = <double>[];
    for (var i = 0; i < keys.length; i++) {
      final entry = data[keys[i]]!;
      if (entry.temp == null) continue;
      final x = padding + i * stepX;
      final y = height - padding - ((entry.temp! - minT) / range) * (height - padding * 2);
      points.add(Offset(x, y));
      pointTemps.add(entry.temp!);
    }

    if (points.length > 1) {
      final linePaint = Paint()
        ..color = const Color(0xFF7C3AED)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    final circlePaint = Paint()..color = const Color(0xFF7C3AED);
    final radius = big ? 3.5 : 2.5;
    for (final p in points) {
      canvas.drawCircle(p, radius, circlePaint);
    }

    // Etiquetas de temperatura
    final fontSize = big ? 10.0 : 8.0;
    for (var i = 0; i < points.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: pointTemps[i].toStringAsFixed(1),
          style: TextStyle(fontSize: fontSize, color: const Color(0xFF7C3AED)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(points[i].dx - tp.width / 2, points[i].dy - 7 - tp.height));
    }

    // Barras de periodo
    final periodPaint = Paint()..color = AppColors.primary;
    for (var i = 0; i < keys.length; i++) {
      final entry = data[keys[i]]!;
      if (entry.flow == 'none') continue;
      final x = padding + i * stepX - 3;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, height - padding + 4, 6, 6),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, periodPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TempChartPainter oldDelegate) {
    return oldDelegate.keys != keys || oldDelegate.data != data || oldDelegate.big != big;
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lluvia corta de pétalos rosas que cae sobre toda la pantalla (≈1,6 s) —
/// pequeño detalle de celebración al guardar el registro del día
/// (rediseño 2026-11). Se dibuja en el Overlay raíz y se quita sola; no
/// bloquea toques (IgnorePointer).
void showPetalBurst(BuildContext context) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _PetalBurst(onDone: () {
      if (entry.mounted) entry.remove();
    }),
  );
  overlay.insert(entry);
}

class _PetalBurst extends StatefulWidget {
  const _PetalBurst({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_PetalBurst> createState() => _PetalBurstState();
}

class _Petal {
  _Petal(math.Random r)
      : x = r.nextDouble(),
        delay = r.nextDouble() * 0.35,
        size = 10 + r.nextDouble() * 12,
        drift = (r.nextDouble() - 0.5) * 0.25,
        spin = (r.nextDouble() - 0.5) * 8,
        color = const [
          Color(0xFFF8A5C2),
          Color(0xFFF06595),
          Color(0xFFFFC9DE),
          Color(0xFFE64980),
        ][r.nextInt(4)];

  final double x;
  final double delay;
  final double size;
  final double drift;
  final double spin;
  final Color color;
}

class _PetalBurstState extends State<_PetalBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Petal> _petals;

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    _petals = List.generate(26, (_) => _Petal(r));
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..addStatusListener((st) {
        if (st == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _PetalPainter(_petals, _c.value),
        ),
      ),
    );
  }
}

class _PetalPainter extends CustomPainter {
  _PetalPainter(this.petals, this.t);
  final List<_Petal> petals;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in petals) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final y = -30 + (size.height + 60) * Curves.easeIn.transform(local);
      final x = size.width * (p.x + p.drift * local) + math.sin(local * 6 + p.x * 10) * 18;
      final opacity = local > 0.8 ? (1 - local) / 0.2 : 1.0;
      final paint = Paint()..color = p.color.withOpacity(opacity.clamp(0.0, 1.0) * 0.9);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * local);
      // Pétalo: óvalo alargado con una punta.
      final path = Path()
        ..moveTo(0, -p.size / 2)
        ..quadraticBezierTo(p.size / 2, -p.size / 6, 0, p.size / 2)
        ..quadraticBezierTo(-p.size / 2, -p.size / 6, 0, -p.size / 2)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalPainter old) => old.t != t;
}

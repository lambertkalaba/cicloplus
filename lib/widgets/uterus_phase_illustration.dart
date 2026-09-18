import 'package:flutter/material.dart';

/// Ilustración anatómica del aparato reproductor femenino (útero + trompas
/// + ovarios) para una fase del ciclo ('menstrual' | 'folicular' |
/// 'ovulacion' | 'lutea'), dibujada con [CustomPaint] — ver [UterusPainter]
/// para los detalles de estilo y la razón de dibujarla a mano en vez de usar
/// una imagen de stock.
///
/// Extraída de la tarjeta "Etapas del ciclo menstrual" de Revisión
/// (`_CycleStagesCard`/`_PhaseTile` en review_screen.dart) a un widget
/// compartido para poder reutilizar exactamente el mismo dibujo en la
/// tarjeta "Entiende tu cuerpo" de Estadísticas (petición de la usuaria de
/// que esa sección tuviera un esquema, no solo texto) — ambas pantallas
/// importan este archivo en vez de tener cada una su propia copia del
/// painter.
class UterusPhaseIllustration extends StatelessWidget {
  final String phaseKey;
  final Color primary;
  final double size;

  /// Cuando es `false`, el dibujo se atenúa con opacidad — se usa en la
  /// cuadrícula 2x2 de Revisión para las 3 fases que no son la actual.
  /// En cualquier otro contexto (como la tarjeta de Estadísticas) conviene
  /// dejarlo en `true` para que las 4 ilustraciones se vean con el mismo
  /// peso visual.
  final bool active;

  const UterusPhaseIllustration({
    super.key,
    required this.phaseKey,
    required this.primary,
    this.size = 64,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: UterusPainter(phaseKey: phaseKey, primary: primary, active: active)),
    );
  }
}

/// Dibuja una ilustración anatómica del aparato reproductor femenino
/// (útero + trompas + ovarios) imitando el estilo de referencia que
/// compartió el usuario (láminas tipo "Menstrual/Follicular/Ovulation/
/// Luteal phase" con útero rojo intenso degradado, trompas en espiral
/// cerrada y ovarios blancos de contorno grueso) — dibujado con
/// CustomPaint en vez de usar la imagen de stock original porque esa
/// imagen tiene derechos de autor y no puede incluirse en la app sin
/// licencia. Reutilizada en las 4 fases, cambiando solo el detalle
/// interior: gota de sangre (menstrual), folículo madurando (folicular),
/// óvulo liberándose con flecha de trayectoria (ovulación), o cuerpo
/// lúteo (lútea). Cuarta versión — rojo intenso sólido con degradado
/// marcado y trompas en espiral, más fiel a la referencia.
class UterusPainter extends CustomPainter {
  final String phaseKey;
  final Color primary;
  final bool active;

  const UterusPainter({required this.phaseKey, required this.primary, required this.active});

  static const _red = Color(0xFFE0334E);
  static const _redDark = Color(0xFFB91C3C);

  /// Construye el lado del cuerpo uterino como un Path simétrico: se
  /// dibuja el lado derecho con [sign] = 1 y se refleja con -1 para el
  /// izquierdo, garantizando simetría perfecta.
  Path _bodyPath(double w, double h) {
    final path = Path()..moveTo(w * 0.5, h * 0.965);
    void side(double sign) {
      path
        ..cubicTo(
          w * 0.5 + sign * w * 0.175, h * 0.965,
          w * 0.5 + sign * w * 0.245, h * 0.845,
          w * 0.5 + sign * w * 0.235, h * 0.66,
        )
        ..cubicTo(
          w * 0.5 + sign * w * 0.228, h * 0.50,
          w * 0.5 + sign * w * 0.165, h * 0.375,
          w * 0.5 + sign * w * 0.075, h * 0.325,
        )
        ..cubicTo(
          w * 0.5 + sign * w * 0.11, h * 0.29,
          w * 0.5 + sign * w * 0.11, h * 0.245,
          w * 0.5 + sign * w * 0.065, h * 0.205,
        );
    }

    side(1);
    path.cubicTo(w * 0.5 + w * 0.028, h * 0.185, w * 0.5 - w * 0.028, h * 0.185, w * 0.5 - w * 0.065, h * 0.205);
    path
      ..cubicTo(w * 0.5 - w * 0.11, h * 0.245, w * 0.5 - w * 0.11, h * 0.29, w * 0.5 - w * 0.075, h * 0.325)
      ..cubicTo(w * 0.5 - w * 0.165, h * 0.375, w * 0.5 - w * 0.228, h * 0.50, w * 0.5 - w * 0.235, h * 0.66)
      ..cubicTo(w * 0.5 - w * 0.245, h * 0.845, w * 0.5 - w * 0.175, h * 0.965, w * 0.5, h * 0.965)
      ..close();
    return path;
  }

  /// Trompa de Falopio en forma de espiral cerrada (rizo), como en la
  /// referencia — no una simple curva abierta, sino un bucle que se
  /// enrosca sobre sí mismo antes de llegar al ovario.
  Path _tubePath(double w, double h, double sign) {
    return Path()
      ..moveTo(w * 0.5 + sign * w * 0.075, h * 0.325)
      ..cubicTo(
        w * 0.5 + sign * w * 0.22, h * 0.27,
        w * 0.5 + sign * w * 0.24, h * 0.36,
        w * 0.5 + sign * w * 0.155, h * 0.385,
      )
      ..cubicTo(
        w * 0.5 + sign * w * 0.09, h * 0.40,
        w * 0.5 + sign * w * 0.10, h * 0.32,
        w * 0.5 + sign * w * 0.165, h * 0.30,
      )
      ..cubicTo(
        w * 0.5 + sign * w * 0.235, h * 0.28,
        w * 0.5 + sign * w * 0.27, h * 0.22,
        w * 0.5 + sign * w * 0.22, h * 0.175,
      );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Cuando la fase no está activa se atenúa todo el dibujo con opacidad
    // (en vez de cambiar de color), para conservar el rojo característico
    // de la referencia en ambos estados.
    final opacity = active ? 1.0 : 0.55;
    final center = Offset(w * 0.5, h * 0.55);

    final bodyFill = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.15, -0.35),
        radius: 1.05,
        colors: [_red.withOpacity(opacity * 0.95), _redDark.withOpacity(opacity)],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.55));

    final tubeStroke = Paint()
      ..color = _red.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.052
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // --- Trompas de Falopio: espirales cerradas simétricas.
    canvas.drawPath(_tubePath(w, h, 1), tubeStroke);
    canvas.drawPath(_tubePath(w, h, -1), tubeStroke);

    // --- Cuerpo uterino: silueta rellena con degradado rojo intenso, sin
    // contorno adicional (el propio degradado ya define el borde, como
    // en la referencia).
    final body = _bodyPath(w, h);
    canvas.drawPath(body, bodyFill);

    // Brillo superior-izquierdo suave para dar volumen (efecto glossy).
    canvas.save();
    canvas.clipPath(body);
    canvas.drawCircle(
      Offset(w * 0.36, h * 0.42),
      w * 0.22,
      Paint()..color = Colors.white.withOpacity(0.16 * opacity),
    );
    canvas.restore();

    // Cérvix: pequeño óvalo más oscuro en la base.
    final cervixRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.935), width: w * 0.13, height: h * 0.055);
    canvas.drawOval(cervixRect, Paint()..color = _redDark.withOpacity(opacity));

    // --- Ovarios: óvalos blancos sólidos con contorno rojo grueso, tal
    // como en la referencia (no tintados ni degradados).
    final ovaryLeft = Offset(w * 0.145, h * 0.145);
    final ovaryRight = Offset(w * 0.855, h * 0.145);
    final ovaryRadius = w * 0.095;
    final ovaryBorder = Paint()
      ..color = _red.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.034;
    for (final c in [ovaryLeft, ovaryRight]) {
      final ovalRect = Rect.fromCenter(center: c, width: ovaryRadius * 2, height: ovaryRadius * 1.75);
      canvas.drawOval(ovalRect, Paint()..color = Colors.white.withOpacity(opacity));
      canvas.drawOval(ovalRect, ovaryBorder);
    }

    // Detalle interior específico de cada fase.
    switch (phaseKey) {
      case 'menstrual':
        // Gota de sangre roja sólida en la esquina superior derecha,
        // como en la referencia (no gotas cayendo del cuerpo). Mantenida
        // bien dentro del lienzo (dx tope 0.85 + radio 0.06 = 0.91) para
        // que nunca se recorte contra el contenedor circular del sheet.
        final dropPaint = Paint()..color = _red.withOpacity(opacity);
        final dx = w * 0.85;
        final dropPath = Path()
          ..moveTo(dx, h * 0.04)
          ..cubicTo(dx - w * 0.06, h * 0.15, dx - w * 0.048, h * 0.25, dx, h * 0.27)
          ..cubicTo(dx + w * 0.048, h * 0.25, dx + w * 0.06, h * 0.15, dx, h * 0.04)
          ..close();
        canvas.drawPath(dropPath, dropPaint);
        canvas.drawCircle(Offset(dx - w * 0.014, h * 0.18), w * 0.011, Paint()..color = Colors.white.withOpacity(0.5 * opacity));
        break;
      case 'folicular':
        // Un folículo pequeño (punto dorado) madurando dentro del ovario
        // izquierdo.
        canvas.drawCircle(ovaryLeft, w * 0.032, Paint()..color = const Color(0xFFFFB84D).withOpacity(opacity));
        break;
      case 'ovulacion':
        // Óvulo maduro (punto dorado) en el ovario izquierdo, con una
        // flecha curva gruesa roja apuntando hacia el útero, como en la
        // referencia.
        canvas.drawCircle(ovaryLeft, w * 0.034, Paint()..color = const Color(0xFFFFB84D).withOpacity(opacity));
        final arrowPaint = Paint()
          ..color = _red.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.045
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        final arrowPath = Path()
          ..moveTo(w * 0.02, h * 0.30)
          ..quadraticBezierTo(w * 0.10, h * 0.46, w * 0.28, h * 0.50);
        canvas.drawPath(arrowPath, arrowPaint);
        final tip = Offset(w * 0.28, h * 0.50);
        final headPaint = Paint()..color = _red.withOpacity(opacity);
        final headPath = Path()
          ..moveTo(tip.dx + w * 0.045, tip.dy - h * 0.01)
          ..lineTo(tip.dx - w * 0.01, tip.dy - h * 0.058)
          ..lineTo(tip.dx - w * 0.035, tip.dy + h * 0.03)
          ..close();
        canvas.drawPath(headPath, headPaint);
        break;
      case 'lutea':
      default:
        // Cuerpo lúteo: punto dorado dentro del cuerpo central del
        // útero (progesterona).
        canvas.drawCircle(Offset(w * 0.5, h * 0.60), w * 0.038, Paint()..color = const Color(0xFFFFB84D).withOpacity(opacity));
        break;
    }
  }

  @override
  bool shouldRepaint(covariant UterusPainter oldDelegate) =>
      oldDelegate.phaseKey != phaseKey || oldDelegate.primary != primary || oldDelegate.active != active;
}

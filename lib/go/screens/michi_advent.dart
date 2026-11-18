import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../strings.dart';
import '../widgets/michi_sound.dart';
import '../widgets/ui.dart';

/// Calendario de Adviento de Michi (1-24 de diciembre). Cada día se abre una
/// puertita con un regalo de Michi y se cuelga un adorno en el árbol.
/// Los días pasados que no abriste se pueden abrir después (sin castigos).
class MichiAdvent {
  MichiAdvent._();

  static String get _key => 'michi_advent_${_season.year}';

  /// Diciembre de la temporada actual (en enero, el del año anterior).
  static DateTime get _season {
    final n = DateTime.now();
    return DateTime(n.month == 1 ? n.year - 1 : n.year, 12, 1);
  }

  /// Se ve del 15 de noviembre al 6 de enero.
  static bool get visible {
    final n = DateTime.now();
    return (n.month == 11 && n.day >= 15) || n.month == 12 || (n.month == 1 && n.day <= 6);
  }

  /// Último día que se puede abrir (0 = aún no ha empezado).
  static int get openUpTo {
    final n = DateTime.now();
    if (n.month == 12) return math.min(n.day, 24);
    if (n.month == 1 && n.day <= 6) return 24;
    return 0;
  }

  static int get daysToStart {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return _season.difference(today).inDays;
  }

  static Future<Set<int>> opened() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_key) ?? const []).map(int.tryParse).whereType<int>().toSet();
  }

  static Future<void> open(int day) async {
    final p = await SharedPreferences.getInstance();
    final s = (p.getStringList(_key) ?? <String>[]).toSet()..add('$day');
    await p.setStringList(_key, s.toList());
  }

  /// ¿Hay una puertita de hoy (o anterior) sin abrir?
  static Future<bool> hasNew() async {
    final up = openUpTo;
    if (up == 0) return false;
    final o = await opened();
    for (var d = 1; d <= up; d++) {
      if (!o.contains(d)) return true;
    }
    return false;
  }

  static const emojis = ['🧣', '☕', '⭐', '🧦', '🍪', '🎶', '💌', '❄️', '🕯️', '🎁', '🌙', '🍊', '📖', '🦌', '💧', '🌟', '🧸', '📸', '🍫', '🎄', '🤍', '🛁', '✨', '🎅'];

  static String gift(int day) {
    switch (day) {
      case 1:
        return tr('Una bufanda calentita para ti. ¡Diciembre empieza abrazadito!', 'A cosy scarf for you. December starts with a hug!');
      case 2:
        return tr('Un chocolate caliente imaginario. Siéntate cinco minutos y disfrútalo.', 'An imaginary hot chocolate. Sit down for five minutes and enjoy it.');
      case 3:
        return tr('Una estrella para recordarte que brillas incluso en los días grises.', 'A star to remind you that you shine even on grey days.');
      case 4:
        return tr('Calcetines gordos de lana: hoy toca pies calentitos y mantita.', 'Thick woolly socks: today is for warm feet and a blanket.');
      case 5:
        return tr('Galletas de jengibre recién hechas. Huele a hogar.', 'Freshly baked gingerbread biscuits. It smells like home.');
      case 6:
        return tr('Una canción: pon tu favorita y baila un minuto conmigo.', 'A song: put on your favourite and dance with me for a minute.');
      case 7:
        return tr('Una notita: estoy muy orgulloso de cómo te cuidas.', "A little note: I'm so proud of how you look after yourself.");
      case 8:
        return tr('Un copo de nieve único… como tú.', 'A one-of-a-kind snowflake… just like you.');
      case 9:
        return tr('Una vela para un ratito de calma. Respira hondo tres veces.', 'A candle for a moment of calm. Take three deep breaths.');
      case 10:
        return tr('Un abrazo gigante envuelto en papel brillante.', 'A giant hug wrapped in shiny paper.');
      case 11:
        return tr('Una noche de buen sueño. Hoy, a la cama un poquito antes.', 'A good night\'s sleep. Tonight, go to bed a little earlier.');
      case 12:
        return tr('Una mandarina: un poquito de vitamina y de sol.', 'A tangerine: a little bit of vitamins and sunshine.');
      case 13:
        return tr('Un cuento antes de dormir. ¿Leemos juntos un capítulo?', 'A bedtime story. Shall we read a chapter together?');
      case 14:
        return tr('Un reno mensajero que te trae ánimos para toda la semana.', 'A messenger reindeer bringing you encouragement for the whole week.');
      case 15:
        return tr('Un vaso de agua fresquita. ¡Hidratarse también es quererse!', 'A glass of cool water. Staying hydrated is self-love too!');
      case 16:
        return tr('Un deseo: piensa en algo bonito que quieras para el año nuevo.', 'A wish: think of something lovely you want for the new year.');
      case 17:
        return tr('Un peluche para achuchar en los días difíciles.', 'A cuddly toy to squeeze on difficult days.');
      case 18:
        return tr('Un recuerdo: busca una foto que te haga sonreír.', 'A memory: find a photo that makes you smile.');
      case 19:
        return tr('Un bombón. Date un capricho, te lo has ganado.', "A chocolate. Treat yourself, you've earned it.");
      case 20:
        return tr('Un adorno especial: ¡nuestro árbol ya casi está completo!', 'A special ornament: our tree is almost complete!');
      case 21:
        return tr('Un mensajito: llama o escribe a alguien a quien quieres.', 'A little message: call or text someone you love.');
      case 22:
        return tr('Un baño calentito o una ducha larga. Mimos para ti.', 'A warm bath or a long shower. Pampering for you.');
      case 23:
        return tr('Purpurina de alegría para mañana, que es Nochebuena.', "Sparkles of joy for tomorrow — it's Christmas Eve.");
      default:
        return tr('¡Feliz Nochebuena! Gracias por cuidarme todo el año. Te quiero mucho.', 'Merry Christmas Eve! Thank you for looking after me all year. I love you so much.');
    }
  }
}

class MichiAdventScreen extends StatefulWidget {
  const MichiAdventScreen({super.key});

  @override
  State<MichiAdventScreen> createState() => _MichiAdventScreenState();
}

class _MichiAdventScreenState extends State<MichiAdventScreen> with TickerProviderStateMixin {
  // Orden "desordenado" de las puertas, como en un calendario de verdad.
  static const _order = [7, 15, 2, 21, 11, 18, 4, 23, 9, 13, 1, 20, 16, 6, 24, 10, 3, 19, 12, 22, 8, 14, 5, 17];
  late final AnimationController _tw = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  late final AnimationController _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat(reverse: true);
  Set<int> _opened = {};
  int? _opening;
  late final AnimationController _door = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void initState() {
    super.initState();
    MichiAdvent.opened().then((o) {
      if (mounted) setState(() => _opened = o);
    });
  }

  @override
  void dispose() {
    _tw.dispose();
    _bob.dispose();
    _door.dispose();
    super.dispose();
  }

  Future<void> _tap(int day) async {
    final up = MichiAdvent.openUpTo;
    if (_opened.contains(day)) {
      _showGift(day);
      return;
    }
    if (day > up || _opening != null) {
      HapticFeedback.selectionClick();
      final msg = up == 0
          ? tr('Las puertitas se abren a partir del 1 de diciembre 🎄', 'The little doors open from 1 December 🎄')
          : tr('¡Todavía no! Esta puertita se abre el día {}.', 'Not yet! This little door opens on day {}.').replaceFirst('{}', '$day');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
      return;
    }
    HapticFeedback.mediumImpact();
    MichiSound.chime();
    setState(() => _opening = day);
    await _door.forward(from: 0);
    await MichiAdvent.open(day);
    if (!mounted) return;
    setState(() {
      _opened = {..._opened, day};
      _opening = null;
    });
    _showGift(day);
  }

  void _showGift(int day) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => _GiftCard(day: day),
      transitionBuilder: (_, a, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final up = MichiAdvent.openUpTo;
    final top = MediaQuery.of(context).padding.top;
    final subtitle = up == 0
        ? tr('Faltan {} días para abrir la primera puertita', '{} days until the first little door opens')
            .replaceFirst('{}', '${MichiAdvent.daysToStart}')
        : tr('{} de 24 adornos en el árbol', '{} of 24 ornaments on the tree').replaceFirst('{}', '${_opened.length}');
    return Scaffold(
      backgroundColor: const Color(0xFF13234A),
      body: Stack(children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0E1B3D), Color(0xFF26407A), Color(0xFF3A5A9E)],
              ),
            ),
          ),
        ),
        const Positioned.fill(child: IgnorePointer(child: SnowFall())),
        CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, top + 4, 16, 0),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.of(context).maybePop()),
                Expanded(
                  child: Text(tr('Adviento con Michi', 'Advent with Michi'),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(child: _treeArea()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text(subtitle,
                  textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFE7A3), fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 30),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.9),
              delegate: SliverChildBuilderDelegate((context, i) => _doorTile(_order[i], up), childCount: 24),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _treeArea() {
    return SizedBox(
      height: 270,
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        const treeW = 200.0, treeH = 230.0;
        final left = (w - treeW) / 2 - 30;
        return Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: left,
            top: 20,
            width: treeW,
            height: treeH,
            child: AnimatedBuilder(
              animation: _tw,
              builder: (_, __) => CustomPaint(painter: _TreePainter(_tw.value, _opened), child: _ornaments(treeW, treeH)),
            ),
          ),
          // Estrella de la punta: se enciende al abrir el día 24.
          Positioned(
            left: left + treeW / 2 - 18,
            top: 0,
            child: AnimatedBuilder(
              animation: _tw,
              builder: (_, __) {
                final on = _opened.contains(24);
                return Transform.scale(
                  scale: on ? 1 + 0.12 * _tw.value : 0.9,
                  child: Opacity(opacity: on ? 1 : 0.35, child: const Text('⭐', style: TextStyle(fontSize: 32))),
                );
              },
            ),
          ),
          Positioned(
            left: left + treeW - 6,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _bob,
              builder: (_, c) => Transform.translate(offset: Offset(0, -6 * Curves.easeInOut.transform(_bob.value)), child: c),
              child: const Img('michi_scarf', size: 112, fallback: Icons.pets_rounded),
            ),
          ),
        ]);
      }),
    );
  }

  /// Huecos de los adornos dentro del árbol (en fracciones del tamaño).
  static final _slots = () {
    final r = <Offset>[];
    const rows = [2, 3, 4, 4, 5, 6];
    for (var i = 0; i < rows.length; i++) {
      final y = 0.2 + i * 0.12;
      final half = 0.1 + i * 0.07;
      final n = rows[i];
      for (var k = 0; k < n; k++) {
        final x = 0.5 - half + (n == 1 ? half : 2 * half * k / (n - 1));
        r.add(Offset(x, y));
      }
    }
    return r;
  }();

  Widget _ornaments(double w, double h) {
    return Stack(clipBehavior: Clip.none, children: [
      for (final d in _opened)
        if (d >= 1 && d <= 24)
          Positioned(
            left: _slots[(d * 7) % 24].dx * w - 11,
            top: _slots[(d * 7) % 24].dy * h - 11,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, v, c) => Transform.scale(scale: v, child: c),
              child: Text(MichiAdvent.emojis[d - 1], style: const TextStyle(fontSize: 19)),
            ),
          ),
    ]);
  }

  Widget _doorTile(int day, int up) {
    final open = _opened.contains(day);
    final avail = day <= up;
    final today = day == up && DateTime.now().month == 12;
    const palette = [Color(0xFFD7263D), Color(0xFF1B8A5A), Color(0xFFE8A33D), Color(0xFF8E44AD)];
    final color = palette[day % palette.length];
    return GestureDetector(
      onTap: () => _tap(day),
      child: AnimatedBuilder(
        animation: Listenable.merge([_door, _tw]),
        builder: (context, _) {
          final swinging = _opening == day;
          final angle = swinging ? -Curves.easeInOutCubic.transform(_door.value) * 1.7 : (open ? -1.7 : 0.0);
          return Stack(clipBehavior: Clip.none, children: [
            // Lo que hay detrás de la puerta.
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6E0),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [if (today && !open) BoxShadow(color: const Color(0xFFFFD54F).withOpacity(0.4 + 0.4 * _tw.value), blurRadius: 14, spreadRadius: 1)],
                ),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(MichiAdvent.emojis[day - 1], style: const TextStyle(fontSize: 26)),
                    Text('$day', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF8A6D3B))),
                  ]),
                ),
              ),
            ),
            // La puertita.
            if (angle > -1.69)
              Positioned.fill(
                child: Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateY(angle),
                  child: Container(
                    decoration: BoxDecoration(
                      color: avail ? color : color.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFE7A3), width: 2),
                    ),
                    child: Stack(children: [
                      // Lazo dorado.
                      Center(child: Container(width: 6, color: const Color(0xFFFFE7A3).withOpacity(0.8))),
                      Center(child: Container(height: 6, color: const Color(0xFFFFE7A3).withOpacity(0.8))),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                          child: Text('$day', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color)),
                        ),
                      ),
                      if (!avail) const Positioned(right: 5, top: 4, child: Text('🔒', style: TextStyle(fontSize: 11))),
                      if (today) const Positioned(right: 4, top: 2, child: Text('✨', style: TextStyle(fontSize: 13))),
                    ]),
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

class _TreePainter extends CustomPainter {
  _TreePainter(this.t, this.opened);
  final double t;
  final Set<int> opened;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    // Tronco
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.44, h * 0.88, w * 0.12, h * 0.12), const Radius.circular(4)),
      Paint()..color = const Color(0xFF7A4A2A),
    );
    // Tres pisos de ramas
    final tiers = [
      [0.06, 0.38, 0.22],
      [0.24, 0.62, 0.34],
      [0.44, 0.9, 0.48],
    ];
    for (final tier in tiers) {
      final top = tier[0] * h, bottom = tier[1] * h, half = tier[2] * w;
      final path = Path()
        ..moveTo(w / 2, top)
        ..quadraticBezierTo(w / 2 + half * 0.5, (top + bottom) / 2, w / 2 + half, bottom)
        ..quadraticBezierTo(w / 2, bottom + 10, w / 2 - half, bottom)
        ..quadraticBezierTo(w / 2 - half * 0.5, (top + bottom) / 2, w / 2, top)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3FAE6A), Color(0xFF1B6E43)])
              .createShader(Rect.fromLTWH(0, top, w, bottom - top)),
      );
    }
    // Lucecitas que titilan
    final colors = [Color(0xFFFFE066), C.t(0xFFFF8FB1), Color(0xFF8FD3FF), Color(0xFFFFFFFF)];
    for (var i = 0; i < 18; i++) {
      final fy = 0.16 + (i % 6) * 0.13;
      final spread = 0.08 + (i % 6) * 0.065;
      final fx = 0.5 + (i.isEven ? -1 : 1) * spread * ((i * 37 % 10) / 10);
      final on = ((i + (t * 4).floor()) % 3) != 0;
      canvas.drawCircle(
        Offset(fx * w, fy * h),
        on ? 3.2 : 2.2,
        Paint()
          ..color = colors[i % colors.length].withOpacity(on ? 1 : 0.4)
          ..maskFilter = on ? const MaskFilter.blur(BlurStyle.normal, 2) : null,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TreePainter old) => old.t != t || old.opened.length != opened.length;
}

class _GiftCard extends StatelessWidget {
  const _GiftCard({required this.day});
  final int day;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
          Container(
            width: 310,
            margin: const EdgeInsets.only(top: 70),
            padding: const EdgeInsets.fromLTRB(22, 70, 22, 18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF2),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE8A33D), width: 3),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(tr('Día {} de diciembre', '{} December').replaceFirst('{}', '$day'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFD7263D))),
              const SizedBox(height: 6),
              Text(MichiAdvent.emojis[day - 1], style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 8),
              Text(MichiAdvent.gift(day),
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.4, fontWeight: FontWeight.w700, color: C.text)),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD7263D), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12)),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tr('¡Gracias, Michi! 💗', 'Thank you, Michi! 💗'), style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ]),
          ),
          Img(day == 24 ? 'michi_party' : (day.isEven ? 'michi_heart' : 'michi_scarf'), size: 130, fallback: Icons.pets_rounded),
          const Positioned.fill(child: IgnorePointer(child: SnowFall(count: 14, burst: true))),
        ]),
      ),
    );
  }
}

/// Nieve que cae suave (o una ráfaga de destellos si [burst]).
class SnowFall extends StatefulWidget {
  const SnowFall({super.key, this.count = 40, this.burst = false});
  final int count;
  final bool burst;

  @override
  State<SnowFall> createState() => _SnowFallState();
}

class _SnowFallState extends State<SnowFall> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(seconds: widget.burst ? 2 : 14));
  final _r = math.Random(3);
  late final _flakes = List.generate(widget.count, (_) => [_r.nextDouble(), _r.nextDouble(), 0.5 + _r.nextDouble(), _r.nextDouble() * 6.28]);

  @override
  void initState() {
    super.initState();
    widget.burst ? _c.forward() : _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(painter: _SnowPainter(_c.value, _flakes, widget.burst)),
    );
  }
}

class _SnowPainter extends CustomPainter {
  _SnowPainter(this.t, this.flakes, this.burst);
  final double t;
  final List<List<double>> flakes;
  final bool burst;

  @override
  void paint(Canvas canvas, Size s) {
    for (final f in flakes) {
      if (burst) {
        // Destellos que salen del centro hacia fuera.
        final ang = f[3];
        final dist = Curves.easeOut.transform(t) * (120 + 60 * f[2]);
        final p = Offset(s.width / 2 + math.cos(ang) * dist, 130 + math.sin(ang) * dist);
        canvas.drawCircle(p, 3 * f[2] * (1 - t) + 0.5,
            Paint()..color = (f[0] > 0.5 ? const Color(0xFFFFD54F) : C.t(0xFFFF8FB1)).withOpacity((1 - t).clamp(0.0, 1.0)));
        continue;
      }
      final y = ((t * f[2] + f[1]) % 1.0) * (s.height + 20) - 10;
      final x = f[0] * s.width + math.sin(t * 6.28 * 2 + f[3]) * 14;
      canvas.drawCircle(Offset(x, y), 1.5 + f[2] * 1.6, Paint()..color = Colors.white.withOpacity(0.55 + 0.3 * (f[2] - 0.5)));
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter old) => true;
}

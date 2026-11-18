import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../strings.dart';
import '../widgets/ui.dart';

/// Minijuego de 10 segundos: mueve a Michi y atrapa los peces que caen.
/// Los peces dorados valen 3 puntos.
class MichiGameScreen extends StatefulWidget {
  const MichiGameScreen({super.key});

  @override
  State<MichiGameScreen> createState() => _MichiGameScreenState();
}

class _Fish {
  double x; // 0..1
  double y; // 0..1
  final double speed; // fracción de alto por segundo
  final bool golden;
  final double wobble;
  _Fish(this.x, this.y, this.speed, this.golden, this.wobble);
}

class _Pop {
  final double x, y;
  final String text;
  double t = 0;
  _Pop(this.x, this.y, this.text);
}

class _MichiGameScreenState extends State<MichiGameScreen> with SingleTickerProviderStateMixin {
  static const _bestKey = 'michi_game_best';
  static const _duration = 10.0;

  late final Ticker _ticker = createTicker(_tick);
  final _rnd = math.Random();
  final _fish = <_Fish>[];
  final _pops = <_Pop>[];
  Duration _last = Duration.zero;
  double _time = 0;
  double _spawn = 0;
  double _catX = 0.5;
  int _score = 0;
  int _best = 0;
  bool _running = false;
  bool _finished = false;
  bool _newBest = false;
  double _happy = 0; // salto al atrapar

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _best = p.getInt(_bestKey) ?? 0);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _start() {
    HapticFeedback.mediumImpact();
    setState(() {
      _fish.clear();
      _pops.clear();
      _time = 0;
      _spawn = 0;
      _score = 0;
      _catX = 0.5;
      _running = true;
      _finished = false;
      _newBest = false;
      _last = Duration.zero;
    });
    _ticker.start();
  }

  Future<void> _end() async {
    _ticker.stop();
    HapticFeedback.heavyImpact();
    final p = await SharedPreferences.getInstance();
    if (_score > _best) {
      _best = _score;
      _newBest = true;
      await p.setInt(_bestKey, _score);
    }
    if (mounted) {
      setState(() {
        _running = false;
        _finished = true;
      });
    }
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero ? 0.016 : (now - _last).inMicroseconds / 1e6;
    _last = now;
    _time += dt;
    if (_time >= _duration) {
      _end();
      return;
    }
    // Cada vez caen más rápido y más seguido.
    final level = _time / _duration;
    _spawn -= dt;
    if (_spawn <= 0) {
      _spawn = 0.55 - level * 0.25;
      final golden = _rnd.nextDouble() < 0.12;
      _fish.add(_Fish(0.08 + _rnd.nextDouble() * 0.84, -0.06, 0.32 + level * 0.35 + _rnd.nextDouble() * 0.12, golden, _rnd.nextDouble() * 6));
    }
    for (final f in _fish) {
      f.y += f.speed * dt;
    }
    // Atrapar: el pez llega a la altura de Michi y está cerca.
    _fish.removeWhere((f) {
      if (f.y > 0.78 && f.y < 0.9 && (f.x - _catX).abs() < 0.13) {
        final pts = f.golden ? 3 : 1;
        _score += pts;
        _happy = 1;
        _pops.add(_Pop(f.x, f.y, '+$pts'));
        f.golden ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
        return true;
      }
      return f.y > 1.08;
    });
    for (final p in _pops) {
      p.t += dt;
    }
    _pops.removeWhere((p) => p.t > 0.8);
    _happy = math.max(0, _happy - dt * 3);
    setState(() {});
  }

  void _move(double dx, double width) {
    if (!_running) return;
    setState(() => _catX = (_catX + dx / width).clamp(0.08, 0.92));
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        const catSize = 112.0;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (d) => _move(d.delta.dx, w),
          onTapDown: (d) {
            if (!_running) return;
            setState(() => _catX = (d.localPosition.dx / w).clamp(0.08, 0.92));
          },
          child: Stack(
            children: [
              // Cielo rosa y hierba
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [C.t(0xFFFFD6EC), C.t(0xFFFCE4F1), Color(0xFFE6F6FF)],
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < 5; i++)
                Positioned(
                  left: ((i * 41) % 90) / 100 * w,
                  top: top + 90 + i * 70.0,
                  child: Opacity(opacity: 0.7, child: Text('☁️', style: TextStyle(fontSize: 34.0 + (i % 3) * 10))),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: h * 0.1,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF8FCB6B),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                ),
              ),
              // Peces
              for (final f in _fish)
                Positioned(
                  left: f.x * w - 26,
                  top: f.y * h,
                  child: Transform.rotate(
                    angle: math.sin(_time * 5 + f.wobble) * 0.25,
                    child: Img(f.golden ? 'game_fish_gold' : 'game_fish', size: 52, fallback: Icons.set_meal_rounded),
                  ),
                ),
              // Michi
              Positioned(
                left: _catX * w - catSize / 2,
                top: h * 0.8 - catSize / 2 - math.sin(_happy * math.pi) * 18,
                child: Img(_happy > 0 ? 'michi_return' : 'michi_happy', size: catSize, fallback: Icons.pets_rounded),
              ),
              // +1 / +3
              for (final p in _pops)
                Positioned(
                  left: p.x * w - 20,
                  top: p.y * h - 30 - p.t * 60,
                  child: Opacity(
                    opacity: (1 - p.t / 0.8).clamp(0.0, 1.0),
                    child: Text(p.text,
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: C.pinkDark, shadows: [Shadow(color: Colors.white, blurRadius: 6)])),
                  ),
                ),
              // Marcador
              Positioned(
                top: top + 8,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    _glass(IconButton(
                      icon: Icon(Icons.arrow_back_rounded, color: C.pinkDark),
                      onPressed: () => Navigator.of(context).maybePop(),
                    )),
                    const SizedBox(width: 8),
                    _glass(Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Text('🐟 $_score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: C.pinkDark)),
                    )),
                    const Spacer(),
                    _glass(Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Text('⏱️ ${math.max(0, (_duration - _time).ceil())}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: C.text)),
                    )),
                  ],
                ),
              ),
              if (_running)
                Positioned(
                  top: top + 66,
                  left: 20,
                  right: 20,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 1 - _time / _duration,
                      minHeight: 8,
                      backgroundColor: Colors.white70,
                      valueColor: AlwaysStoppedAnimation(C.pink),
                    ),
                  ),
                ),
              if (!_running) _overlay(),
            ],
          ),
        );
      }),
    );
  }

  Widget _overlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.35),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 34),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: C.pink.withOpacity(0.35), blurRadius: 30)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Img(_finished ? (_newBest ? 'michi_crown' : 'michi_heart') : 'game_fish', size: 110, fallback: Icons.pets_rounded),
              const SizedBox(height: 8),
              Text(
                _finished ? (_newBest ? tr('¡Nuevo récord!', 'New record!') : '🐟 $_score') : tr('Atrapa los peces', 'Catch the fish'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.pinkDark),
              ),
              const SizedBox(height: 6),
              Text(
                _finished
                    ? '${tr('Peces', 'Fish')}: $_score  ·  ${tr('Récord', 'Record')}: $_best'
                    : tr('Mueve a Michi y atrapa todos los peces que puedas en 10 segundos.', 'Move Michi and catch as many fish as you can in 10 seconds.'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text, height: 1.3),
              ),
              if (!_finished && _best > 0) ...[
                const SizedBox(height: 4),
                Text('${tr('Récord', 'Record')}: $_best', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: C.muted)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _start,
                  style: FilledButton.styleFrom(backgroundColor: C.pink, shape: const StadiumBorder()),
                  child: Text(_finished ? tr('Otra vez', 'Play again') : tr('¡Jugar!', 'Play!'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glass(Widget child) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
        ),
        child: child,
      );
}

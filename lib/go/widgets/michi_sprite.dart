import 'package:flutter/material.dart';

/// Animaciones de Michi fotograma a fotograma (dibujos hechos con ChatGPT
/// a partir del mismo gatito): andar, saltar y ronronear al acariciarlo.
/// Los fotogramas están en assets/go/anim/<nombre>_<n>.png, todos de
/// 400×400 con las patas en la misma línea de suelo y mirando a la derecha.
class MichiAnim {
  MichiAnim._();

  static const walk = 8;
  static const jump = 8;
  static const pet = 8;

  /// Fotogramas de cada animación (las de la casa: bailar, sentado vivo,
  /// tumbado, beber, jugar, dormir y meditar).
  static const counts = <String, int>{
    'walk': 8,
    'jump': 8,
    'pet': 8,
    'dance': 8,
    'idle': 8,
    'lie': 8,
    'drink': 8,
    'play': 8,
    'sleep': 4,
    'zen': 4,
    'gym': 8,
  };

  static int count(String name) => counts[name] ?? 8;

  /// Las de andar, saltar y ronronear son PNG; las de la casa, WebP (pesan menos).
  static String frame(String name, int i) =>
      const {'walk', 'jump', 'pet'}.contains(name) ? 'assets/go/anim/${name}_$i.png' : 'assets/go/anim/${name}_$i.webp';

  /// Altura (en fracción del tamaño) de cada fotograma del salto: el dibujo
  /// tiene las patas siempre en el suelo y aquí se le sube en el aire.
  static const jumpLift = [0.0, 0.0, 0.02, 0.16, 0.24, 0.15, 0.0, 0.0];

  /// Precarga los fotogramas para que no parpadee al empezar.
  static Future<void> precache(BuildContext context, [List<String> names = const ['walk', 'jump', 'pet']]) async {
    for (final n in names) {
      for (var i = 0; i < count(n); i++) {
        if (!context.mounted) return;
        try {
          await precacheImage(AssetImage(frame(n, i)), context);
        } catch (_) {}
      }
    }
  }
}

/// Un fotograma de Michi. [name] = walk | jump | pet, [index] se ajusta solo
/// al número de fotogramas.
class MichiFrame extends StatelessWidget {
  const MichiFrame(this.name, this.index, {super.key, this.size = 128, this.flip = false});

  final String name;
  final int index;
  final double size;
  final bool flip;

  int get _count => MichiAnim.count(name);

  @override
  Widget build(BuildContext context) {
    final i = index % _count;
    Widget img = Image.asset(
      MichiAnim.frame(name, i),
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
    if (flip) img = Transform.flip(flipX: true, child: img);
    return img;
  }
}

/// Michi animándose solo en bucle (por ejemplo, andando en el mapa).
class MichiLoop extends StatefulWidget {
  const MichiLoop(this.name, {super.key, this.size = 128, this.fps = 12, this.flip = false, this.playing = true});

  final String name;
  final double size;
  final double fps;
  final bool flip;
  final bool playing;

  @override
  State<MichiLoop> createState() => _MichiLoopState();
}

class _MichiLoopState extends State<MichiLoop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 1));

  int get _count => MichiAnim.count(widget.name);

  @override
  void initState() {
    super.initState();
    _c.duration = Duration(milliseconds: (1000 * _count / widget.fps).round());
    if (widget.playing) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant MichiLoop old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_c.isAnimating) _c.repeat();
    if (!widget.playing && _c.isAnimating) _c.stop();
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
      builder: (_, __) => MichiFrame(widget.name, (_c.value * _count).floor(), size: widget.size, flip: widget.flip),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/store.dart';
import '../strings.dart';
import '../widgets/michi_jokes.dart';
import '../widgets/michi_logic.dart';
import '../widgets/premium.dart' show Premium;
import '../widgets/michi_sound.dart';
import '../widgets/michi_sprite.dart';
import '../widgets/michi_voice.dart';
import '../widgets/ui.dart';
import 'michi_extras.dart';
import 'michi_more.dart';
import 'michi_wardrobe.dart';
import 'michi_world.dart';

/// Una habitación de la casa de Michi. Las posiciones van en fracciones del
/// dibujo (0..1): [spot] es dónde quedan sus patitas cuando ya está en su
/// sitio y [floor] el punto del suelo desde el que salta (sofá, cama...).
class MichiRoom {
  const MichiRoom({
    required this.id,
    required this.emoji,
    required this.es,
    required this.en,
    required this.spot,
    required this.anim,
    this.floor,
    this.size = 0.4,
    this.flip = false,
    this.fgTop,
    this.fps = 4,
  });

  final String id, emoji, es, en, anim;
  final Offset spot;
  final Offset? floor;
  final double size; // tamaño del dibujo de Michi (fracción del ancho)
  final bool flip; // mira a la izquierda
  final double? fgTop; // lo que queda delante de Michi (bañera, escritorio)
  final double fps;

  String get name => tr(es, en);
  String get bg => 'assets/go/house/bg_$id.jpg';
  String get photo => 'assets/go/house/room_$id.jpg';
}

class MichiHouse {
  MichiHouse._();

  static const rooms = <MichiRoom>[
    MichiRoom(id: 'salon', emoji: '🛋️', es: 'Salón', en: 'Living room', spot: Offset(0.46, 0.675), floor: Offset(0.6, 0.93), anim: 'lie', size: 0.48),
    MichiRoom(id: 'cocina', emoji: '🍳', es: 'Cocina', en: 'Kitchen', spot: Offset(0.65, 0.835), anim: 'drink', size: 0.42, fps: 5),
    MichiRoom(id: 'dormitorio', emoji: '🛏️', es: 'Dormitorio', en: 'Bedroom', spot: Offset(0.45, 0.6), floor: Offset(0.64, 0.94), anim: 'sleep', size: 0.42, fps: 1.5),
    MichiRoom(id: 'bano', emoji: '🛁', es: 'Baño', en: 'Bathroom', spot: Offset(0.55, 0.66), floor: Offset(0.4, 0.96), anim: 'idle', size: 0.4, fgTop: 0.5),
    MichiRoom(id: 'terraza', emoji: '🌇', es: 'Terraza', en: 'Terrace', spot: Offset(0.55, 0.86), anim: 'zen', size: 0.4, fps: 1.5),
    MichiRoom(id: 'juegos', emoji: '🧶', es: 'Cuarto de juegos', en: 'Playroom', spot: Offset(0.5, 0.86), anim: 'play', size: 0.4, flip: true, fps: 7),
    MichiRoom(id: 'estudio', emoji: '📔', es: 'Estudio', en: 'Study', spot: Offset(0.57, 0.88), floor: Offset(0.57, 1.25), anim: 'idle', size: 0.42, fgTop: 0.735),
    MichiRoom(id: 'gimnasio', emoji: '🏋️', es: 'Gimnasio', en: 'Gym', spot: Offset(0.5, 0.87), anim: 'gym', size: 0.44, fps: 3),
    MichiRoom(id: 'rincon', emoji: '🪟', es: 'Rincón de lectura', en: 'Reading nook', spot: Offset(0.64, 0.585), floor: Offset(0.55, 0.94), anim: 'lie', size: 0.4),
  ];

  static MichiRoom byId(String id) => rooms.firstWhere((r) => r.id == id, orElse: () => rooms.first);

  /// Dónde está Michi ahora mismo: depende de la hora, de si ya comió hoy y
  /// de tu fase.
  static String autoRoom() {
    final now = DateTime.now();
    final h = now.hour;
    final fed = MichiLogic.logged(dateOnly(now));
    if (h >= 22 || h < 7) return 'dormitorio';
    if (!fed) return 'cocina';
    if (MichiLogic.phaseKey == 'period' && h >= 18) return 'bano';
    if (h < 10) return 'cocina';
    if (h < 13) return 'juegos';
    if (h < 16) return 'salon';
    if (h < 17) return 'gimnasio';
    if (h < 18) return 'estudio';
    if (h < 20) return 'terraza';
    return 'rincon';
  }

  /// Lo que dice al llegar a cada habitación.
  static String phrase(String id) {
    final fed = MichiLogic.logged(dateOnly(DateTime.now()));
    return switch (id) {
      'salon' => tr('¡Qué blandito está el sofá! ¿Te sientas conmigo?', 'This sofa is so soft! Sit with me?'),
      'cocina' => fed
          ? tr('Bebo agüita... ¡tú también, que es importante! 💧', "I'm drinking water... you too, it's important! 💧")
          : tr('Mi cuenco está vacío... ¿registras tu día y me das de comer?', 'My bowl is empty... log your day and feed me?'),
      'dormitorio' => tr('Zzz... qué calentita está la cama...', 'Zzz... the bed is so warm...'),
      'bano' => tr('¡Baño de burbujas! Hoy toca mimarse 🫧', 'Bubble bath! Time to pamper ourselves 🫧'),
      'terraza' => tr('Respira conmigo... inspira... y suelta.', 'Breathe with me... in... and out.'),
      'juegos' => tr('¡Mira mi ovillo! ¿Jugamos un ratito?', 'Look at my yarn ball! Shall we play?'),
      'estudio' => tr('Estoy escribiendo en mi diario. ¿Escribes tú también?', "I'm writing in my diary. Will you write too?"),
      'rincon' => tr('Mi rincón favorito para mirar por la ventana.', 'My favourite spot to look out of the window.'),
      'gimnasio' => tr('¡Un poquito de ejercicio y a sentirse genial! 💪', 'A little exercise and you feel great! 💪'),
      _ => tr('¡Miau!', 'Meow!'),
    };
  }

  static String tapPhrase() {
    final l = [
      tr('¡Prrr! Me encantan tus mimos.', 'Purr! I love your cuddles.'),
      tr('¡Hola! ¿Qué tal tu día?', 'Hi! How is your day?'),
      tr('Eres mi persona favorita.', "You're my favourite person."),
      tr('¡Miau! Cosquillas no, ¡jijiji!', 'Meow! No tickles, hehe!'),
      tr('Cuídate mucho hoy, ¿vale?', 'Take good care of yourself today, ok?'),
      tr('¿Me das otra caricia?', 'Another cuddle, please?'),
    ];
    return l[math.Random().nextInt(l.length)];
  }
}

/// La casa de Michi a pantalla completa: Michi entra andando, salta al sofá o
/// a la cama y se queda vivo (mueve la cola, parpadea, bosteza, maúlla...).
/// Puedes ir a otras habitaciones y cada una abre algo de la app.
class MichiHouseScreen extends StatefulWidget {
  const MichiHouseScreen({super.key, required this.onFeed});
  final VoidCallback onFeed;

  @override
  State<MichiHouseScreen> createState() => _MichiHouseScreenState();
}

enum _Phase { hidden, walk, jump, act, dance, leave }

class _MichiHouseScreenState extends State<MichiHouseScreen> with TickerProviderStateMixin {
  late MichiRoom _room = MichiHouse.byId(MichiHouse.autoRoom());
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();
  late final AnimationController _move = AnimationController(vsync: this);
  late final AnimationController _hearts = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  late final AnimationController _bubble = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));

  _Phase _phase = _Phase.hidden;
  Offset _from = Offset.zero, _to = Offset.zero;
  double _arc = 0;
  bool _faceLeft = false;
  String? _say;
  int _run = 0; // para cancelar secuencias viejas
  bool _busy = false;
  bool get _fed => MichiLogic.logged(dateOnly(DateTime.now()));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MichiAnim.precache(context, const ['walk', 'jump', 'idle', 'lie', 'drink', 'sleep', 'zen', 'play', 'dance', 'gym']);
      for (final r in MichiHouse.rooms) {
        precacheImage(AssetImage(r.bg), context).catchError((_) {});
      }
      _enter(_room, speak: false);
    });
  }

  @override
  void dispose() {
    _run++;
    MichiVoice.stop();
    _clock.dispose();
    _move.dispose();
    _hearts.dispose();
    _bubble.dispose();
    super.dispose();
  }

  // ---------- movimientos ----------

  Future<bool> _go(Offset to, {required int ms, double arc = 0, required _Phase phase, required int run}) async {
    if (!mounted || run != _run) return false;
    final cur = _pos;
    setState(() {
      _phase = phase;
      _from = cur;
      _to = to;
      _arc = arc;
      _faceLeft = to.dx < cur.dx - 0.001;
    });
    _move.duration = Duration(milliseconds: ms);
    await _move.forward(from: 0);
    return mounted && run == _run;
  }

  Offset get _pos {
    if (_phase == _Phase.hidden) return _to;
    final t = _phase == _Phase.walk || _phase == _Phase.leave ? _move.value : Curves.easeInOut.transform(_move.value);
    return Offset.lerp(_from, _to, t)!;
  }

  int _walkMs(Offset a, Offset b) => ((a - b).distance / 0.32 * 1000).round().clamp(500, 3200);

  Future<void> _enter(MichiRoom r, {bool speak = true}) async {
    final run = ++_run;
    final ground = r.floor ?? r.spot;
    final start = Offset(-0.22, ground.dy > 1 ? r.spot.dy : ground.dy);
    setState(() {
      _room = r;
      _phase = _Phase.hidden;
      _to = start;
      _say = null;
    });
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted || run != _run) return;
    if (r.floor != null && r.floor!.dy > 1) {
      // Sube desde abajo (silla del estudio).
      setState(() {
        _to = r.floor!;
        _phase = _Phase.hidden;
      });
      if (!await _go(r.spot, ms: 750, arc: 0.12, phase: _Phase.jump, run: run)) return;
    } else {
      setState(() => _to = start);
      if (!await _go(Offset(ground.dx, ground.dy), ms: _walkMs(start, ground), phase: _Phase.walk, run: run)) return;
      if (r.floor != null) {
        if (!await _go(r.spot, ms: 750, arc: 0.16, phase: _Phase.jump, run: run)) return;
      }
    }
    setState(() {
      _phase = _Phase.act;
      _faceLeft = r.flip;
    });
    if (r.id == 'cocina' && !_fed) MichiSound.meow();
    _talk(MichiHouse.phrase(r.id), speak: speak);
  }

  /// Sale de la habitación (baja de un salto si estaba subido) y entra en otra.
  Future<void> _switch(MichiRoom r) async {
    if (_busy || r.id == _room.id) return;
    _busy = true;
    HapticFeedback.selectionClick();
    final run = ++_run;
    MichiVoice.stop();
    final cur = _room;
    if (_phase != _Phase.hidden) {
      if (cur.floor != null && cur.floor!.dy <= 1 && (_phase == _Phase.act)) {
        if (!await _go(cur.floor!, ms: 600, arc: 0.12, phase: _Phase.jump, run: run)) {
          _busy = false;
          return;
        }
      }
      final p = _pos;
      final out = Offset(1.25, p.dy);
      if (!await _go(out, ms: _walkMs(p, out), phase: _Phase.leave, run: run)) {
        _busy = false;
        return;
      }
    }
    _busy = false;
    if (!mounted) return;
    await _enter(r);
  }

  Future<void> _dance() async {
    if (_busy) return;
    if (_room.id != 'salon') {
      await _switch(MichiHouse.byId('salon'));
    }
    if (!mounted || _phase != _Phase.act) return;
    _busy = true;
    final run = ++_run;
    final floor = _room.floor ?? _room.spot;
    if (!await _go(Offset(0.52, floor.dy - 0.02), ms: 650, arc: 0.14, phase: _Phase.jump, run: run)) {
      _busy = false;
      return;
    }
    setState(() => _phase = _Phase.dance);
    HapticFeedback.mediumImpact();
    MichiSound.chime();
    _talk(tr('¡A bailar! ¡Mueve el esqueleto conmigo!', "Let's dance! Move with me!"));
    await Future.delayed(const Duration(milliseconds: 6500));
    if (!mounted || run != _run) {
      _busy = false;
      return;
    }
    await _go(_room.spot, ms: 750, arc: 0.16, phase: _Phase.jump, run: run);
    _busy = false;
    if (mounted && run == _run) {
      setState(() {
        _phase = _Phase.act;
        _faceLeft = _room.flip;
      });
      _talk(tr('¡Uf, qué divertido! 💃', 'Phew, that was fun! 💃'), speak: false);
    }
  }

  /// Entrenamiento de 30 segundos con Michi: él hace los ejercicios y te va
  /// diciendo qué hacer.
  bool _training = false;
  Future<void> _workout() async {
    if (_busy || _training) return;
    if (_room.id != 'gimnasio') await _switch(MichiHouse.byId('gimnasio'));
    if (!mounted || _phase != _Phase.act) return;
    setState(() => _training = true);
    HapticFeedback.mediumImpact();
    final steps = [
      tr('¡Vamos! Brazos arriba y abajo 💪', "Let's go! Arms up and down 💪"),
      tr('Respira hondo mientras te mueves', 'Breathe deeply while you move'),
      tr('¡Saltitos suaves! Tú puedes', 'Little jumps! You can do it'),
      tr('Estira bien los brazos hacia el cielo', 'Stretch your arms up to the sky'),
      tr('¡Casi está! Un poquito más', 'Almost there! A little more'),
      tr('¡Genial! Ahora bebe un poco de agua 💧', 'Great! Now drink a little water 💧'),
    ];
    for (var i = 0; i < steps.length; i++) {
      if (!mounted || _room.id != 'gimnasio') break;
      _talk(steps[i]);
      await Future.delayed(const Duration(seconds: 5));
    }
    if (mounted) setState(() => _training = false);
    MichiSound.chime();
  }

  void _pet() {
    if (_phase != _Phase.act && _phase != _Phase.dance) return;
    HapticFeedback.lightImpact();
    MichiSound.purr();
    _hearts.forward(from: 0);
    _talk(MichiHouse.tapPhrase());
  }

  Future<void> _talk(String text, {bool speak = true}) async {
    if (!mounted) return;
    setState(() => _say = text);
    _bubble.forward(from: 0);
    if (speak) MichiVoice.say(text);
    final mine = text;
    await Future.delayed(const Duration(milliseconds: 4200));
    if (mounted && _say == mine) {
      await _bubble.reverse();
      if (mounted && _say == mine) setState(() => _say = null);
    }
  }

  // ---------- dibujo ----------

  (String, int, double) _frame() {
    final ms = _clock.lastElapsedDuration?.inMilliseconds ?? 0;
    int loop(String n, double fps) => (ms * fps / 1000).floor() % MichiAnim.count(n);
    switch (_phase) {
      case _Phase.walk:
      case _Phase.leave:
        return ('walk', loop('walk', 12), 0);
      case _Phase.jump:
        final i = (_move.value * MichiAnim.jump).floor().clamp(0, MichiAnim.jump - 1);
        return ('jump', i, 0);
      case _Phase.dance:
        final i = loop('dance', 7);
        return ('dance', i, i == 4 ? 0.06 : 0);
      case _Phase.act:
      case _Phase.hidden:
        final a = (_room.id == 'cocina' && !_fed) ? 'idle' : _room.anim;
        return (a, loop(a, a == _room.anim ? _room.fps : 4), 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: C.t(0xFFFCE4F1),
      body: ListView(
        padding: EdgeInsets.fromLTRB(12, top + 8, 12, 24 + MediaQuery.of(context).padding.bottom),
        children: [
          _header(),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, c) => _scene(c.maxWidth)),
          const SizedBox(height: 10),
          _roomStrip(),
          const SizedBox(height: 10),
          _panel(),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(children: [
      _round(Icon(Icons.arrow_back_rounded, color: C.pinkDark), () => Navigator.of(context).maybePop()),
      const SizedBox(width: 8),
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Text(tr('La casa de Michi', "Michi's house"),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.pinkDark)),
        ),
      ),
      const SizedBox(width: 8),
      // Cambiar al mundo de las nubes (el mapa de aventura).
      _round(const Text('☁️', style: TextStyle(fontSize: 18)), () {
        final s = AppStore.instance;
        s.michiScene = 'map';
        s.commit();
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MichiWorldScreen(onFeed: widget.onFeed)));
      }),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Text('🔥 ${MichiLogic.streak}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFB7791F))),
      ),
    ]);
  }

  Widget _round(Widget child, VoidCallback onTap) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: 44, height: 44, child: Center(child: child))),
      );

  Widget _scene(double w) {
    final r = _room;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        width: w,
        height: w,
        child: AnimatedBuilder(
          animation: Listenable.merge([_clock, _move, _hearts, _bubble]),
          builder: (context, _) {
            final (name, idx, lift) = _frame();
            final p = _pos;
            final arc = (_phase == _Phase.jump) ? math.sin(_move.value * math.pi) * _arc : 0.0;
            // Los fotogramas de andar y saltar tienen el gato algo más pequeño
            // dentro del dibujo: se agrandan para que no "encoja" al moverse.
            final moving = name == 'walk' || name == 'jump';
            final size = r.size * w * (moving ? 1.2 : (name == 'dance' ? 0.92 : 1.0));
            final foot = moving ? 376 / 400 : 386 / 400;
            final ms = _clock.lastElapsedDuration?.inMilliseconds ?? 0;
            final breathe = _phase == _Phase.act ? 1 + math.sin(ms / 1000 * 2 * math.pi / 2.6) * 0.012 : 1.0;
            final petBob = _hearts.isAnimating ? -math.sin(_hearts.value * math.pi) * 0.02 : 0.0;
            final left = p.dx * w - size / 2;
            final topY = (p.dy - arc - lift + petBob) * w - size * foot;
            final behind = r.fgTop != null && (_phase == _Phase.act || (_phase == _Phase.jump && _move.value > 0.55 && _to == r.spot));
            final flip = _phase == _Phase.act ? r.flip : _faceLeft;
            return Stack(clipBehavior: Clip.hardEdge, children: [
              Positioned.fill(child: Image.asset(r.bg, fit: BoxFit.cover, gaplessPlayback: true)),
              if (_phase == _Phase.dance) ..._notes(w, ms),
              if (_phase != _Phase.hidden)
                Positioned(
                  left: left,
                  top: topY,
                  width: size,
                  height: size,
                  child: GestureDetector(
                    onTap: _pet,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.diagonal3Values(1, breathe, 1),
                      child: MichiFrame(name, idx, size: size, flip: flip),
                    ),
                  ),
                ),
              // Lo que tapa a Michi (borde de la bañera, mesa del estudio).
              if (behind)
                Positioned(
                  left: 0,
                  top: r.fgTop! * w,
                  width: w,
                  height: w * (1 - r.fgTop!),
                  child: IgnorePointer(
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.bottomCenter,
                        minHeight: w,
                        maxHeight: w,
                        minWidth: w,
                        maxWidth: w,
                        child: Image.asset(r.bg, width: w, height: w, fit: BoxFit.cover, gaplessPlayback: true),
                      ),
                    ),
                  ),
                ),
              if (_hearts.isAnimating)
                for (var i = 0; i < 3; i++)
                  Positioned(
                    left: p.dx * w - 30 + i * 22,
                    top: (p.dy - arc) * w - size * 0.85 - _hearts.value * (40 + i * 10),
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: (1 - _hearts.value).clamp(0.0, 1.0),
                        child: Text(const ['💗', '💕', '💖'][i], style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  ),
              if (_say != null) _speech(w, p, size),
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(14)),
                  child: Text('${r.emoji} ${r.name}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: C.pinkDark)),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  List<Widget> _notes(double w, int ms) {
    const notes = ['🎵', '🎶', '💗', '🎵', '✨'];
    return [
      for (var i = 0; i < notes.length; i++)
        Builder(builder: (_) {
          final t = ((ms / 1800) + i / notes.length) % 1.0;
          return Positioned(
            left: w * (0.18 + 0.16 * i) + math.sin(t * math.pi * 2) * 10,
            top: w * (0.62 - t * 0.45),
            child: IgnorePointer(child: Opacity(opacity: math.sin(t * math.pi), child: Text(notes[i], style: const TextStyle(fontSize: 24)))),
          );
        }),
    ];
  }

  Widget _speech(double w, Offset p, double size) {
    final bw = w * 0.62;
    var left = p.dx * w - bw / 2;
    left = left.clamp(8.0, w - bw - 8);
    final top = (p.dy * w - size * 0.92 - 64).clamp(44.0, w - 120);
    return Positioned(
      left: left,
      width: bw,
      top: top,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _bubble,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _bubble, curve: Curves.easeOutBack),
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Text(_say ?? '',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: C.text, height: 1.25)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roomStrip() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Text('🏠'),
              label: Text(tr('Toda la casa', 'Whole house'), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
              backgroundColor: C.pink,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: _showHouse,
            ),
          ),
          for (final r in MichiHouse.rooms)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: r.id == _room.id,
                showCheckmark: false,
                avatar: Text(r.emoji),
                label: Text(r.name, style: TextStyle(fontWeight: FontWeight.w800, color: r.id == _room.id ? Colors.white : C.pinkDark)),
                selectedColor: C.pinkDark,
                backgroundColor: Colors.white,
                side: BorderSide(color: C.pinkLine),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onSelected: (_) => _switch(r),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showHouse() async {
    final picked = await showModalBottomSheet<MichiRoom>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: C.t(0xFFFFF4F8),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.82,
          child: Column(children: [
            Text(tr('La casa de Michi', "Michi's house"), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: C.pinkDark)),
            const SizedBox(height: 4),
            Text(tr('Toca una habitación para ir con Michi.', 'Tap a room to go there with Michi.'),
                style: const TextStyle(fontSize: 13, color: C.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.86,
                children: [
                  for (final r in MichiHouse.rooms)
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(r),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: r.id == _room.id ? C.pink : C.pinkLine, width: r.id == _room.id ? 3 : 1),
                        ),
                        padding: const EdgeInsets.all(5),
                        child: Column(children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(r.photo, fit: BoxFit.cover, width: double.infinity),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text('${r.emoji} ${r.name}${r.id == _room.id ? ' · 🐾' : ''}',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: C.pinkDark)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
    if (picked != null) _switch(picked);
  }

  /// Lo que se puede hacer en cada habitación.
  List<(String, String, VoidCallback)> get _actions {
    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w)).then((_) {
          if (mounted) setState(() {});
        });
    final feed = ('🐟', tr('Darle de comer', 'Feed Michi'), () {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
      widget.onFeed();
    });
    return switch (_room.id) {
      'salon' => [('💃', tr('¡Baila, Michi!', 'Dance, Michi!'), _dance)],
      'cocina' => [if (!_fed) feed, ('💃', tr('¡Baila, Michi!', 'Dance, Michi!'), _dance)],
      'dormitorio' => [('💌', tr('Cartas de Michi', "Michi's letters"), () => push(const MichiLetterScreen()))],
      'bano' => [
        if (AppStore.instance.pregnant)
          ('🌬️', tr('Respira conmigo', 'Breathe with me'), () => push(const MichiBreatheScreen()))
        else
          ('🫖', tr('Mi kit para cuidarte', 'My self-care kit'), () => showMichiPeriodKit(context)),
      ],
      'terraza' => [('🌬️', tr('Respira conmigo', 'Breathe with me'), () => push(const MichiBreatheScreen()))],
      'juegos' => [('🎯', '${tr('Retos', 'Challenges')}${Premium.active ? '' : ' 👑'}', () => push(const MichiChallengeScreen())), ('🏅', '${tr('Logros', 'Badges')}${Premium.active ? '' : ' 👑'}', () => push(const MichiBadgesScreen()))],
      'estudio' => [('📔', tr('Diario con Michi', 'Diary with Michi'), () => push(const MichiDiaryScreen()))],
      'rincon' => [('👗', tr('Armario', 'Wardrobe'), () => push(const MichiWardrobeScreen()))],
      'gimnasio' => [('💪', tr('Haz ejercicio conmigo', 'Work out with me'), _workout)],
      _ => const [],
    };
  }

  Widget _panel() {
    final acts = _actions;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: C.t(0xFF8E1B47).withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          _fed ? tr('¡Michi está feliz! 🐟', 'Michi is happy! 🐟') : tr('Michi te espera 🐾', 'Michi is waiting 🐾'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.pinkDark),
        ),
        const SizedBox(height: 4),
        Text(tr('Tócalo para darle mimos. Cambia de habitación y Michi irá contigo.', 'Tap him to give him cuddles. Change rooms and Michi will follow you.'),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.text)),
        const SizedBox(height: 12),
        for (final a in acts) ...[
          SizedBox(
            height: 46,
            child: FilledButton.icon(
              onPressed: a.$3,
              style: FilledButton.styleFrom(backgroundColor: C.pink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23))),
              icon: Text(a.$1, style: const TextStyle(fontSize: 18)),
              label: Text(a.$2, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _pet,
                style: OutlinedButton.styleFrom(
                  foregroundColor: C.pinkDark,
                  side: BorderSide(color: C.pink, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                icon: const Text('🤗'),
                label: Text(tr('Acariciar', 'Pet'), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => MichiJokes.show(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: C.pinkDark,
                  side: BorderSide(color: C.pink, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                icon: const Text('😹'),
                label: Text(tr('Chiste', 'Joke'), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

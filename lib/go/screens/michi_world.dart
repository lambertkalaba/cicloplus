import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/store.dart';
import '../strings.dart';
import '../widgets/michi_logic.dart';
import '../widgets/michi_sound.dart';
import '../widgets/michi_sprite.dart';
import '../widgets/michi_jokes.dart';
import '../widgets/ui.dart';
import 'michi_album.dart';
import 'michi_game.dart';
import 'michi_advent.dart';
import 'michi_extras.dart';
import 'michi_more.dart';
import 'michi_stories.dart';
import 'michi_house.dart';
import 'michi_wardrobe.dart';

/// "El mundo de Michi": mapas de aventura a pantalla completa (ilustraciones
/// de ChatGPT). Cada día seguido registrando, Michi avanza un paso por el
/// camino. Mundo 1: de su casita al castillo de las nubes (días 1-30).
/// Mundo 2: del arcoíris al palacio de la luna (días 31-60). En cada parada
/// gana un premio y una postal para su álbum.
class MichiWorldScreen extends StatefulWidget {
  final VoidCallback onFeed;
  const MichiWorldScreen({super.key, required this.onFeed});

  @override
  State<MichiWorldScreen> createState() => _MichiWorldScreenState();
}

class _World {
  final String map;
  final double aspect; // alto / ancho
  final List<int> bounds; // pasos locales de cada parada (0..30)
  final List<List<Offset>> segments;
  final Color ground;
  const _World(this.map, this.aspect, this.bounds, this.segments, this.ground);
}

class _MichiWorldScreenState extends State<MichiWorldScreen> with TickerProviderStateMixin {
  static const perWorld = 30;
  static const total = 60;
  static const _seenKey = 'michi_world_seen_step';
  bool _panelOpen = true;

  static const _worlds = <_World>[
    _World('michi_map.jpg', 1102 / 622, [0, 3, 7, 14, 30], [
      [Offset(0.37, 0.907), Offset(0.53, 0.907), Offset(0.675, 0.871), Offset(0.756, 0.817), Offset(0.723, 0.762), Offset(0.611, 0.726), Offset(0.466, 0.708), Offset(0.37, 0.672), Offset(0.386, 0.626), Offset(0.498, 0.599), Offset(0.643, 0.567)],
      [Offset(0.643, 0.567), Offset(0.69, 0.535), Offset(0.675, 0.499), Offset(0.595, 0.467), Offset(0.482, 0.44)],
      [Offset(0.482, 0.44), Offset(0.354, 0.427), Offset(0.257, 0.408), Offset(0.209, 0.381), Offset(0.273, 0.358), Offset(0.386, 0.349), Offset(0.482, 0.343)],
      [Offset(0.482, 0.343), Offset(0.579, 0.327), Offset(0.675, 0.3), Offset(0.756, 0.272), Offset(0.764, 0.236), Offset(0.707, 0.209), Offset(0.627, 0.186), Offset(0.611, 0.163), Offset(0.659, 0.136)],
    ], Color(0xFF8FCB6B)),
    _World('michi_map2.jpg', 1045 / 584, [0, 5, 12, 20, 30], [
      [Offset(0.514, 0.833), Offset(0.531, 0.78), Offset(0.445, 0.737), Offset(0.308, 0.708), Offset(0.231, 0.67), Offset(0.231, 0.627), Offset(0.308, 0.595), Offset(0.445, 0.576), Offset(0.582, 0.557)],
      [Offset(0.582, 0.557), Offset(0.642, 0.524), Offset(0.651, 0.486), Offset(0.591, 0.452), Offset(0.462, 0.435), Offset(0.325, 0.421)],
      [Offset(0.325, 0.421), Offset(0.248, 0.394), Offset(0.231, 0.356), Offset(0.288, 0.327), Offset(0.373, 0.309)],
      [Offset(0.373, 0.309), Offset(0.432, 0.279), Offset(0.402, 0.241), Offset(0.466, 0.216), Offset(0.582, 0.201), Offset(0.676, 0.189)],
    ], Color(0xFFF3C8E8)),
  ];

  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  late final AnimationController _walk = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  late final AnimationController _party = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  late final AnimationController _pet = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final AnimationController _hop = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  late final AnimationController _bubble = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  final _scroll = ScrollController();
  double _viewport = 0, _mapH = 0, _panel = 0, _hdr = 80;
  double _from = 0, _to = 0; // pasos globales 0..60
  bool _ready = false;
  int _view = 1; // mundo que se está viendo
  MichiStop? _newPrize;
  String? _say; // bocadillo de Michi
  bool _alive = true;

  int get _streak => MichiLogic.streak;
  bool get _fedToday => MichiLogic.logged(dateOnly(DateTime.now()));

  static bool get _night {
    final h = DateTime.now().hour;
    return h >= 20 || h < 7;
  }

  static bool get _winter {
    final m = DateTime.now().month;
    return m == 12 || m == 1 || m == 2;
  }

  int _worldOf(double step) => step > perWorld ? 2 : 1;

  @override
  void initState() {
    super.initState();
    final step = math.min(_streak, total).toDouble();
    _to = step;
    _from = step;
    _view = _worldOf(step);
    _start(step);
    _life();
  }

  @override
  void dispose() {
    _alive = false;
    _idle.dispose();
    _walk.dispose();
    _party.dispose();
    _pet.dispose();
    _hop.dispose();
    _ambient.dispose();
    _bubble.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Michi está vivo: cada pocos segundos da un saltito o dice algo.
  Future<void> _life() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    var n = 0;
    while (_alive && mounted) {
      if (!_walk.isAnimating && _newPrize == null) {
        if (n % 3 == 0) {
          _talk(_phrase());
        } else {
          _hop.forward(from: 0);
        }
      }
      n++;
      await Future.delayed(Duration(milliseconds: 4200 + math.Random().nextInt(2500)));
    }
  }

  String _phrase() {
    if (MichiLogic.isBirthday) return MichiLogic.birthdayTitle();
    if (MichiLogic.missingYou) return MichiLogic.letter();
    final c = MichiLogic.cheer(fedToday: _fedToday);
    if (c != null) return c;
    // Si no, cuenta la historia de la última parada conseguida.
    final got = MichiLogic.stops.where((s) => s.day <= _to).toList();
    if (got.isNotEmpty) return MichiLogic.story(got.last.day);
    return tr('Michi avanza un paso cada día que registras.', 'Michi moves one step every day you log.');
  }

  Future<void> _talk(String text) async {
    if (!mounted) return;
    setState(() => _say = text);
    await _bubble.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 3600));
    if (!mounted) return;
    await _bubble.reverse();
    if (mounted && _say == text) setState(() => _say = null);
  }

  void _doPet() {
    HapticFeedback.lightImpact();
    MichiSound.purr();
    _pet.forward(from: 0);
    _talk(const ['💗', '😻', '🥰', '💕'][math.Random().nextInt(4)] * 3);
  }

  Future<void> _start(double step) async {
    final p = await SharedPreferences.getInstance();
    final seen = (p.getDouble(_seenKey) ?? 0).clamp(0, total).toDouble();
    await p.setDouble(_seenKey, step);
    await MichiLogic.postcards(); // guarda las postales ya conseguidas
    if (!mounted) return;
    var from = seen < step ? seen : step;
    // Si ha cambiado de mundo, empieza en el arcoíris del mundo 2.
    if (_worldOf(from) != _worldOf(step)) from = perWorld.toDouble();
    setState(() {
      _from = from;
      _ready = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToMichi(_from));
    if (seen < step) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      HapticFeedback.selectionClick();
      await _walk.forward(from: 0);
      final won = MichiLogic.stops.where((s) => s.day > seen && s.day <= step).toList();
      if (won.isNotEmpty && mounted) {
        setState(() => _newPrize = won.last);
        HapticFeedback.heavyImpact();
        _party.forward(from: 0);
      } else if (mounted) {
        _hop.forward(from: 0);
      }
    }
  }

  // ---------- Geometría del camino ----------
  Offset _pos(_World w, double local) {
    final b = w.bounds;
    var i = 0;
    while (i < 3 && local > b[i + 1]) {
      i++;
    }
    final t = ((local - b[i]) / (b[i + 1] - b[i])).clamp(0.0, 1.0);
    return _along(w.segments[i], t);
  }

  Offset _along(List<Offset> pts, double t) {
    var len = 0.0;
    final segs = <double>[];
    for (var i = 0; i < pts.length - 1; i++) {
      final l = (pts[i + 1] - pts[i]).distance;
      segs.add(l);
      len += l;
    }
    var d = t * len;
    for (var i = 0; i < segs.length; i++) {
      if (d <= segs[i] || i == segs.length - 1) {
        final f = segs[i] == 0 ? 0.0 : (d / segs[i]).clamp(0.0, 1.0);
        return Offset.lerp(pts[i], pts[i + 1], f)!;
      }
      d -= segs[i];
    }
    return pts.last;
  }

  double _local(double step, int world) => (step - (world - 1) * perWorld).clamp(0, perWorld).toDouble();

  void _scrollToMichi(double step) {
    if (!_scroll.hasClients || _mapH == 0) return;
    final w = _worlds[_view - 1];
    final y = _hdr + _pos(w, _local(step, _view)).dy * _mapH;
    final target = (y - (_viewport - _panel) * 0.55).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.jumpTo(target);
  }

  void _switchWorld(int v) {
    if (v == _view) return;
    HapticFeedback.selectionClick();
    setState(() => _view = v);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_worldOf(_to) == v) {
        _scrollToMichi(_to);
      } else if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _showStory(MichiStop s) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(s.name(), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: C.pinkDark)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset('assets/go/${s.postcard}.jpg', height: 140, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Text(MichiLogic.story(s.day), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: C.text, height: 1.35)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final streak = _streak;
    final step = math.min(streak, total);
    final top = MediaQuery.of(context).padding.top;
    final fed = _fedToday;
    final world = _worlds[_view - 1];
    final michiHere = _worldOf(_to) == _view || (_walk.isAnimating && _worldOf(_from) == _view);
    final locked = _view == 2 && step < perWorld;
    final localStep = _local(step.toDouble(), _view);
    return Scaffold(
      backgroundColor: C.t(0xFFFCE4F1),
      body: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final h = w * world.aspect;
        final panelSpace = 236.0 + MediaQuery.of(context).padding.bottom;
        _viewport = c.maxHeight;
        _mapH = h;
        _panel = panelSpace;
        _hdr = top + 70;
        return Stack(
          children: [
            Positioned.fill(child: Container(color: world.ground)),
            SingleChildScrollView(
              controller: _scroll,
              child: Column(
                children: [
                  Container(
                    height: _hdr,
                    width: w,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF6D9F2), Color(0xFFEBD5F7)]),
                    ),
                  ),
                  SizedBox(
                    width: w,
                    height: h,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(left: 0, top: 0, width: w, height: h, child: Image.asset('assets/go/${world.map}', fit: BoxFit.fill)),
                        _ambientLayer(w, h),
                        if (_night) _nightLayer(w, h),
                        if (_winter) _snowLayer(w, h),
                        // Huellitas de los pasos
                        for (var i = 1; i <= perWorld; i++)
                          if (!world.bounds.contains(i)) _paw(world, i, !locked && i <= localStep, w, h),
                        // Paradas con su premio
                        for (final s in MichiLogic.stops.where((s) => s.world == _view))
                          _stopBadge(world, s, step >= s.day, w, h),
                        if (_ready && michiHere) _michi(world, w, h),
                        if (locked) _lockedLayer(),
                      ],
                    ),
                  ),
                  SizedBox(height: panelSpace),
                ],
              ),
            ),
            _header(top, streak),
            _bottomPanel(step, fed, localStep),
            if (_newPrize != null) _celebration(_newPrize!),
          ],
        );
      }),
    );
  }

  Widget _michi(_World world, double w, double h) {
    return AnimatedBuilder(
      animation: Listenable.merge([_idle, _walk, _pet, _hop, _bubble]),
      builder: (context, _) {
        final walking = _walk.isAnimating;
        final cur = walking ? _from + (_to - _from) * Curves.easeInOut.transform(_walk.value) : (_walk.isCompleted ? _to : _from);
        final local = _local(cur, _view);
        final p = _pos(world, local);
        // Hacia dónde mira: compara con un poco más adelante del camino.
        final ahead = _pos(world, math.min(perWorld.toDouble(), local + 0.3));
        final flip = walking && ahead.dx < p.dx;
        final bob = math.sin(_idle.value * math.pi) * 3;
        // Andar, saltar y ronronear con dibujos fotograma a fotograma.
        const size = 100.0;
        final jumpI = _hop.isAnimating ? (_hop.value * MichiAnim.jump).floor().clamp(0, MichiAnim.jump - 1) : 0;
        const stepHop = 0.0;
        const petHop = 0.0;
        final hop = _hop.isAnimating ? -MichiAnim.jumpLift[jumpI] * size : 0.0;
        const squash = 1.0;
        final tilt = (walking || _pet.isAnimating || _hop.isAnimating) ? 0.0 : math.sin(_idle.value * math.pi) * 0.03;
        final sprite = walking
            ? MichiFrame('walk', (_walk.value * _walk.duration!.inMilliseconds / 83).floor(), size: size)
            : _pet.isAnimating
                ? MichiFrame('pet', (_pet.value * MichiAnim.pet).floor().clamp(0, MichiAnim.pet - 1), size: size)
                : _hop.isAnimating
                    ? MichiFrame('jump', jumpI, size: size)
                    : null;
        final img = walking
            ? 'cat_walk'
            : (_pet.isAnimating
                ? 'michi_heart'
                : (_fedToday ? MichiLogic.pose(fedToday: true) : (MichiLogic.missingYou ? 'michi_letter' : MichiLogic.pose(fedToday: false))));
        final left = p.dx * w - size / 2;
        final topY = p.dy * h - size + 10 - bob + stepHop + petHop + hop;
        final lift = stepHop + petHop + hop; // negativo = en el aire
        return Positioned(
          left: left - 70,
          top: topY - 74,
          width: size + 140,
          height: size + 84 - lift,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Estela de brillitos al caminar
              if (walking)
                for (var i = 0; i < 6; i++)
                  Positioned(
                    left: 70 + size / 2 + (flip ? 1 : -1) * (14.0 + i * 9) + math.sin(_walk.value * 30 + i) * 4,
                    top: 74 + size - 16 - (i % 3) * 7 - lift,
                    child: Opacity(
                      opacity: (1 - i / 6).clamp(0.0, 1.0) * 0.9,
                      child: Text(i.isEven ? '✨' : '🐾', style: TextStyle(fontSize: 12.0 - i)),
                    ),
                  ),
              // Sombra en el suelo (se hace pequeña cuando salta)
              Positioned(
                left: 70 + 24,
                width: size - 48,
                top: 74 + size - 12 - lift,
                child: Transform.scale(
                  scale: (1 + lift / 80).clamp(0.5, 1.0),
                  child: Container(height: 10, decoration: BoxDecoration(color: Colors.black.withOpacity(0.18), borderRadius: BorderRadius.circular(20))),
                ),
              ),
              Positioned(
                left: 70,
                top: 74,
                width: size,
                height: size,
                child: GestureDetector(
                  onTap: _doPet,
                  child: Transform.rotate(
                    angle: tilt,
                    alignment: Alignment.bottomCenter,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.diagonal3Values((flip ? -1.0 : 1.0) * squash, 1 / squash, 1),
                      child: sprite ??
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: Img(img, key: ValueKey(img), size: size, fallback: Icons.pets_rounded),
                          ),
                    ),
                  ),
                ),
              ),
              if (_pet.isAnimating)
                for (var i = 0; i < 4; i++)
                  Positioned(
                    left: 70 + 6.0 + i * 24,
                    top: 74 - 4 - _pet.value * (28 + i * 8),
                    child: Opacity(
                      opacity: (1 - _pet.value).clamp(0.0, 1.0),
                      child: Text(const ['💗', '💕', '💖', '✨'][i], style: const TextStyle(fontSize: 20)),
                    ),
                  ),
              // Bocadillo
              if (_say != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: size + 84 - lift - 74 + 4,
                  child: Transform.scale(
                    scale: Curves.easeOutBack.transform(_bubble.value.clamp(0.0, 1.0)),
                    alignment: Alignment.bottomCenter,
                    child: Opacity(
                      opacity: _bubble.value.clamp(0.0, 1.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: C.pink.withOpacity(0.3), blurRadius: 10)],
                        ),
                        child: Text(_say!,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: C.pinkDark, height: 1.2)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Mariposas y pétalos que flotan (de día) — el mapa parece vivo.
  Widget _ambientLayer(double w, double h) {
    if (_night) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ambient,
          builder: (context, _) {
            final t = _ambient.value;
            return Stack(children: [
              for (var i = 0; i < 7; i++)
                Positioned(
                  left: (((t + i / 7) % 1.0) * 1.2 - 0.1) * w,
                  top: (0.12 + (i * 0.13) % 0.8) * h + math.sin((t * 6 + i) * math.pi) * 22,
                  child: Transform.rotate(
                    angle: math.sin((t * 10 + i) * math.pi) * 0.3,
                    child: Text(i % 3 == 0 ? '🦋' : '🌸', style: TextStyle(fontSize: i % 3 == 0 ? 20 : 13)),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _nightLayer(double w, double h) => Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _idle,
            builder: (context, _) => Stack(children: [
              Positioned.fill(child: Container(color: const Color(0xFF1B1F4B).withOpacity(0.38))),
              for (var i = 0; i < 26; i++)
                Positioned(
                  left: ((i * 61) % 97) / 97 * w,
                  top: ((i * 37) % 89) / 89 * h * 0.55,
                  child: Opacity(
                    opacity: (0.35 + 0.65 * (i.isEven ? _idle.value : 1 - _idle.value)).clamp(0.0, 1.0),
                    child: Text('✦', style: TextStyle(fontSize: 10.0 + (i % 3) * 4, color: const Color(0xFFFFF4B8))),
                  ),
                ),
              Positioned(right: w * 0.08, top: h * 0.03, child: const Text('🌙', style: TextStyle(fontSize: 40))),
            ]),
          ),
        ),
      );

  Widget _snowLayer(double w, double h) => Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _ambient,
            builder: (context, _) => Stack(children: [
              for (var i = 0; i < 40; i++)
                Positioned(
                  left: ((i * 53) % 100) / 100 * w + math.sin((_ambient.value * 8 + i * 0.3) * math.pi) * 14,
                  top: ((_ambient.value * 1.5 + i * 0.137) % 1.0) * h,
                  child: Text('❄', style: TextStyle(fontSize: 8.0 + (i % 4) * 3, color: Colors.white.withOpacity(0.9))),
                ),
            ]),
          ),
        ),
      );

  Widget _lockedLayer() => Positioned.fill(
        child: Container(
          color: Colors.white.withOpacity(0.45),
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: C.pink.withOpacity(0.3), blurRadius: 20)]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🔒', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(tr('Llega al castillo para abrir este mundo', 'Reach the castle to unlock this world'),
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: C.pinkDark)),
            ]),
          ),
        ),
      );

  Widget _header(double top, int streak) => Positioned(
        top: top + 8,
        left: 10,
        right: 10,
        child: Row(
          children: [
            _glass(IconButton(icon: Icon(Icons.arrow_back_rounded, color: C.pinkDark), onPressed: () => Navigator.of(context).maybePop())),
            const SizedBox(width: 8),
            Expanded(
              child: _glass(Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(tr('El mundo de Michi', "Michi's world"),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.pinkDark)),
              )),
            ),
            const SizedBox(width: 6),
            // Volver a la casa de Michi.
            GestureDetector(
              onTap: () {
                final s = AppStore.instance;
                s.michiScene = 'house';
                s.commit();
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MichiHouseScreen(onFeed: widget.onFeed)));
              },
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.88),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
                ),
                child: const Text('🏠', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 6),
            for (final v in [1, 2]) ...[
              GestureDetector(
                onTap: () => _switchWorld(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _view == v ? C.pink : Colors.white.withOpacity(0.88),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
                  ),
                  child: Text(v == 1 ? '🏰' : '🌙', style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 6),
            ],
            _glass(Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Text('🔥 $streak', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFB7791F))),
            )),
          ],
        ),
      );

  Widget _bottomPanel(int step, bool fed, double localStep) {
    final banner = MichiLogic.isBirthday
        ? MichiLogic.birthdayTitle()
        : (fed ? tr('¡Michi está feliz! 🐟', 'Michi is happy! 🐟') : tr('Michi te espera 🐾', 'Michi is waiting 🐾'));
    return Positioned(
      left: 12,
      right: 12,
      bottom: 14 + MediaQuery.of(context).padding.bottom,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: C.t(0xFF8E1B47).withOpacity(0.18), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Se puede plegar para ver bien el mapa de detrás.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _panelOpen = !_panelOpen),
              child: Row(children: [
                Expanded(child: Text(banner, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.pinkDark))),
                Text('🐾 ${tr('{} de {} pasos', '{} of {} steps').replaceFirst('{}', '${localStep.round()}').replaceFirst('{}', '$perWorld')}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: C.text)),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _panelOpen ? 0 : 0.5,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: C.pinkDark, size: 26),
                ),
              ]),
            ),
            if (_panelOpen) ...[
            const SizedBox(height: 4),
            Text(
              MichiLogic.missingYou ? MichiLogic.letter() : (MichiLogic.cheer(fedToday: fed) ?? tr('Michi avanza un paso cada día que registras.', 'Michi moves one step every day you log.')),
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.text),
            ),
            if (MichiLogic.streakInfo().shieldRecent && step > 0) ...[
              const SizedBox(height: 3),
              Text(MichiLogic.shieldText(), style: const TextStyle(fontSize: 11.5, color: Color(0xFF3E7BC9), fontWeight: FontWeight.w800)),
            ],
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: localStep / perWorld,
                minHeight: 10,
                backgroundColor: C.t(0xFFFCE4F1),
                valueColor: AlwaysStoppedAnimation(C.pink),
              ),
            ),
            const SizedBox(height: 10),
            if (MichiAdvent.visible) ...[
              SizedBox(
                width: double.infinity,
                child: _chip('🎄', tr('Adviento', 'Advent'),
                    () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MichiAdventScreen())).then((_) {
                          if (mounted) setState(() {});
                        })),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(width: double.infinity, child: _chip('😹', tr('Chiste de Michi', "Michi's joke"), () => MichiJokes.show(context))),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _chip('🌬️', tr('Respira', 'Breathe'), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MichiBreatheScreen())))),
              const SizedBox(width: 8),
              Expanded(child: _chip('💌', tr('Cartas', 'Letters'), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MichiLetterScreen())))),
              const SizedBox(width: 8),
              Expanded(child: _chip('👗', tr('Armario', 'Wardrobe'), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MichiWardrobeScreen())).then((_) {
                    if (mounted) setState(() {});
                  }))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _chip('📔', tr('Diario', 'Diary'), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MichiDiaryScreen())))),
              const SizedBox(width: 8),
              Expanded(child: _chip('🎯', tr('Retos', 'Challenges'), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MichiChallengeScreen())))),
              const SizedBox(width: 8),
              Expanded(child: _chip('🏅', tr('Logros', 'Badges'), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MichiBadgesScreen())))),
            ]),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _doPet,
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
                if (!fed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).pop();
                          widget.onFeed();
                        },
                        style: FilledButton.styleFrom(backgroundColor: C.pink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
                        icon: const Text('🐟'),
                        label: Text(tr('Darle de comer', 'Feed Michi'), style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String emoji, String label, VoidCallback onTap) => Material(
        color: C.t(0xFFFCE4F1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: C.pinkDark))),
            ]),
          ),
        ),
      );

  Widget _glass(Widget child) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
        ),
        child: child,
      );

  Widget _paw(_World world, int i, bool done, double w, double h) {
    final p = _pos(world, i.toDouble());
    return Positioned(
      left: p.dx * w - 9,
      top: p.dy * h - 9,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: done ? C.pink : Colors.white.withOpacity(0.85),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)],
        ),
        alignment: Alignment.center,
        child: done ? const Text('🐾', style: TextStyle(fontSize: 9)) : null,
      ),
    );
  }

  Widget _stopBadge(_World world, MichiStop s, bool unlocked, double w, double h) {
    final p = _pos(world, _local(s.day.toDouble(), s.world));
    const size = 58.0;
    return Positioned(
      left: (p.dx * w - size / 2).clamp(4.0, w - size - 4),
      top: p.dy * h - size / 2,
      child: GestureDetector(
        onTap: unlocked ? () => _showStory(s) : null,
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _idle,
              builder: (context, child) => Transform.scale(scale: unlocked ? 1 + _idle.value * 0.06 : 1, child: child),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: unlocked ? const Color(0xFFFFC94D) : Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: unlocked ? const Color(0xFFFFC94D).withOpacity(0.8) : Colors.black26, blurRadius: unlocked ? 18 : 6)],
                ),
                child: ClipOval(
                  child: ColorFiltered(
                    colorFilter: unlocked
                        ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                        : const ColorFilter.matrix([0.33, 0.33, 0.33, 0, 40, 0.33, 0.33, 0.33, 0, 40, 0.33, 0.33, 0.33, 0, 40, 0, 0, 0, 1, 0]),
                    child: Image.asset('assets/go/${s.prize}.png',
                        fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(s.emoji, style: const TextStyle(fontSize: 28)))),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: unlocked ? C.pink : Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(12)),
              child: Text(
                unlocked ? s.name() : '🔒 ${s.day} ${daysWord(s.day)}',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: unlocked ? Colors.white : C.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _celebration(MichiStop s) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _newPrize = null),
        child: AnimatedBuilder(
          animation: _party,
          builder: (context, _) {
            final t = _party.value;
            final size = MediaQuery.of(context).size;
            return Container(
              color: Colors.black.withOpacity(0.45 * math.min(1, t * 4)),
              child: Stack(
                children: [
                  for (var i = 0; i < 30; i++)
                    Positioned(
                      left: (i * 37 % 100) / 100 * size.width,
                      top: -40 + t * (size.height + 80) * (0.6 + (i % 5) * 0.12),
                      child: Transform.rotate(
                        angle: t * 10 + i,
                        child: Text(const ['🎉', '✨', '💖', '🌸', '⭐', '🎀'][i % 6], style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  Center(
                    child: Transform.scale(
                      scale: Curves.elasticOut.transform(math.min(1, t * 2.2)),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 34),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [BoxShadow(color: const Color(0xFFFFC94D).withOpacity(0.7), blurRadius: 30)],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tr('¡Nuevo premio!', 'New prize!'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.pinkDark)),
                            const SizedBox(height: 10),
                            Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset('assets/go/${s.postcard}.jpg', height: 130, width: 220, fit: BoxFit.cover),
                              ),
                              Positioned(
                                right: -14,
                                bottom: -18,
                                child: Container(
                                  width: 74,
                                  height: 74,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFC94D), width: 3), color: Colors.white),
                                  child: ClipOval(
                                    child: Image.asset('assets/go/${s.prize}.png',
                                        fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(s.emoji, style: const TextStyle(fontSize: 36)))),
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            Text(s.name(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.text)),
                            const SizedBox(height: 6),
                            Text(MichiLogic.story(s.day),
                                textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: C.muted, height: 1.3)),
                            const SizedBox(height: 6),
                            Text(tr('Postal nueva en tu álbum 📮', 'New postcard in your album 📮'),
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: C.pink)),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => setState(() => _newPrize = null),
                              style: FilledButton.styleFrom(backgroundColor: C.pink, shape: const StadiumBorder()),
                              child: const Text('🎉  OK', style: TextStyle(fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

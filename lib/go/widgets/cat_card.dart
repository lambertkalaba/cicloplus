import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/michi_advent.dart';
import '../screens/michi_extras.dart';
import '../screens/michi_more.dart';
import '../screens/michi_stories.dart';
import '../screens/michi_house.dart';
import '../screens/michi_world.dart';
import '../data/store.dart';
import 'premium.dart' show Premium;
import '../strings.dart';
import 'ui.dart';
import 'dart:async';

import 'michi_events.dart';
import 'michi_gifts.dart';
import 'michi_sound.dart';
import 'michi_sprite.dart';
import 'michi_voice.dart';
import 'michi_jokes.dart';
import 'michi_logic.dart';

/// Michi, el gatito de CicloPlus. Sustituye a "Tu jardín":
/// - Come cuando registras tu día (cualquier dato del día cuenta).
/// - Después de registrar, salta y juega contento.
/// - Si no registras, te espera con hambre (sin hacerte sentir mal).
/// - Con rachas de días seguidos gana premios (collar, cama, juguete, corona).
class CatCard extends StatefulWidget {
  const CatCard({super.key, required this.onFeed});

  /// Abre el registro del día (dar de comer = registrar).
  final VoidCallback onFeed;

  @override
  State<CatCard> createState() => _CatCardState();
}

enum _Mood { happy, waiting, hungry, sad, sleeping }

class _CatCardState extends State<CatCard> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat(reverse: true);
  late final AnimationController _jump = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  // Entra caminando desde la izquierda (una vez por apertura de la app).
  late final AnimationController _walk = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  // Saludo: mueve el cuerpo como diciendo "¡hola!" cada pocos segundos.
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  // Baile (fotogramas de ChatGPT): a veces baila cuando lo tocas contento.
  late final AnimationController _dance = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400));
  static bool _walkedIn = false;
  bool _missedYou = false; // hacía días que no entraba
  bool _wokeUp = false; // la despertaste tocando su casita
  bool _hearts = false; // corazones al acariciarlo
  static const _lastSeenKey = 'cat_last_seen_day';
  bool _celebrate = false;
  int _celebrateFrame = 0;

  static const _celebratedKey = 'cat_celebrated_day';

  @override
  void initState() {
    super.initState();
    AppStore.instance.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _check();
      if (mounted) MichiAnim.precache(context);
    });
    _intro();
  }

  StreamSubscription<List<MichiGift>>? _giftSub;
  List<MichiGift> _gifts = const [];

  Future<void> _intro() async {
    await MichiLogic.loadBirthday();
    MichiEvents.loadStoreCountry(); // sin esperar: el país de la tienda llega detrás
    try {
      _giftSub = MichiGiftService.watchMine().listen((g) {
        if (mounted) setState(() => _gifts = g);
      }, onError: (_) {});
    } catch (_) {}
    final p = await SharedPreferences.getInstance();
    final last = p.getString(_lastSeenKey);
    final today = dayKey(DateTime.now());
    if (last != null && last != today) {
      final d = DateTime.tryParse(last);
      if (d != null && dateOnly(DateTime.now()).difference(d).inDays >= 3) _missedYou = true;
    }
    await p.setString(_lastSeenKey, today);
    if (!mounted) return;
    setState(() {});
    if (!_walkedIn) {
      _walkedIn = true;
      await _walk.forward(from: 0);
      if (mounted) setState(() {}); // ya llegó: cambia a la postura de saludo
    } else {
      _walk.value = 1;
    }
    // Saluda al llegar y luego cada ~6 s mientras esté contento o esperando.
    while (mounted) {
      final m = _mood;
      if (!_celebrate && (m == _Mood.happy || m == _Mood.waiting)) {
        // Contento: a veces saluda, a veces da un saltito.
        if (m == _Mood.happy && math.Random().nextInt(3) == 0) {
          await _jump.forward(from: 0);
        } else {
          await _wave.forward(from: 0);
        }
      }
      await Future.delayed(const Duration(seconds: 6));
    }
  }

  @override
  void dispose() {
    AppStore.instance.removeListener(_check);
    _giftSub?.cancel();
    _idle.dispose();
    _jump.dispose();
    _walk.dispose();
    _wave.dispose();
    _dance.dispose();
    MichiVoice.stop();
    super.dispose();
  }

  bool _logged(DateTime d) {
    final l = AppStore.instance.logs[dayKey(d)];
    return l != null && !l.isEmpty;
  }

  /// Días seguidos registrando (hasta hoy, o hasta ayer si hoy aún no).
  int get _streak => MichiLogic.streak;

  static bool get _isNight {
    final h = DateTime.now().hour;
    return h >= 22 || h < 7;
  }

  _Mood get _mood {
    final today = dateOnly(DateTime.now());
    if (_logged(today)) return (_isNight && !_wokeUp) ? _Mood.sleeping : _Mood.happy;
    if (_logged(addDays(today, -1))) return _Mood.waiting;
    // Triste si llevas días sin entrar o sin registrar (3+).
    if (_missedYou || (!_logged(addDays(today, -2)) && AppStore.instance.logs.isNotEmpty)) return _Mood.sad;
    return _Mood.hungry;
  }

  /// La primera vez que se ve al gato después de registrar hoy: fiesta.
  Future<void> _check() async {
    if (!mounted) return;
    setState(() {});
    if (_mood != _Mood.happy) return;
    final p = await SharedPreferences.getInstance();
    final today = dayKey(DateTime.now());
    if (p.getString(_celebratedKey) == today) return;
    await p.setString(_celebratedKey, today);
    _playCelebration();
  }

  Future<void> _playCelebration() async {
    if (!mounted) return;
    setState(() => _celebrate = true);
    HapticFeedback.mediumImpact();
    MichiSound.meow();
    for (var i = 0; i < 3; i++) {
      if (!mounted) return;
      setState(() => _celebrateFrame = i);
      await _jump.forward(from: 0);
    }
    if (mounted) setState(() => _celebrate = false);
  }

  /// Animación dibujada que toca ahora: (nombre, fotograma, altura del salto).
  (String, int, double)? get _sprite {
    if (_walk.isAnimating) return ('walk', (_walk.value * 18).floor(), 0.0);
    if (_dance.isAnimating) {
      final i = (_dance.value * 24).floor() % MichiAnim.count('dance');
      return ('dance', i, i == 4 ? 0.05 : 0.0);
    }
    if (_hearts && _jump.isAnimating) return ('pet', (_jump.value * MichiAnim.pet).floor().clamp(0, MichiAnim.pet - 1), 0.0);
    if (_jump.isAnimating && (_celebrate || _mood == _Mood.happy)) {
      final i = (_jump.value * MichiAnim.jump).floor().clamp(0, MichiAnim.jump - 1);
      return ('jump', i, MichiAnim.jumpLift[i]);
    }
    return null;
  }

  MichiEvent? get _event => MichiLogic.isBirthday ? null : MichiEvents.today();

  String get _image {
    if (_celebrate) return _celebrateFrame == 1 ? 'cat_eat' : 'cat_play';
    if (_walk.isAnimating) return 'cat_walk';
    switch (_mood) {
      case _Mood.sleeping:
        return MichiLogic.sleepPose();
      case _Mood.sad:
        return 'michi_letter';
      case _Mood.happy:
        return _hearts ? 'michi_heart' : (_event?.pose ?? MichiLogic.pose(fedToday: true));
      case _Mood.waiting:
        return MichiLogic.pose(fedToday: false);
      case _Mood.hungry:
        return 'cat_wave';
    }
  }

  /// Una frase distinta cada día cuando está contento.
  String _dailyPhrase() {
    const es = [
      '¡Miau! Hoy estás preciosa.',
      'Gracias por cuidarte (y cuidarme).',
      '¿Un poco de agua? Yo ya bebí 💧',
      'Respira hondo conmigo... ronroneo 💗',
      'Me encanta cuando vienes a verme.',
      'Hoy toca mimarse un poquito.',
      'Tú puedes con todo. Yo te animo 🐾',
      '¡Mañana te espero aquí!',
    ];
    const en = [
      'Meow! You look lovely today.',
      'Thanks for looking after yourself (and me).',
      'Some water? I already had mine 💧',
      'Take a deep breath with me... purr 💗',
      'I love it when you visit.',
      'Today is a day to pamper yourself.',
      "You've got this. I'm cheering you on 🐾",
      "I'll be waiting here tomorrow!",
    ];
    final i = DateTime.now().difference(DateTime(2026)).inDays % es.length;
    return tr(es[i], en[i]);
  }

  /// Premios por racha.
  List<String> get _prizes {
    final s = _streak;
    return [
      if (s >= 3) '🎀',
      if (s >= 7) '🛏️',
      if (s >= 14) '🧶',
      if (s >= 30) '👑',
    ];
  }

  String get _nextPrize {
    final s = _streak;
    if (s < 3) return tr('Collar a los 3 días', 'Collar at 3 days');
    if (s < 7) return tr('Camita a los 7 días', 'Little bed at 7 days');
    if (s < 14) return tr('Ovillo a los 14 días', 'Yarn ball at 14 days');
    if (s < 30) return tr('Corona a los 30 días', 'Crown at 30 days');
    return tr('¡Tiene todos los premios!', 'All prizes unlocked!');
  }

  @override
  Widget build(BuildContext context) {
    final mood = _mood;
    final streak = _streak;
    final event = _event;
    final special = event != null && (mood == _Mood.happy || mood == _Mood.waiting);
    final title = MichiLogic.isBirthday ? MichiLogic.birthdayTitle() : special ? '${event.emoji} ${tr('¡Hoy es un día especial!', 'Today is a special day!')}' : switch (mood) {
      _Mood.happy => tr('¡Michi está feliz! 🐟', 'Michi is happy! 🐟'),
      _Mood.waiting => tr('Michi te espera 🐾', 'Michi is waiting 🐾'),
      _Mood.hungry => tr('Michi tiene hambre 🥺', 'Michi is hungry 🥺'),
      _Mood.sad => tr('Michi te ha echado de menos 😿', 'Michi missed you 😿'),
      _Mood.sleeping => tr('Michi duerme en su casita 😴', 'Michi is asleep at home 😴'),
    };
    final body = switch (mood) {
      _Mood.happy => tr('Ya ha comido hoy gracias a tu registro. ¡Vuelve mañana!', 'Fed today thanks to your log. Come back tomorrow!'),
      _Mood.waiting => tr('Registra tu día para darle de comer.', 'Log your day to feed Michi.'),
      _Mood.hungry => tr('Hace días que no come. Registra tu día y vuelve a jugar.', "Michi hasn't eaten in a while. Log your day to play again."),
      _Mood.sad => tr('Llevabas días sin venir. Regístrate hoy y verás qué contento se pone.', "You've been away for days. Log today and see how happy Michi gets."),
      _Mood.sleeping => tr('Ya comió hoy y está calentito. Toca su casita para despertarlo.', 'Fed and cosy. Tap the house to wake Michi up.'),
    };
    final phrase = switch (mood) {
      _Mood.happy => event?.text ?? MichiLogic.cheer(fedToday: true) ?? (DateTime.now().day.isEven ? MichiEvents.seasonPhrase() : _dailyPhrase()),
      _Mood.waiting => event?.text ?? MichiLogic.cheer(fedToday: false) ?? MichiEvents.seasonPhrase(),
      _Mood.sad => MichiLogic.letter(),
      _ => null,
    };
    final shield = MichiLogic.streakInfo().shieldRecent && streak > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 12),
      decoration: card(),
      child: Row(
        children: [
          SizedBox(
            width: 128,
            height: 128,
            child: AnimatedBuilder(
              animation: Listenable.merge([_idle, _jump, _walk, _wave]),
              builder: (context, child) {
                final sad = mood == _Mood.sad;
                // Entrada caminando: se desplaza desde fuera con pasitos.
                final w = Curves.easeOut.transform(_walk.value);
                final walkX = (1 - w) * -150;
                const step = 0.0; // los pasos ya están dibujados
                // Respira suave siempre (más lento y bajito si está triste).
                final bob = math.sin(_idle.value * math.pi) * (sad ? 1.5 : 3);
                // Salto con curva natural (sube rápido, cae suave).
                final j = Curves.easeOutCubic.transform(_jump.value);
                final hop = (_celebrate || _jump.isAnimating) && _sprite == null ? -math.sin(j * math.pi) * 26 : 0.0;
                // Saludo: balanceo rápido de lado a lado con saltito.
                final waveT = _wave.isAnimating ? Curves.easeInOut.transform(_wave.value) : 0.0;
                final waveTilt = math.sin(waveT * math.pi * 4) * 0.12 * (1 - waveT);
                final waveHop = -math.sin(waveT * math.pi) * 6;
                final tilt = _sprite != null
                    ? 0.0
                    : _celebrate
                    ? math.sin(_jump.value * math.pi * 2) * 0.08
                    : (sad ? -0.04 : waveTilt + (mood == _Mood.happy ? math.sin(_idle.value * math.pi) * 0.03 : 0.0));
                return Opacity(
                  opacity: _walk.value < 0.05 && !_walk.isCompleted ? 0 : 1,
                  child: Transform.translate(
                    offset: Offset(walkX, hop - bob + step + waveHop),
                    child: Transform.rotate(alignment: Alignment.bottomCenter, angle: tilt, child: child),
                  ),
                );
              },
              child: GestureDetector(
                onTap: () {
                  if (mood == _Mood.sleeping) {
                    // Sale de su casita caminando y te saluda.
                    setState(() => _wokeUp = true);
                    _walk.forward(from: 0).then((_) {
                      if (!mounted) return;
                      setState(() {});
                      _wave.forward(from: 0);
                    });
                  } else if (mood == _Mood.happy) {
                    // A veces se pone a bailar; si no, caricia: corazones,
                    // saltito, ronroneo y vibración suave. Y te dice algo.
                    HapticFeedback.lightImpact();
                    if (!_dance.isAnimating && math.Random().nextInt(3) == 0) {
                      MichiSound.chime();
                      MichiVoice.say(tr('¡Mira cómo bailo!', 'Look at me dance!'));
                      _dance.forward(from: 0).then((_) {
                        if (mounted) setState(() {});
                      });
                      return;
                    }
                    MichiSound.purr();
                    MichiVoice.say(phrase ?? _dailyPhrase());
                    setState(() => _hearts = true);
                    _jump.forward(from: 0).then((_) {
                      if (mounted) setState(() => _hearts = false);
                    });
                  } else if (mood == _Mood.waiting) {
                    HapticFeedback.selectionClick();
                    MichiSound.meow();
                    MichiVoice.say(phrase ?? tr('¡Hola! Registra tu día y me das de comer.', 'Hi! Log your day and feed me.'));
                    _wave.forward(from: 0);
                  } else {
                    widget.onFeed();
                  }
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Cambio de postura suave (fundido), sin saltos bruscos.
                    // Andar, saltar y ronronear fotograma a fotograma (dibujos
                    // de verdad); el resto del tiempo, su postura del día.
                    AnimatedBuilder(
                      animation: Listenable.merge([_walk, _jump, _dance]),
                      builder: (context, _) {
                        final sp = _sprite;
                        if (sp != null) {
                          return Transform.translate(
                            offset: Offset(0, -sp.$3 * 128),
                            child: MichiFrame(sp.$1, sp.$2, size: 128),
                          );
                        }
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: Img(_image, key: ValueKey(_image), size: 128, fallback: Icons.pets_rounded),
                        );
                      },
                    ),
                    // Lo que flota alrededor de Michi: la estación o la fiesta de hoy.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: StoryParticles(
                          key: ValueKey('fx${event?.fx ?? MichiEvents.seasonFx}'),
                          fx: event?.fx ?? MichiEvents.seasonFx,
                          count: event != null ? 10 : 5,
                        ),
                      ),
                    ),
                    if (_hearts)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _jump,
                            builder: (context, _) => Stack(
                              clipBehavior: Clip.none,
                              children: [
                                for (var i = 0; i < 3; i++)
                                  Positioned(
                                    left: 30.0 + i * 28,
                                    top: 10 - _jump.value * (30 + i * 8),
                                    child: Opacity(
                                      opacity: (1 - _jump.value).clamp(0.0, 1.0),
                                      child: Text(const ['💗', '💕', '💖'][i], style: const TextStyle(fontSize: 18)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (_) => AppStore.instance.michiScene == 'map' && Premium.active ? MichiWorldScreen(onFeed: widget.onFeed) : MichiHouseScreen(onFeed: widget.onFeed)))
                  .then((_) {
                if (mounted) setState(() {});
              }),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_gifts.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => showOpenMichiGift(context, _gifts.first),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.fromLTRB(4, 2, 10, 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFFFFE08A), C.t(0xFFFFC2DC)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Img('gift_box', size: 28, fallback: Icons.card_giftcard_rounded),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(tr('¡Michi tiene un regalo! 🎁', 'Michi has a gift! 🎁'),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: C.pinkDark)),
                        ),
                      ]),
                    ),
                  ),
                ],
                Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: C.pinkDark)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 12.5, color: C.text, height: 1.3, fontWeight: FontWeight.w600)),
                if (phrase != null) ...[
                  const SizedBox(height: 4),
                  Text('💬 $phrase',
                      style: TextStyle(fontSize: 12, color: C.pinkDark, fontStyle: FontStyle.italic, fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFFFF1C9), borderRadius: BorderRadius.circular(10)),
                      child: Text('🔥 $streak ${daysWord(streak)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFB7791F))),
                    ),
                    const SizedBox(width: 6),
                    Text(_prizes.join(' '), style: const TextStyle(fontSize: 15)),
                  ],
                ),
                if (shield) ...[
                  const SizedBox(height: 4),
                  Text(MichiLogic.shieldText(), style: const TextStyle(fontSize: 11, color: Color(0xFF3E7BC9), fontWeight: FontWeight.w800)),
                ],
                const SizedBox(height: 4),
                Text(_nextPrize, style: const TextStyle(fontSize: 11, color: C.muted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${AppStore.instance.michiScene == 'map' && Premium.active ? '🗺️' : '🏠'} ${tr('Ver a Michi', 'See Michi')} ›', style: TextStyle(fontSize: 12.5, color: C.pink, fontWeight: FontWeight.w900)),
                if (michiKitToday())
                  GestureDetector(
                    onTap: () => showMichiPeriodKit(context),
                    child: Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: C.t(0xFFFFE1EC), borderRadius: BorderRadius.circular(12)),
                      child: Text('🫖 ${tr('Mi kit para cuidarte hoy', 'My kit to look after you today')}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: C.pinkDark)),
                    ),
                  ),
                FutureBuilder<bool>(
                  future: MichiBadges.hasNew(),
                  builder: (context, snap) => snap.data == true
                      ? GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MichiBadgesScreen())).then((_) {
                            if (mounted) setState(() {});
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFFFF1C9), borderRadius: BorderRadius.circular(12)),
                            child: Text('🏅 ${tr('¡Nuevo logro!', 'New badge!')}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFB7791F))),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                FutureBuilder<bool>(
                  future: MichiLetters.hasNew(),
                  builder: (context, snap) => snap.data == true
                      ? GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MichiLetterScreen())).then((_) {
                            if (mounted) setState(() {});
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Color(0xFFFFF1C9), C.t(0xFFFFE1EC)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('💌 ${tr('¡Michi te ha escrito una carta!', 'Michi wrote you a letter!')}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: C.pinkDark)),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                FutureBuilder<bool>(
                  future: MichiEvents.hasFlowers(),
                  builder: (context, snap) => snap.data == true
                      ? GestureDetector(
                          onTap: () => showMichiFlowers(context).then((_) {
                            if (mounted) setState(() {});
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [C.t(0xFFFFE1EC), Color(0xFFFFF1C9)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('💐 ${tr('¡Michi te ha traído flores!', 'Michi brought you flowers!')}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: C.pinkDark)),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                // Chiste del día (solo hasta que lo lea).
                FutureBuilder<SharedPreferences>(
                  future: SharedPreferences.getInstance(),
                  builder: (context, snap) {
                    final n = DateTime.now();
                    final seen = snap.data?.getString('michi_joke_day') == '${n.year}-${n.month}-${n.day}';
                    if (snap.data == null || seen) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () => MichiJokes.show(context).then((_) {
                        if (mounted) setState(() {});
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFFFF1C9), borderRadius: BorderRadius.circular(12)),
                        child: Text('😹 ${tr('¡Tengo un chiste para ti!', 'I have a joke for you!')}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFB7791F))),
                      ),
                    );
                  },
                ),
                if (MichiAdvent.openUpTo > 0)
                  FutureBuilder<bool>(
                    future: MichiAdvent.hasNew(),
                    builder: (context, snap) => snap.data == true
                        ? GestureDetector(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MichiAdventScreen())).then((_) {
                              if (mounted) setState(() {});
                            }),
                            child: Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [C.t(0xFFFFE3E3), Color(0xFFDDF3E4)]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('🎄 ${tr('¡Abre la puertita de hoy!', "Open today's little door!")}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFD7263D))),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                if (mood != _Mood.happy && mood != _Mood.sleeping) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 34,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: C.pink, padding: const EdgeInsets.symmetric(horizontal: 14)),
                      onPressed: widget.onFeed,
                      icon: const Text('🐟'),
                      label: Text(tr('Darle de comer', 'Feed Michi'), style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}

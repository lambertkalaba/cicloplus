import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/store.dart';
import '../strings.dart';
import '../widgets/ui.dart';
import 'michi_more.dart' show MichiCounters;
import 'michi_stories.dart' show StoryParticles, StoryFx;

// ───────────────────────────── Respira con Michi ─────────────────────────────

/// Un minuto de respiración guiada: Michi se hincha y se deshincha contigo.
class MichiBreatheScreen extends StatefulWidget {
  const MichiBreatheScreen({super.key});

  @override
  State<MichiBreatheScreen> createState() => _MichiBreatheScreenState();
}

class _MichiBreatheScreenState extends State<MichiBreatheScreen> with SingleTickerProviderStateMixin {
  static const _inhale = 4, _hold = 2, _exhale = 6, _cycles = 5;
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: _inhale + _hold + _exhale));
  int _cycle = 0;
  bool _running = false, _done = false;
  int _phase = -1;

  @override
  void initState() {
    super.initState();
    _c.addListener(_tick);
    _c.addStatusListener((s) {
      if (s != AnimationStatus.completed || !_running) return;
      if (++_cycle >= _cycles) {
        HapticFeedback.mediumImpact();
        MichiCounters.add('breathe');
        setState(() {
          _running = false;
          _done = true;
        });
      } else {
        _c.forward(from: 0);
      }
    });
  }

  void _tick() {
    final t = _c.value * (_inhale + _hold + _exhale);
    final p = t < _inhale ? 0 : (t < _inhale + _hold ? 1 : 2);
    if (p != _phase) {
      _phase = p;
      HapticFeedback.selectionClick();
      setState(() {});
    }
  }

  /// Tamaño del círculo (0 = vacío, 1 = lleno).
  double get _fill {
    final t = _c.value * (_inhale + _hold + _exhale);
    if (t < _inhale) return Curves.easeInOut.transform(t / _inhale);
    if (t < _inhale + _hold) return 1;
    return 1 - Curves.easeInOut.transform((t - _inhale - _hold) / _exhale);
  }

  void _start() {
    HapticFeedback.lightImpact();
    setState(() {
      _cycle = 0;
      _running = true;
      _done = false;
      _phase = -1;
    });
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = !_running
        ? (_done ? tr('¡Muy bien! Te sientes más tranquila 💗', 'Well done! You feel calmer now 💗') : tr('Respira conmigo un minuto', 'Breathe with me for a minute'))
        : [tr('Inspira…', 'Breathe in…'), tr('Aguanta…', 'Hold…'), tr('Suelta el aire…', 'Breathe out…')][_phase.clamp(0, 2)];
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF3B4A8C),
        title: Text(tr('Respira con Michi', 'Breathe with Michi'), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Stack(children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFEEF3FF), C.t(0xFFFCE4F1)]),
            ),
          ),
        ),
        Positioned.fill(child: IgnorePointer(child: StoryParticles(fx: _done ? StoryFx.hearts : StoryFx.bubbles, count: 12))),
        SafeArea(
          child: Column(children: [
            const Spacer(),
            AnimatedBuilder(
              animation: _c,
              builder: (_, __) {
                final f = _running ? _fill : (_done ? 0.6 : 0.3);
                return SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(alignment: Alignment.center, children: [
                    // Halo que crece al inspirar.
                    Container(
                      width: 150 + 140 * f,
                      height: 150 + 140 * f,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          const Color(0xFFB79CEB).withOpacity(0.45),
                          C.t(0xFFFFC2DC).withOpacity(0.25),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                    Container(
                      width: 120 + 100 * f,
                      height: 120 + 100 * f,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.6)),
                    ),
                    Transform.scale(
                      scale: 0.85 + 0.25 * f,
                      child: Img(_done ? 'michi_heart' : 'michi_calm', size: 160, fallback: Icons.pets_rounded),
                    ),
                  ]),
                );
              },
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(label,
                  key: ValueKey(label),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF3B4A8C))),
            ),
            const SizedBox(height: 8),
            if (_running)
              Text('${_cycle + 1} / $_cycles', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.muted))
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Text(
                  tr('Inspira 4 segundos, aguanta 2 y suelta el aire en 6. Ayuda a calmar los nervios y el dolor.',
                      'Breathe in for 4 seconds, hold for 2 and breathe out for 6. It helps calm nerves and pain.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w600, color: C.muted),
                ),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7B4FD6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
                  onPressed: _running ? () => setState(() {
                        _running = false;
                        _c.stop();
                      }) : _start,
                  child: Text(
                    _running ? tr('Parar', 'Stop') : (_done ? tr('Repetir', 'Repeat') : tr('Empezar', 'Get started')),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ───────────────────────────── Cartas de Michi ─────────────────────────────

/// Al empezar cada mes, Michi te escribe una carta sobre el mes anterior.
class MichiLetters {
  MichiLetters._();

  static DateTime get lastMonth {
    final n = DateTime.now();
    return DateTime(n.year, n.month - 1, 1);
  }

  static String _key(DateTime m) => 'michi_letter_${m.year}_${m.month}';

  /// Carta nueva sin leer (la primera semana del mes, si ya usabas la app).
  static Future<bool> hasNew() async {
    if (DateTime.now().day > 7) return false;
    final m = lastMonth;
    final any = AppStore.instance.logs.entries.any((e) {
      final d = DateTime.tryParse(e.key);
      return d != null && !e.value.isEmpty && d.isBefore(DateTime(m.year, m.month + 1, 1));
    });
    if (!any) return false;
    final p = await SharedPreferences.getInstance();
    return !(p.getBool(_key(m)) ?? false);
  }

  static Future<void> markRead(DateTime m) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key(m), true);
  }

  static const _posts = ['post_garden', 'post_bridge', 'post_hill', 'post_castle', 'post_beach', 'post_candy', 'post_lake', 'post_moon'];

  static String background(DateTime m) => _posts[(m.month + m.year) % _posts.length];

  /// Texto de la carta de ese mes.
  static List<String> letter(DateTime m) {
    final logs = AppStore.instance.logs.entries.where((e) {
      final d = DateTime.tryParse(e.key);
      return d != null && d.year == m.year && d.month == m.month && !e.value.isEmpty;
    }).map((e) => e.value).toList();
    final name = AppStore.instance.name.trim().split(RegExp(r'\s+')).first;
    final out = <String>[
      name.isEmpty ? tr('¡Hola!', 'Hi!') : tr('Querida {}:', 'Dear {},').replaceFirst('{}', name),
    ];
    final month = L.month(m.month).toLowerCase();
    if (logs.isEmpty) {
      out.add(tr('En {} casi no nos vimos… Te he echado de menos. ¡Vuelve pronto, te espero!', "In {} we hardly saw each other… I missed you. Come back soon, I'm waiting for you!")
          .replaceFirst('{}', month));
    } else {
      out.add(tr('En {} nos vimos {} días. ¡Me encanta que vengas a verme!', 'In {} we saw each other on {} days. I love it when you visit me!')
          .replaceFirst('{}', month)
          .replaceFirst('{}', '${logs.length}'));
      final counts = List.filled(6, 0);
      for (final l in logs) {
        if (l.mood >= 1 && l.mood <= 5) counts[l.mood]++;
      }
      var best = 0;
      for (var i = 1; i <= 5; i++) {
        if (counts[i] > (best == 0 ? 0 : counts[best])) best = i;
      }
      if (best > 0) {
        out.add([
          tr('La mayoría de días te sentiste bien. ¡Qué alegría verte así! ✨', 'Most days you felt good. It made me so happy to see you like that! ✨'),
          tr('Muchos días estabas cansada. Recuerda que descansar también es cuidarte 💤', 'You were tired on many days. Remember that resting is self-care too 💤'),
          tr('Hubo bastantes días con dolor. Fuiste muy valiente, y yo estuve contigo 💗', 'There were quite a few days with pain. You were very brave, and I was with you 💗'),
          tr('Casi siempre estuviste tranquila. Esa paz tuya me encanta 🌸', 'You were calm almost all the time. I love that peace of yours 🌸'),
          tr('¡Estuviste motivadísima! Nadie te paraba 💪', 'You were so motivated! Nothing could stop you 💪'),
        ][best - 1]);
      }
      final happy = logs.where((l) => (l.mood == 1 || l.mood == 5) && l.note.trim().isNotEmpty).toList();
      if (happy.isNotEmpty) {
        out.add(tr('Tu mejor momento: «{}» 🌟', 'Your best moment: "{}" 🌟').replaceFirst('{}', happy.last.note.trim()));
      }
      final water = logs.where((l) => l.water >= AppStore.instance.waterGoal).length;
      if (water >= 5) {
        out.add(tr('Y bebiste tu agua {} días. ¡Así me gusta! 💧', 'And you drank your water on {} days. That\'s the way! 💧').replaceFirst('{}', '$water'));
      }
    }
    out.add(tr('Este mes que empieza, cuídate mucho. Yo estaré aquí todos los días.', "This new month, take good care of yourself. I'll be here every day."));
    out.add(tr('Te quiero mucho,', 'Lots of love,'));
    return out;
  }
}

class MichiLetterScreen extends StatefulWidget {
  const MichiLetterScreen({super.key});

  @override
  State<MichiLetterScreen> createState() => _MichiLetterScreenState();
}

class _MichiLetterScreenState extends State<MichiLetterScreen> with SingleTickerProviderStateMixin {
  late DateTime _m = MichiLetters.lastMonth;
  late final AnimationController _open = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void initState() {
    super.initState();
    MichiLetters.markRead(_m);
  }

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final n = DateTime(_m.year, _m.month + delta, 1);
    final now = DateTime.now();
    if (!n.isBefore(DateTime(now.year, now.month, 1))) return; // solo meses terminados
    HapticFeedback.selectionClick();
    setState(() => _m = n);
    _open.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final lines = MichiLetters.letter(_m);
    final canNext = DateTime(_m.year, _m.month + 1, 1).isBefore(DateTime(DateTime.now().year, DateTime.now().month, 1));
    return Scaffold(
      backgroundColor: C.t(0xFFFFF4F8),
      appBar: AppBar(
        backgroundColor: C.t(0xFFFFF4F8),
        elevation: 0,
        foregroundColor: C.pinkDark,
        title: Text(tr('Cartas de Michi', 'Letters from Michi'), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 30), children: [
        Row(children: [
          IconButton(onPressed: () => _go(-1), icon: Icon(Icons.chevron_left_rounded, color: C.pinkDark)),
          Expanded(
            child: Text('${L.month(_m.month)} ${_m.year}',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: C.text)),
          ),
          IconButton(
              onPressed: canNext ? () => _go(1) : null,
              icon: Icon(Icons.chevron_right_rounded, color: canNext ? C.pinkDark : C.pinkLine)),
        ]),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _open,
          builder: (_, child) {
            final t = Curves.easeOutBack.transform(_open.value.clamp(0.0, 1.0));
            return Opacity(opacity: _open.value.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(0, 40 * (1 - t)), child: child));
          },
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF2),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(
                height: 170,
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset('assets/go/${MichiLetters.background(_m)}.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: C.lavenderSoft)),
                  const Positioned.fill(child: IgnorePointer(child: StoryParticles(fx: StoryFx.hearts, count: 8))),
                  const Align(alignment: Alignment.bottomCenter, child: Img('michi_letter', size: 120, fallback: Icons.pets_rounded)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (var i = 0; i < lines.length; i++) ...[
                    Text(lines[i],
                        style: TextStyle(
                          fontSize: i == 0 ? 18 : 15.5,
                          height: 1.5,
                          fontWeight: i == 0 ? FontWeight.w900 : FontWeight.w600,
                          color: i == 0 ? C.pinkDark : C.text,
                          fontStyle: i == 0 ? FontStyle.normal : FontStyle.italic,
                        )),
                    const SizedBox(height: 8),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('Michi 🐾', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: C.pinkDark)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

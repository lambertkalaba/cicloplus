import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/store.dart';
import '../strings.dart';
import '../widgets/michi_events.dart';
import '../widgets/michi_logic.dart';
import '../widgets/ui.dart';
import 'michi_advent.dart';
import 'more.dart' show DiaryScreen;
import 'michi_extras.dart';
import 'michi_stories.dart' show MichiStories, StoryParticles, StoryFx;

/// Contadores pequeños que usan los logros.
class MichiCounters {
  MichiCounters._();

  static Future<int> get(String k) async => (await SharedPreferences.getInstance()).getInt('michi_count_$k') ?? 0;

  static Future<void> add(String k) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('michi_count_$k', (p.getInt('michi_count_$k') ?? 0) + 1);
  }
}

// ───────────────────────────── Kit de la regla ─────────────────────────────

/// ¿Hoy toca el kit? (días de regla o con dolor).
bool michiKitToday() {
  final st = AppStore.instance;
  if (st.goal == 'pregnancy' && st.pregnancyWeek != null) return false;
  final l = AppStore.instance.logs[dayKey(DateTime.now())];
  if (l != null && (l.pain >= 2 || l.mood == 3)) return true;
  return MichiLogic.phaseKey == 'period';
}

Future<void> showMichiPeriodKit(BuildContext context) {
  HapticFeedback.lightImpact();
  final tips = [
    ('🫖', tr('Calor en la tripa', 'Warmth on your tummy'), tr('Una bolsa de agua caliente relaja los músculos y alivia el dolor.', 'A hot water bottle relaxes the muscles and eases the pain.')),
    ('🍵', tr('Algo calentito', 'Something warm'), tr('Una infusión o agua templada te ayudará a sentirte mejor.', 'A herbal tea or warm water will help you feel better.')),
    ('🧘‍♀️', tr('Estiramientos suaves', 'Gentle stretches'), tr('La postura del niño o caminar un poco puede aliviar los calambres.', "Child's pose or a short walk can ease cramps.")),
    ('🛌', tr('Descansa sin culpa', 'Rest without guilt'), tr('Tu cuerpo está trabajando mucho. Hoy está bien ir más despacio.', "Your body is working hard. It's okay to slow down today.")),
    ('🥬', tr('Come algo con hierro', 'Eat something with iron'), tr('Las legumbres, las espinacas o la carne te ayudan a recuperar el hierro que pierdes.', 'Pulses, spinach or meat help you recover the iron you lose.')),
  ];
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: C.t(0xFFFFF4F8),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Img('michi_period', size: 70, fallback: Icons.pets_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: Text(tr('Mi kit para cuidarte hoy 🩷', 'My kit to look after you today 🩷'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: C.pinkDark)),
            ),
          ]),
          const SizedBox(height: 10),
          for (final t in tips)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.$1, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.$2, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: C.text)),
                    const SizedBox(height: 2),
                    Text(t.$3, style: const TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w600, color: C.muted)),
                  ]),
                ),
              ]),
            ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7B4FD6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23))),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MichiBreatheScreen()));
              },
              icon: const Text('🌬️'),
              label: Text(tr('Respira con Michi', 'Breathe with Michi'), style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 6),
          Text(tr('Si el dolor es muy fuerte o no es normal para ti, consulta con tu médico.', 'If the pain is very strong or unusual for you, see your doctor.'),
              style: const TextStyle(fontSize: 11.5, color: C.muted, fontWeight: FontWeight.w600)),
        ]),
      ),
    ),
  );
}

// ───────────────────────────── Diario con Michi ─────────────────────────────

String michiReply(DayLog? l, String text) {
  final i = text.length % 3;
  final mood = l?.mood ?? 0;
  if (mood == 2 || mood == 3 || (l?.pain ?? 0) >= 2) {
    return [
      tr('Gracias por contármelo. Te mando un abrazo enorme y un ronroneo 💗', 'Thank you for telling me. Sending you a huge hug and a purr 💗'),
      tr('Los días difíciles también pasan. Estoy aquí contigo 🌙', "Difficult days pass too. I'm here with you 🌙"),
      tr('Hoy cuídate mucho, ¿vale? Te lo mereces todo 🩷', 'Look after yourself today, okay? You deserve everything 🩷'),
    ][i];
  }
  if (mood == 1 || mood == 5) {
    return [
      tr('¡Qué bonito! Me encanta verte así de feliz ✨', 'How lovely! I love seeing you this happy ✨'),
      tr('¡Guardo este momento en mi cajita de recuerdos! 🐾', "I'm keeping this moment in my little memory box! 🐾"),
      tr('¡Sigue así, hoy brillas! 🌟', 'Keep it up, you shine today! 🌟'),
    ][i];
  }
  return [
    tr('Gracias por escribirme. Me encanta leerte 💌', 'Thanks for writing to me. I love reading your words 💌'),
    tr('Lo apunto en mi diario de gatito. ¡Mañana más! 🐾', "I'm writing it in my kitty diary. More tomorrow! 🐾"),
    tr('Qué bien que me lo cuentes. Te escucho siempre 🌸', "I'm glad you told me. I always listen 🌸"),
  ][i];
}

class MichiDiaryScreen extends StatefulWidget {
  const MichiDiaryScreen({super.key});

  @override
  State<MichiDiaryScreen> createState() => _MichiDiaryScreenState();
}

class _MichiDiaryScreenState extends State<MichiDiaryScreen> {
  late final TextEditingController _t = TextEditingController(text: AppStore.instance.logs[dayKey(DateTime.now())]?.note ?? '');
  String? _reply;

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _t.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    final today = dateOnly(DateTime.now());
    await AppStore.instance.updateLog(today, (l) => l.note = text);
    if (!mounted) return;
    setState(() => _reply = michiReply(AppStore.instance.logs[dayKey(today)], text));
  }

  @override
  Widget build(BuildContext context) {
    final entries = AppStore.instance.logs.entries.where((e) => e.value.note.trim().isNotEmpty).toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return Scaffold(
      backgroundColor: C.t(0xFFFFF4F8),
      appBar: AppBar(
        backgroundColor: C.t(0xFFFFF4F8),
        foregroundColor: C.pinkDark,
        elevation: 0,
        title: Text(tr('Diario con Michi', 'Diary with Michi'), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 30), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: card(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Img('michi_letter', size: 56, fallback: Icons.pets_rounded),
              const SizedBox(width: 8),
              Expanded(
                child: Text(tr('¿Qué tal tu día? Cuéntamelo en una frase 💬', 'How was your day? Tell me in one sentence 💬'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: C.text)),
              ),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: _t,
              maxLines: 5,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: tr('Hoy me he sentido…', 'Today I felt…'),
                filled: true,
                fillColor: const Color(0xFFFFF8FB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: C.pinkLine)),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: C.pink),
                onPressed: _save,
                child: Text(tr('Contárselo a Michi', 'Tell Michi'), style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _reply == null
                  ? const SizedBox.shrink()
                  : Container(
                      key: ValueKey(_reply),
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: C.pinkSoft, borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        const Text('🐱', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_reply!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.pinkDark))),
                      ]),
                    ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        if (entries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Row(children: [
              Expanded(child: Text(tr('Lo que me has contado', "What you've told me"), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: C.pinkDark))),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiaryScreen())),
                child: Text(tr('Ver todo en Mi diario ›', 'See all in My diary ›'), style: TextStyle(fontWeight: FontWeight.w900, color: C.pink)),
              ),
            ]),
          ),
        for (final e in entries.take(5))
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: card(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(L.dateShort(DateTime.parse(e.key)), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: C.pink)),
              const SizedBox(height: 4),
              Text(e.value.note, style: const TextStyle(fontSize: 14.5, height: 1.4, fontWeight: FontWeight.w600, color: C.text)),
            ]),
          ),
      ]),
    );
  }
}

// ───────────────────────────── Retos de 7 días ─────────────────────────────

class MichiChallenge {
  const MichiChallenge(this.id, this.emoji, this.title, this.hint);
  final String id;
  final String emoji;
  final String Function() title;
  final String Function() hint;
}

class MichiChallenges {
  MichiChallenges._();

  static final all = <MichiChallenge>[
    MichiChallenge('water', '💧', () => tr('7 días bebiendo agua', '7 days drinking water'), () => tr('Bebe tus vasos de agua cada día.', 'Drink your glasses of water every day.')),
    MichiChallenge('sleep', '🌙', () => tr('7 días a la cama antes de las 12', '7 days in bed before midnight'), () => tr('Acuéstate antes de medianoche.', 'Go to bed before midnight.')),
    MichiChallenge('walk', '🚶‍♀️', () => tr('7 días caminando 20 minutos', '7 days walking 20 minutes'), () => tr('Un paseo de 20 minutos al día.', 'A 20-minute walk every day.')),
    MichiChallenge('screen', '📵', () => tr('7 noches sin móvil antes de dormir', '7 nights without your phone before bed'), () => tr('Deja el móvil 30 minutos antes de dormir.', 'Put your phone away 30 minutes before sleep.')),
    MichiChallenge('breathe', '🌬️', () => tr('7 días respirando con Michi', '7 days breathing with Michi'), () => tr('Un minuto de respiración al día.', 'One minute of breathing a day.')),
    MichiChallenge('kind', '💗', () => tr('7 días diciéndote algo bonito', '7 days saying something kind to yourself'), () => tr('Cada día, una frase amable para ti.', 'Every day, one kind sentence for yourself.')),
  ];

  static Future<(String?, Set<String>)> state() async {
    final p = await SharedPreferences.getInstance();
    return (p.getString('michi_ch_id'), (p.getStringList('michi_ch_days') ?? const <String>[]).toSet());
  }

  static Future<void> start(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('michi_ch_id', id);
    await p.setStringList('michi_ch_days', []);
  }

  static Future<void> stop() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('michi_ch_id');
    await p.remove('michi_ch_days');
  }

  /// Marca hoy. Devuelve true si con esto se completa el reto.
  static Future<bool> checkToday() async {
    final p = await SharedPreferences.getInstance();
    final days = (p.getStringList('michi_ch_days') ?? <String>[]).toSet()..add(dayKey(DateTime.now()));
    await p.setStringList('michi_ch_days', days.toList());
    if (days.length >= 7) {
      final done = (p.getStringList('michi_ch_done') ?? <String>[])..add(p.getString('michi_ch_id') ?? '');
      await p.setStringList('michi_ch_done', done);
      await p.remove('michi_ch_id');
      await p.remove('michi_ch_days');
      return true;
    }
    return false;
  }

  static Future<int> completed() async => ((await SharedPreferences.getInstance()).getStringList('michi_ch_done') ?? const []).length;
}

class MichiChallengeScreen extends StatefulWidget {
  const MichiChallengeScreen({super.key});

  @override
  State<MichiChallengeScreen> createState() => _MichiChallengeScreenState();
}

class _MichiChallengeScreenState extends State<MichiChallengeScreen> {
  String? _id;
  Set<String> _days = {};
  bool _celebrate = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await MichiChallenges.state();
    if (mounted) {
      setState(() {
        _id = s.$1;
        _days = s.$2;
      });
    }
  }

  Future<void> _check() async {
    HapticFeedback.mediumImpact();
    final done = await MichiChallenges.checkToday();
    if (done) setState(() => _celebrate = true);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final ch = MichiChallenges.all.where((c) => c.id == _id).firstOrNull;
    final todayDone = _days.contains(dayKey(DateTime.now()));
    return Scaffold(
      backgroundColor: const Color(0xFFF2FBF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2FBF5),
        foregroundColor: C.emeraldDark,
        elevation: 0,
        title: Text(tr('Retos de Michi', "Michi's challenges"), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Stack(children: [
        if (_celebrate) const Positioned.fill(child: IgnorePointer(child: StoryParticles(fx: StoryFx.balloons, count: 16))),
        ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 30), children: [
          if (_celebrate)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: card(),
              child: Row(children: [
                const Img('michi_party', size: 70, fallback: Icons.pets_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(tr('¡Reto completado! Estoy orgullosísimo de ti 🏆', 'Challenge complete! I am so proud of you 🏆'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.emeraldDark)),
                ),
              ]),
            ),
          if (ch != null) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: card(),
              child: Column(children: [
                Text(ch.emoji, style: const TextStyle(fontSize: 46)),
                const SizedBox(height: 6),
                Text(ch.title(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: C.text)),
                const SizedBox(height: 4),
                Text(ch.hint(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: C.muted)),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < 7; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _days.length ? C.green : const Color(0xFFE2F3E2),
                      ),
                      child: Center(
                        child: Text(i < _days.length ? '🐾' : '${i + 1}',
                            style: TextStyle(fontSize: i < _days.length ? 15 : 12, fontWeight: FontWeight.w900, color: C.emeraldDark)),
                      ),
                    ),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: C.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                    onPressed: todayDone ? null : _check,
                    child: Text(todayDone ? tr('¡Hecho hoy! Vuelve mañana 🐾', 'Done today! Come back tomorrow 🐾') : tr('¡Hecho hoy!', 'Done today!'),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await MichiChallenges.stop();
                    _load();
                  },
                  child: Text(tr('Dejar este reto', 'Leave this challenge'), style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Text(tr('Elige un reto y Michi te acompaña 7 días. ¡Sin prisas: cuenta cada día que lo cumplas!',
                      'Choose a challenge and Michi will keep you company for 7 days. No rush: every day you do it counts!'),
                  style: const TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w600, color: C.text)),
            ),
            for (final c in MichiChallenges.all)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    leading: Text(c.emoji, style: const TextStyle(fontSize: 28)),
                    title: Text(c.title(), style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text(c.hint()),
                    trailing: const Icon(Icons.play_arrow_rounded, color: C.green),
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await MichiChallenges.start(c.id);
                      setState(() => _celebrate = false);
                      _load();
                    },
                  ),
                ),
              ),
          ],
        ]),
      ]),
    );
  }
}

// ───────────────────────────── Logros ─────────────────────────────

class MichiBadge {
  const MichiBadge(this.id, this.emoji, this.title, this.desc);
  final String id;
  final String emoji;
  final String Function() title;
  final String Function() desc;
}

class MichiBadges {
  MichiBadges._();

  static final _base = <MichiBadge>[
    MichiBadge('first', '🐾', () => tr('Primer paso', 'First step'), () => tr('Registra tu primer día.', 'Log your first day.')),
    MichiBadge('week', '🔥', () => tr('Una semana juntas', 'One week together'), () => tr('Racha de 7 días.', '7-day streak.')),
    MichiBadge('month', '👑', () => tr('Un mes sin parar', 'A month non-stop'), () => tr('Racha de 30 días.', '30-day streak.')),
    MichiBadge('hundred', '💯', () => tr('100 días', '100 days'), () => tr('100 días registrados en total.', '100 days logged in total.')),
    MichiBadge('water', '💧', () => tr('Hidratada', 'Hydrated'), () => tr('30 días cumpliendo tu agua.', '30 days meeting your water goal.')),
    MichiBadge('breathe', '🌬️', () => tr('Zen', 'Zen'), () => tr('Respira con Michi 10 veces.', 'Breathe with Michi 10 times.')),
    MichiBadge('diary', '📔', () => tr('Querido diario', 'Dear diary'), () => tr('Escribe 7 días en el diario.', 'Write in the diary on 7 days.')),
    MichiBadge('challenge', '🏆', () => tr('Campeona', 'Champion'), () => tr('Completa un reto de 7 días.', 'Complete a 7-day challenge.')),
    MichiBadge('flowers', '💐', () => tr('Ramo de flores', 'Bouquet'), () => tr('Recibe flores de Michi 5 veces.', 'Receive flowers from Michi 5 times.')),
    MichiBadge('letter', '💌', () => tr('Correspondencia', 'Pen pals'), () => tr('Lee una carta de Michi.', 'Read a letter from Michi.')),
  ];

  static final _advent = MichiBadge('advent', '🎄', () => tr('Navidad completa', 'Complete Christmas'), () => tr('Abre las 24 puertitas del Adviento.', 'Open all 24 Advent doors.'));

  /// Próxima fiesta de su país en los próximos 14 días (o hoy).
  static (DateTime, MichiEvent)? nextFest() {
    final t = dateOnly(DateTime.now());
    for (var i = 0; i <= 14; i++) {
      final d = addDays(t, i);
      final e = MichiEvents.holiday(d);
      if (e != null) return (d, e);
    }
    return null;
  }

  /// Logro de temporada: el Adviento mientras dura; después, la próxima
  /// fiesta que esté a 14 días o menos. Si no hay ninguna cerca, no sale.
  static MichiBadge? get seasonal {
    if (MichiAdvent.visible) return _advent;
    final f = nextFest();
    if (f == null) return null;
    final (d, e) = f;
    final today = dateOnly(DateTime.now());
    return MichiBadge(
      'fest_${dayKey(d)}',
      e.emoji,
      () => tr('Fiesta con Michi', 'Party with Michi'),
      () => d == today
          ? tr('¡Hoy es el día! Celébralo con Michi.', "Today's the day! Celebrate with Michi.")
          : tr('Celébralo con Michi el {}.', 'Celebrate it with Michi on {}.').replaceFirst('{}', L.dateShort(d)),
    );
  }

  static List<MichiBadge> get all => [..._base, if (seasonal case final b?) b];

  static Future<Set<String>> unlocked() async {
    final s = AppStore.instance;
    final logs = s.logs.values.where((l) => !l.isEmpty).toList();
    final streak = MichiLogic.streak;
    final p = await SharedPreferences.getInstance();
    final best = (p.getInt('michi_best_streak') ?? 0) < streak ? streak : (p.getInt('michi_best_streak') ?? 0);
    if (best != (p.getInt('michi_best_streak') ?? 0)) await p.setInt('michi_best_streak', best);
    final adv = await MichiAdvent.opened();
    // Si hoy es fiesta y ha abierto la app, queda celebrada.
    final today = dateOnly(DateTime.now());
    if (MichiEvents.holiday(today) != null && !p.containsKey('michi_fest_${dayKey(today)}')) {
      await p.setBool('michi_fest_${dayKey(today)}', true);
    }
    final fest = MichiAdvent.visible ? null : nextFest();
    final out = <String>{
      if (logs.isNotEmpty) 'first',
      if (best >= 7) 'week',
      if (best >= 30) 'month',
      if (logs.length >= 100) 'hundred',
      if (logs.where((l) => l.water >= s.waterGoal).length >= 30) 'water',
      if (await MichiCounters.get('breathe') >= 10) 'breathe',
      if (s.logs.values.where((l) => l.note.trim().isNotEmpty).length >= 7) 'diary',
      if (await MichiChallenges.completed() >= 1) 'challenge',
      if (await MichiCounters.get('flowers') >= 5) 'flowers',
      if (adv.length >= 24) 'advent',
      if (fest != null && p.containsKey('michi_fest_${dayKey(fest.$1)}')) 'fest_${dayKey(fest.$1)}',
      if (p.getKeys().any((k) => k.startsWith('michi_letter_'))) 'letter',
    };
    return out;
  }

  /// Logros nuevos que aún no se han enseñado.
  static Future<bool> hasNew() async {
    final u = await unlocked();
    final p = await SharedPreferences.getInstance();
    final seen = (p.getStringList('michi_badges_seen') ?? const []).toSet();
    return u.difference(seen).isNotEmpty;
  }

  static Future<void> markSeen(Set<String> u) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('michi_badges_seen', u.toList());
  }
}

class MichiBadgesScreen extends StatefulWidget {
  const MichiBadgesScreen({super.key});

  @override
  State<MichiBadgesScreen> createState() => _MichiBadgesScreenState();
}

class _MichiBadgesScreenState extends State<MichiBadgesScreen> {
  Set<String> _u = {};
  Set<String> _fresh = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await MichiBadges.unlocked();
    final p = await SharedPreferences.getInstance();
    final seen = (p.getStringList('michi_badges_seen') ?? const []).toSet();
    await MichiBadges.markSeen(u);
    if (mounted) {
      setState(() {
        _u = u;
        _fresh = u.difference(seen);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAEE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFAEE),
        foregroundColor: const Color(0xFFB7791F),
        elevation: 0,
        title: Text(tr('Logros de Michi', "Michi's badges"), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Stack(children: [
        if (_fresh.isNotEmpty) const Positioned.fill(child: IgnorePointer(child: StoryParticles(fx: StoryFx.sparkles, count: 14))),
        ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 30), children: [
          Text('${MichiBadges.all.where((b) => _u.contains(b.id)).length} / ${MichiBadges.all.length}',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFB7791F))),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.7,
            children: [
              for (final b in MichiBadges.all)
                _badge(b, _u.contains(b.id), _fresh.contains(b.id)),
            ],
          ),
        ]),
      ]),
    );
  }

  Widget _badge(MichiBadge b, bool on, bool fresh) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: fresh ? 0.3 : 1, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (_, v, c) => Transform.scale(scale: v, child: c),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: on ? Colors.white : const Color(0xFFF1EDE4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: fresh ? const Color(0xFFFFC94D) : Colors.transparent, width: 2),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Opacity(opacity: on ? 1 : 0.3, child: Text(on ? b.emoji : '🔒', style: const TextStyle(fontSize: 34))),
          const SizedBox(height: 4),
          Text(b.title(), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: on ? C.text : C.muted)),
          const SizedBox(height: 2),
          Text(b.desc(), textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: C.muted, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
import '../cicloplus_host.dart' show CicloData;
import '../data/store.dart';
import '../services/notifications.dart';
import '../strings.dart';
import '../widgets/ui.dart';
import 'more.dart';
import '../widgets/ciclo_date_picker.dart';
import '../widgets/premium.dart' show Premium;

/// Bienvenida: una pregunta por pantalla (diseño hecho con ChatGPT).
/// Las preguntas dependen del objetivo y casi todas se pueden saltar con
/// «No lo sé», que usa los valores más habituales (ciclo 28, regla 5).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  int _i = 0;
  String _goal = 'track';
  DateTime? _last;
  int _period = 5;
  int _cycle = 28;
  String _regular = ''; // yes | no | unknown
  String _contra = ''; // none | pill | iud | condom | other
  final Set<String> _symptoms = {};
  int _birthYear = 0;
  bool _peri = false;
  bool _busy = false;

  int get _age => _birthYear == 0 ? 0 : DateTime.now().year - _birthYear;

  /// Preguntas que tocan según lo que va respondiendo.
  List<String> get _steps => [
        'name',
        'goal',
        if (_goal != 'pregnancy') ...['last', 'period', 'cycle', 'regular'],
        if (_goal == 'track') 'contra',
        'symptoms',
        'birth',
        if (_goal != 'pregnancy' && _age >= 45) 'peri',
        'notif',
      ];

  String get _key => _steps[_i.clamp(0, _steps.length - 1)];

  static const _img = {
    'name': 'michi_happy',
    'goal': 'michi_heart',
    'last': 'michi_flower',
    'period': 'michi_happy',
    'cycle': 'michi_motivated',
    'regular': 'michi_calm',
    'contra': 'michi_heart',
    'symptoms': 'michi_calm',
    'birth': 'michi_party',
    'peri': 'michi_calm',
    'notif': 'michi_letter',
  };

  String _title(String k) => switch (k) {
        'name' => tr('¡Hola! ¿Cómo te llamas?', 'Hi! What is your name?'),
        'goal' => tr('¿Para qué quieres CicloPlus?', 'What do you want to use CicloPlus for?'),
        'last' => tr('¿Cuándo empezó tu última regla?', 'When did your last period start?'),
        'period' => tr('¿Cuánto te suele durar la regla?', 'How long does your period usually last?'),
        'cycle' => tr('¿Cada cuántos días te viene?', 'How many days is your cycle?'),
        'regular' => tr('¿Tu ciclo suele ser regular?', 'Is your cycle usually regular?'),
        'contra' => tr('¿Usas algún anticonceptivo?', 'Do you use birth control?'),
        'symptoms' => tr('¿Qué sueles notar?', 'What do you usually notice?'),
        'birth' => tr('¿En qué año naciste?', 'What year were you born?'),
        'peri' => tr('¿Tus ciclos han empezado a cambiar?', 'Have your cycles started to change?'),
        _ => tr('¿Te avisamos?', 'Shall we remind you?'),
      };

  String? _hint(String k) => switch (k) {
        'name' => tr('Así Michi te puede saludar. Es opcional.', 'So Michi can greet you. Optional.'),
        'cycle' => tr('Desde el primer día de una regla hasta el primer día de la siguiente.', 'From the first day of one period to the first day of the next.'),
        'symptoms' => tr('Elige todo lo que quieras. Saldrán primero al registrar tu día.', 'Pick as many as you like. They will show first when you log your day.'),
        'birth' => tr('Nos ayuda a darte consejos para tu edad. Es opcional.', 'Helps us give advice for your age. Optional.'),
        'peri' => tr('Ciclos más cortos o más largos, sofocos o sudores por la noche.', 'Shorter or longer cycles, hot flushes or night sweats.'),
        'notif' => tr('Te avisamos antes de la regla, en tus días fértiles y para registrar tu día. Puedes cambiarlo cuando quieras.',
            'We remind you before your period, on fertile days and to log your day. You can change it anytime.'),
        _ => null,
      };

  /// «No lo sé / Saltar» con el valor que se usará.
  String? _skipLabel(String k) => switch (k) {
        'last' => tr('No me acuerdo', "I don't remember"),
        'period' => tr('No lo sé (usaremos 5 días)', "I don't know (we'll use 5 days)"),
        'cycle' => tr('No lo sé (usaremos 28 días)', "I don't know (we'll use 28 days)"),
        'birth' => tr('Prefiero no decirlo', "I'd rather not say"),
        'symptoms' => tr('Saltar', 'Skip'),
        _ => null,
      };

  void _skip() {
    switch (_key) {
      case 'last':
        _last = null;
      case 'period':
        _period = 5;
      case 'cycle':
        _cycle = 28;
      case 'birth':
        _birthYear = 0;
      case 'symptoms':
        _symptoms.clear();
    }
    _next();
  }

  Future<void> _next() async {
    if (_i < _steps.length - 1) {
      setState(() => _i++);
    } else {
      await _start(askNotif: true);
    }
  }

  Future<void> _start({required bool askNotif}) async {
    if (_busy) return;
    _busy = true;
    final s = AppStore.instance;
    s.name = _name.text.trim();
    s.defaultCycle = _cycle;
    s.defaultPeriod = _period;
    s.favSymptoms = _symptoms.toList();
    s.contraception = _contra;
    s.birthYear = _birthYear;
    if (_peri) {
      s.perimenopause = true;
      for (final x in [tr('Sofocos', 'Hot flushes'), tr('Sudores nocturnos', 'Night sweats')]) {
        if (!s.customSymptoms.contains(x)) s.customSymptoms.add(x);
      }
    }
    if (_contra == 'pill') s.reminders.pill = true;
    if (_goal != 'pregnancy' && _last != null) {
      await s.addPeriod(dateOnly(_last!), length: _period);
    }
    if (_regular == 'no') {
      CicloData.instance.irregular = true;
      try {
        await SettingsService().saveIrregularCycleMode(true);
      } catch (_) {}
    }
    s.goal = _goal == 'pregnancy' ? 'track' : _goal;
    if (_goal == 'pregnancy' && mounted) {
      // Sin la fecha no se puede saber cómo está el bebé: se pregunta aquí.
      if (await PregnancyScreen.setup(context) && mounted) await PregnancyScreen.askBabies(context);
    }
    s.onboarded = true;
    await s.commit();
    if (askNotif) await Notifier.instance.requestPermission();
    await Notifier.instance.reschedule();
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final k = _key;
    final last = _i == steps.length - 1;
    final skip = _skipLabel(k);
    return Scaffold(
      body: PinkBackground(
        child: Column(
          children: [
            const GreenHeader(bellDot: false),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                children: [
                  Text(tr('Pregunta {} de {}', 'Question {} of {}').replaceFirst('{}', '${_i + 1}').replaceFirst('{}', '${steps.length}'),
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: C.pinkDark)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var j = 0; j < steps.length; j++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3.5),
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(color: j <= _i ? C.pink : C.pinkLine, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      key: ValueKey(k),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      decoration: card(radius: 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Michi animando + la pregunta en un bocadillo.
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Img(_img[k] ?? 'michi_happy', size: 92, fallback: Icons.pets_rounded),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                                  decoration: BoxDecoration(color: C.pinkSoft, borderRadius: BorderRadius.circular(22)),
                                  child: Text(_title(k),
                                      style: TextStyle(fontSize: 20, height: 1.15, fontWeight: FontWeight.w900, color: C.pinkDark)),
                                ),
                              ),
                            ],
                          ),
                          if (_hint(k) != null) ...[
                            const SizedBox(height: 10),
                            Text(_hint(k)!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, height: 1.35, color: C.muted)),
                          ],
                          const SizedBox(height: 16),
                          _body(k),
                          if (skip != null) ...[
                            const SizedBox(height: 14),
                            OutlinedButton(
                              onPressed: _skip,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                shape: const StadiumBorder(),
                                side: BorderSide(color: C.pink, width: 1.4),
                                backgroundColor: Colors.white,
                              ),
                              child: Text(skip, style: TextStyle(fontWeight: FontWeight.w800, color: C.pinkDark)),
                            ),
                          ],
                          const SizedBox(height: 16),
                          PinkButton(
                            label: last ? tr('Empezar', 'Get started') : tr('Siguiente', 'Next'),
                            icon: last ? Icons.favorite_rounded : Icons.chevron_right_rounded,
                            onTap: _next,
                          ),
                          if (last)
                            Center(
                              child: TextButton(
                                onPressed: () => _start(askNotif: false),
                                child: Text(tr('Ahora no', 'Not now'), style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          if (_i > 0)
                            Center(
                              child: TextButton(
                                onPressed: () => setState(() => _i--),
                                child: Text(tr('Atrás', 'Back'),
                                    style: TextStyle(color: C.pinkDark, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr('Las predicciones son estimaciones y no sirven como método anticonceptivo.',
                        'Predictions are estimates and must not be used as birth control.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11.5, color: C.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(String k) {
    switch (k) {
      case 'name':
        return TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            hintText: tr('Tu nombre (opcional)', 'Your name (optional)'),
            filled: true,
            fillColor: C.pinkBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: C.pinkLine)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: C.pinkLine)),
          ),
        );
      case 'goal':
        return Column(children: [
          for (final g in const [
            ['track', 'drop'],
            ['conceive', 'g_sprout'],
            ['pregnancy', 'g_feet'],
          ])
            _option(_goal == g[0], () => setState(() => _goal = g[0]),
                leading: Img(g[1], size: 30, fallback: Icons.favorite_rounded),
                label: goalName(g[0])),
        ]);
      case 'last':
        return InkWell(
          onTap: () async {
            final now = DateTime.now();
            final d = await showCicloDatePicker(
              context: context,
              initialDate: _last ?? now,
              firstDate: DateTime(now.year - 1),
              lastDate: now,
              helpText: tr('¿Cuándo empezó tu última regla?', 'When did your last period start?'),
            );
            if (d != null) setState(() => _last = d);
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(color: C.pinkBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: _last == null ? C.pinkLine : C.pink, width: 1.5)),
            child: Row(children: [
              Icon(Icons.calendar_month_rounded, color: C.pink),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_last == null ? tr('Elegir fecha', 'Pick a date') : L.dateLong(_last!),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _last == null ? C.muted : C.text)),
              ),
              const Icon(Icons.chevron_right, color: C.muted),
            ]),
          ),
        );
      case 'period':
        return _NumberStrip(min: 1, max: 12, value: _period, onChanged: (v) => setState(() => _period = v));
      case 'cycle':
        return _NumberStrip(min: 18, max: 45, value: _cycle, onChanged: (v) => setState(() => _cycle = v));
      case 'regular':
        return Column(children: [
          _option(_regular == 'yes', () => setState(() => _regular = 'yes'), leading: const Text('📅', style: TextStyle(fontSize: 24)),
              label: tr('Sí, más o menos igual cada mes', 'Yes, about the same every month')),
          _option(_regular == 'no', () => setState(() => _regular = 'no'), leading: const Text('🔀', style: TextStyle(fontSize: 24)),
              label: tr('No, cambia bastante', 'No, it changes a lot')),
          _option(_regular == 'unknown', () => setState(() => _regular = 'unknown'), leading: const Text('🤔', style: TextStyle(fontSize: 24)),
              label: tr('No lo sé', "I don't know")),
        ]);
      case 'contra':
        return Column(children: [
          for (final o in [
            ('none', '🚫', tr('Ninguno', 'None')),
            ('pill', '💊', tr('Píldora', 'Pill')),
            ('iud', '🩷', tr('DIU', 'IUD')),
            ('condom', '🛡️', tr('Preservativo', 'Condom')),
            ('other', '✨', tr('Otro', 'Other')),
          ])
            _option(_contra == o.$1, () => setState(() => _contra = o.$1),
                leading: Text(o.$2, style: const TextStyle(fontSize: 24)), label: o.$3,
                trailing: o.$1 == 'pill' ? tr('Te lo recordamos', "We'll remind you") : null),
        ]);
      case 'symptoms':
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in symptomKeys)
              GestureDetector(
                onTap: () => setState(() => _symptoms.contains(s) ? _symptoms.remove(s) : _symptoms.add(s)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                  decoration: BoxDecoration(
                    color: _symptoms.contains(s) ? C.pinkSoft : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _symptoms.contains(s) ? C.pink : C.pinkLine, width: 1.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (symptomAsset(s) != null) Img(symptomAsset(s)!, size: 26) else const Text('✨'),
                    const SizedBox(width: 6),
                    Text(symptomName(s), style: TextStyle(fontWeight: FontWeight.w800, color: _symptoms.contains(s) ? C.pinkDark : C.text)),
                  ]),
                ),
              ),
          ],
        );
      case 'birth':
        final now = DateTime.now().year;
        return _NumberStrip(
          min: now - 60,
          max: now - 10,
          value: _birthYear == 0 ? now - 28 : _birthYear,
          suffix: '',
          wide: true,
          onChanged: (v) => setState(() => _birthYear = v),
        );
      case 'peri':
        return Column(children: [
          _option(_peri, () => setState(() => _peri = true), leading: const Text('🌗', style: TextStyle(fontSize: 24)),
              label: tr('Sí, han cambiado', 'Yes, they have changed')),
          _option(!_peri, () => setState(() => _peri = false), leading: const Text('🙂', style: TextStyle(fontSize: 24)),
              label: tr('No, siguen igual', 'No, they are the same')),
        ]);
      default:
        return const Center(child: Text('🔔', style: TextStyle(fontSize: 54)));
    }
  }

  Widget _option(bool sel, VoidCallback onTap, {required Widget leading, required String label, String? trailing}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Choice(
          selected: sel,
          onTap: onTap,
          child: Row(children: [
            SizedBox(width: 40, child: Center(child: leading)),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.text))),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(trailing, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF8A6512))),
              ),
            if (sel) Padding(padding: const EdgeInsets.only(left: 6), child: Icon(Icons.check_circle_rounded, color: C.pink)),
          ]),
        ),
      );
}

/// Fila de números grandes (como en el diseño): el elegido en rosa.
class _NumberStrip extends StatefulWidget {
  const _NumberStrip({required this.min, required this.max, required this.value, required this.onChanged, this.suffix = 'días', this.wide = false});
  final int min, max, value;
  final ValueChanged<int> onChanged;
  final String suffix;
  final bool wide;

  @override
  State<_NumberStrip> createState() => _NumberStripState();
}

class _NumberStripState extends State<_NumberStrip> {
  late final ScrollController _c;
  double get _w => widget.wide ? 84 : 64;

  @override
  void initState() {
    super.initState();
    _c = ScrollController(initialScrollOffset: ((widget.value - widget.min) * (_w + 8) - 120).clamp(0, double.infinity).toDouble());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.suffix.isEmpty ? '' : (widget.value == 1 ? tr('día', 'day') : tr('días', 'days'));
    return SizedBox(
      height: 92,
      child: ListView.separated(
        controller: _c,
        scrollDirection: Axis.horizontal,
        itemCount: widget.max - widget.min + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final v = widget.min + i;
          final sel = v == widget.value;
          return GestureDetector(
            onTap: () => widget.onChanged(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: _w,
              margin: EdgeInsets.symmetric(vertical: sel ? 0 : 6),
              decoration: BoxDecoration(
                color: sel ? C.pinkSoft : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? C.pink : C.pinkLine, width: sel ? 2 : 1),
                boxShadow: [BoxShadow(color: C.pink.withOpacity(sel ? 0.18 : 0.05), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$v', style: TextStyle(fontSize: widget.wide ? 22 : 28, fontWeight: FontWeight.w900, color: sel ? C.pinkDark : C.text)),
                if (unit.isNotEmpty) Text(v == 1 ? tr('día', 'day') : tr('días', 'days'), style: TextStyle(fontSize: 12.5, color: sel ? C.pinkDark : C.muted)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

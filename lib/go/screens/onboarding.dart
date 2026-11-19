import 'package:flutter/material.dart';

import '../data/store.dart';
import '../services/notifications.dart';
import '../strings.dart';
import '../widgets/ui.dart';
import 'more.dart';
import '../widgets/ciclo_date_picker.dart';

/// Primera vez, en 3 pasos cortos: último periodo, duraciones y objetivo
/// (con el nombre opcional). Todo se puede saltar.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  int _step = 0;
  DateTime? _last;
  int _cycle = 28;
  int _period = 5;
  String _goal = 'track';
  bool _busy = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showCicloDatePicker(
      context: context,
      initialDate: _last ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      helpText: tr('¿Cuándo empezó tu último periodo?', 'When did your last period start?'),
    );
    if (d != null) setState(() => _last = d);
  }

  Future<void> _start() async {
    if (_busy) return;
    _busy = true;
    final s = AppStore.instance;
    s.name = _name.text.trim();
    s.defaultCycle = _cycle;
    s.defaultPeriod = _period;
    if (_last != null) {
      await s.addPeriod(dateOnly(_last!), length: _period);
    }
    s.goal = _goal == 'pregnancy' ? 'track' : _goal;
    if (_goal == 'pregnancy' && mounted) {
      // Sin la fecha no se puede saber cómo está el bebé: se pregunta aquí.
      await PregnancyScreen.setup(context);
    }
    s.onboarded = true;
    await s.commit();
    await Notifier.instance.requestPermission();
    await Notifier.instance.reschedule();
    _busy = false;
  }

  void _next() => _step < 2 ? setState(() => _step++) : _start();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PinkBackground(
        child: Column(
          children: [
            const GreenHeader(bellDot: false),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                children: [
                  // Avatar y Michi dando la bienvenida.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Img('avatar', size: 130, fallback: Icons.face_3),
                      SizedBox(width: 4),
                      Img('michi_happy', size: 76, fallback: Icons.pets_rounded),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(tr('¡Bienvenida a CicloPlus!', 'Welcome to CicloPlus!'),
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: C.text)),
                  const SizedBox(height: 10),
                  // Paso 1 · 2 · 3
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _step ? 26 : 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: i <= _step ? C.pink : C.pinkLine,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(tr('Paso {} de 3', 'Step {} of 3').replaceFirst('{}', '${_step + 1}'),
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.muted)),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      key: ValueKey(_step),
                      padding: const EdgeInsets.all(16),
                      decoration: card(),
                      child: [_stepDate, _stepLengths, _stepGoal][_step](),
                    ),
                  ),
                  const SizedBox(height: 22),
                  PinkButton(
                    label: _step < 2 ? tr('Siguiente', 'Next') : tr('Empezar', 'Get started'),
                    icon: _step < 2 ? Icons.arrow_forward_rounded : Icons.favorite_rounded,
                    onTap: _next,
                  ),
                  if (_step > 0)
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => _step--),
                        child: Text(tr('Atrás', 'Back'), style: TextStyle(color: C.pinkDark, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  const SizedBox(height: 6),
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

  // ── Paso 1: último periodo ──
  Widget _stepDate() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('¿Cuándo empezó tu último periodo?', 'When did your last period start?'), style: _label),
          const SizedBox(height: 10),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: C.pinkBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: C.pinkLine),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: C.pink),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _last == null ? tr('Elegir fecha', 'Pick a date') : L.dateLong(_last!),
                      style: TextStyle(fontWeight: FontWeight.w700, color: _last == null ? C.muted : C.text),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: C.muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() {
                _last = null;
                _step = 1;
              }),
              child: Text(tr('No me acuerdo', "I don't remember"), style: TextStyle(color: C.pinkDark, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      );

  // ── Paso 2: duraciones ──
  Widget _stepLengths() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(tr('Duración del ciclo', 'Cycle length'), style: _label)),
              Stepper2(value: _cycle, min: 18, max: 45, suffix: ' d', onChanged: (v) => setState(() => _cycle = v)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(tr('Duración del periodo', 'Period length'), style: _label)),
              Stepper2(value: _period, min: 2, max: 10, suffix: ' d', onChanged: (v) => setState(() => _period = v)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            decoration: BoxDecoration(color: C.pinkBg, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Icon(Icons.help_outline_rounded, color: C.pink, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('¿No lo sabes? No pasa nada: usaremos 28 y 5 días y la app aprenderá de ti.',
                        "Not sure? No problem: we'll use 28 and 5 days and the app will learn from you."),
                    style: const TextStyle(fontSize: 12.5, color: C.muted, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _cycle = 28;
                    _period = 5;
                    _step = 2;
                  }),
                  child: Text(tr('No lo sé', 'Not sure'), style: TextStyle(color: C.pinkDark, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      );

  // ── Paso 3: objetivo y nombre ──
  Widget _stepGoal() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('¿Para qué quieres CicloPlus?', 'What do you want to use CicloPlus for?'), style: _label),
          const SizedBox(height: 10),
          for (final g in const [
            ['track', 'drop'],
            ['conceive', 'g_sprout'],
            ['pregnancy', 'g_feet'],
          ]) ...[
            Choice(
              selected: _goal == g[0],
              onTap: () => setState(() => _goal = g[0]),
              child: Row(
                children: [
                  Img(g[1], size: 30, fallback: Icons.favorite_rounded),
                  const SizedBox(width: 10),
                  Expanded(child: Text(goalName(g[0]), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.text))),
                  if (_goal == g[0]) Icon(Icons.check_circle_rounded, color: C.pink),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          Text(tr('¿Cómo te llamas?', "What's your name?"), style: _label),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: _input(tr('Tu nombre (opcional)', 'Your name (optional)')),
          ),
        ],
      );
}

const _label = TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: C.text);

InputDecoration _input(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: C.pinkBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: C.pinkLine)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: C.pinkLine)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: C.pink, width: 2)),
    );

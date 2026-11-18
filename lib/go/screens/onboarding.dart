import 'package:flutter/material.dart';

import '../data/store.dart';
import '../services/notifications.dart';
import '../strings.dart';
import '../widgets/ui.dart';

/// Primera vez: nombre, último periodo y duraciones. Todo opcional.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  DateTime? _last;
  int _cycle = 28;
  int _period = 5;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _last ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      helpText: tr('¿Cuándo empezó tu último periodo?', 'When did your last period start?'),
    );
    if (d != null) setState(() => _last = d);
  }

  Future<void> _start() async {
    final s = AppStore.instance;
    s.name = _name.text.trim();
    s.defaultCycle = _cycle;
    s.defaultPeriod = _period;
    if (_last != null) {
      await s.addPeriod(dateOnly(_last!), length: _period);
    }
    s.onboarded = true;
    await s.commit();
    await Notifier.instance.requestPermission();
    await Notifier.instance.reschedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PinkBackground(
        child: Column(
          children: [
            const GreenHeader(bellDot: false),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                children: [
                  const Center(child: Img('avatar', size: 170, fallback: Icons.face_3)),
                  const SizedBox(height: 8),
                  Text(tr('¡Bienvenida a CicloPlus!', 'Welcome to CicloPlus!'),
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: C.text)),
                  const SizedBox(height: 6),
                  Text(
                    tr('Tu calendario menstrual rápido y sencillo.',
                        'Your quick and simple period tracker.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: C.muted, height: 1.35, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: card(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('¿Cómo te llamas?', "What's your name?"), style: _label),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: _input(tr('Tu nombre (opcional)', 'Your name (optional)')),
                        ),
                        const SizedBox(height: 16),
                        Text(tr('¿Cuándo empezó tu último periodo?', 'When did your last period start?'), style: _label),
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 16),
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
                                }),
                                child: Text(tr('No lo sé', 'Not sure'), style: TextStyle(color: C.pinkDark, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  PinkButton(label: tr('Empezar', 'Get started'), icon: Icons.favorite_rounded, onTap: _start),
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

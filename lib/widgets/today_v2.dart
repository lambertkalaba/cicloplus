import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../l10n/redesign_strings.dart';
import '../models/day_entry.dart';
import '../services/cycle_predictor.dart';
import '../services/settings_service.dart';

/// Piezas del rediseño "CicloPlus 2.0" de la pestaña Hoy (maqueta aprobada:
/// cabecera verde esmeralda, flores, chica ilustrada, anillo del ciclo con
/// el día bien grande, resumen del día, ánimo en un toque, agua y sueño).
class V2Colors {
  static const emerald = Color(0xFF138A5E);
  static const emeraldDark = Color(0xFF0B6B47);
  static const pink = Color(0xFFE8458B);
  static const pinkDark = Color(0xFFC2185B);
  static const pinkSoft = Color(0xFFFFE4EF);
  static const lavender = Color(0xFFA48BDC);
  static const lavenderSoft = Color(0xFFF1EBFF);
  static const greenSoft = Color(0xFFE3F5EC);
  static const cream = Color(0xFFFFF7FA);
  static const text = Color(0xFF302B35);
  static const muted = Color(0xFF8A7F8E);
}

BoxDecoration v2Card({Color color = Colors.white, double radius = 22}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(color: const Color(0xFFB0306A).withOpacity(0.10), blurRadius: 22, offset: const Offset(0, 8)),
      ],
    );

/// Saludo con la ilustración de la chica (asset generado para el rediseño).
class V2GreetingCard extends StatefulWidget {
  const V2GreetingCard({super.key});

  @override
  State<V2GreetingCard> createState() => _V2GreetingCardState();
}

class _V2GreetingCardState extends State<V2GreetingCard> {
  String? _name;

  @override
  void initState() {
    super.initState();
    SettingsService().loadProfileName().then((n) {
      if (mounted) setState(() => _name = n);
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = RedesignStrings.current;
    return Container(
      height: 128,
      decoration: v2Card(radius: 26).copyWith(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE9F2), Color(0xFFFFF6F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              left: -6,
              bottom: -8,
              child: Image.asset('assets/decorative/hero_woman.png', width: 138, height: 138, fit: BoxFit.contain),
            ),
            Positioned.fill(
              left: 132,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${r.greeting(DateTime.now().hour, _name)} 👋',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: V2Colors.text, height: 1.15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r.greetingSubtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: V2Colors.muted, height: 1.3, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Anillo del ciclo con el día en grande y chips de fase / próximo
/// periodo / ovulación a la derecha.
class V2CycleRingCard extends StatelessWidget {
  final CyclePredictor predictor;
  final Map<String, DayEntry> data;
  final VoidCallback onTap;
  final VoidCallback onLogPeriod;

  const V2CycleRingCard({
    super.key,
    required this.predictor,
    required this.data,
    required this.onTap,
    required this.onLogPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final r = RedesignStrings.current;
    final dayInCycle = predictor.currentDayInCycle();
    final cycleLen = predictor.getAvgCycleLength();
    final today = DateTime.now();
    final today0 = DateTime(today.year, today.month, today.day);

    if (dayInCycle == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: v2Card(),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: CustomPaint(
                painter: _RingPainter(progress: 0, empty: true),
                child: const Center(child: Text('🌸', style: TextStyle(fontSize: 34))),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.noDataTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: V2Colors.text)),
                  const SizedBox(height: 6),
                  Text(r.noDataBody, style: const TextStyle(fontSize: 12.5, color: V2Colors.muted, height: 1.3)),
                  const SizedBox(height: 10),
                  _PillButton(label: r.logMyDay, icon: Icons.add, onTap: onLogPeriod),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final day = dayInCycle + 1;
    final nextPeriod = predictor.predictNextPeriod();
    final ovulation = predictor.predictOvulation(nextPeriod);
    final phase = predictor.currentPhaseKey();
    final prediction = predictor.predict();
    final fertileToday = prediction.fertileDates.contains(dateKey(today));

    final chips = <Widget>[];
    chips.add(_InfoChip(
      icon: Icons.eco,
      color: V2Colors.emerald,
      bg: V2Colors.greenSoft,
      label: fertileToday ? r.fertileEstimated : (phase != null ? s.phaseName(phase) : r.cycleDay),
    ));
    if (nextPeriod != null) {
      chips.add(_InfoChip(
        icon: Icons.calendar_month_rounded,
        color: V2Colors.pinkDark,
        bg: V2Colors.pinkSoft,
        label: r.periodInDays(nextPeriod.difference(today0).inDays),
      ));
    }
    if (ovulation != null && !ovulation.isBefore(today0)) {
      chips.add(_InfoChip(
        icon: Icons.radio_button_checked,
        color: const Color(0xFF7A5BC7),
        bg: V2Colors.lavenderSoft,
        label: r.ovulationInDays(ovulation.difference(today0).inDays),
      ));
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
        decoration: v2Card(),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 158,
                  height: 158,
                  child: CustomPaint(
                    painter: _RingPainter(progress: (day / math.max(cycleLen, day)).clamp(0.0, 1.0)),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(r.cycleDay, style: const TextStyle(fontSize: 11.5, color: V2Colors.muted, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          FittedBox(
                            child: Text(
                              r.dayN(day),
                              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: V2Colors.pinkDark, height: 1.05),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(r.ofNDays(cycleLen), style: const TextStyle(fontSize: 12, color: V2Colors.muted, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final c in chips) ...[c, const SizedBox(height: 8)],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              r.estimatedNote,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, color: V2Colors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String label;

  const _InfoChip({required this.icon, required this.color, required this.bg, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color, height: 1.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final bool empty;

  _RingPainter({required this.progress, this.empty = false});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.085;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0xFFF5E6EE);
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (empty) return;
    // Arco de todo el ciclo en colores suaves (periodo rosa → fértil verde
    // → lútea lavanda) y encima el progreso hasta hoy en color fuerte.
    final full = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [Color(0xFFFFB3CF), Color(0xFFB7E4CC), Color(0xFFD9CCF5), Color(0xFFFFB3CF)],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * 0.999, false, full);
    final prog = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [V2Colors.pink, V2Colors.emerald, V2Colors.lavender, V2Colors.pink],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, prog);
    // Puntero blanco en la posición de hoy.
    final a = -math.pi / 2 + math.pi * 2 * progress;
    final c = rect.center;
    final rr = rect.width / 2;
    final p = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
    canvas.drawCircle(p, stroke * 0.75, Paint()..color = Colors.white);
    canvas.drawCircle(p, stroke * 0.75, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = V2Colors.pink);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress || old.empty != empty;
}

/// "Mi resumen de hoy" con la flor de loto.
class V2SummaryCard extends StatelessWidget {
  final String? phaseKey;

  const V2SummaryCard({super.key, required this.phaseKey});

  @override
  Widget build(BuildContext context) {
    final r = RedesignStrings.current;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: v2Card(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r.summaryTitle} ✨',
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: V2Colors.text)),
                const SizedBox(height: 6),
                Text(r.summaryFor(phaseKey),
                    style: const TextStyle(fontSize: 13, color: V2Colors.muted, height: 1.35, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Image.asset('assets/decorative/lotus.png', width: 84, height: 84),
        ],
      ),
    );
  }
}

/// "¿Cómo te sientes hoy?" — 5 estados de ánimo que se guardan con un toque
/// en el registro de hoy (mismo campo `mood` que usa Registrar).
class V2MoodRow extends StatelessWidget {
  final Map<String, DayEntry> data;
  final ValueChanged<Map<String, DayEntry>> onDataChanged;

  const V2MoodRow({super.key, required this.data, required this.onDataChanged});

  static const _moods = [
    ['feliz', '😊'],
    ['agotada', '🥱'],
    ['triste', '😢'],
    ['sensible', '🥹'],
    ['ansiosa', '😰'],
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final key = dateKey(DateTime.now());
    final entry = data[key] ?? const DayEntry();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: v2Card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.todayHowDoYouFeel, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: V2Colors.text)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final m in _moods)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _MoodButton(
                      emoji: m[1],
                      label: s.moodLabelFor(m[0]),
                      selected: entry.mood.contains(m[0]),
                      onTap: () {
                        final moods = List<String>.from(entry.mood);
                        if (moods.contains(m[0])) {
                          moods.remove(m[0]);
                        } else {
                          moods.add(m[0]);
                        }
                        final updated = Map<String, DayEntry>.from(data);
                        updated[key] = entry.copyWith(mood: moods);
                        onDataChanged(updated);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MoodButton({required this.emoji, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? V2Colors.pinkSoft : const Color(0xFFFFF8FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? V2Colors.pink : const Color(0xFFF6DDE8), width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 180),
              scale: selected ? 1.15 : 1,
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: selected ? V2Colors.pinkDark : V2Colors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Agua (+1 vaso con cada toque) y sueño (abre el registro).
class V2QuickStats extends StatelessWidget {
  final Map<String, DayEntry> data;
  final ValueChanged<Map<String, DayEntry>> onDataChanged;
  final VoidCallback onOpenEditor;

  const V2QuickStats({super.key, required this.data, required this.onDataChanged, required this.onOpenEditor});

  @override
  Widget build(BuildContext context) {
    final r = RedesignStrings.current;
    final key = dateKey(DateTime.now());
    final entry = data[key] ?? const DayEntry();
    final water = entry.water ?? 0;
    final sleep = entry.sleep;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            emoji: '💧',
            title: r.water,
            value: r.glasses(water),
            progress: (water / 8).clamp(0.0, 1.0),
            color: const Color(0xFF3BA3D9),
            trailing: const Icon(Icons.add_circle, color: Color(0xFF3BA3D9), size: 26),
            onTap: () {
              final updated = Map<String, DayEntry>.from(data);
              updated[key] = entry.copyWith(water: water >= 12 ? 0 : water + 1);
              onDataChanged(updated);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            emoji: '🌙',
            title: r.sleep,
            value: sleep != null ? '${sleep.toStringAsFixed(sleep % 1 == 0 ? 0 : 1)} h' : r.tapToLog,
            progress: sleep != null ? (sleep / 8).clamp(0.0, 1.0) : 0,
            color: V2Colors.lavender,
            trailing: const Icon(Icons.chevron_right, color: V2Colors.lavender, size: 24),
            onTap: onOpenEditor,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String value;
  final double progress;
  final Color color;
  final Widget trailing;
  final VoidCallback onTap;

  const _StatTile({
    required this.emoji,
    required this.title,
    required this.value,
    required this.progress,
    required this.color,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        decoration: v2Card(radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: V2Colors.text)),
                ),
                trailing,
              ],
            ),
            const SizedBox(height: 6),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón grande "Registrar mi día".
class V2LogButton extends StatelessWidget {
  final VoidCallback onTap;

  const V2LogButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = RedesignStrings.current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(colors: [V2Colors.pink, V2Colors.pinkDark]),
          boxShadow: [BoxShadow(color: V2Colors.pink.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: Colors.white),
            const SizedBox(width: 8),
            Text(r.logMyDay, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PillButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: [V2Colors.pink, V2Colors.pinkDark]),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/store.dart';
import '../services/pill.dart';
import '../strings.dart';
import '../cicloplus_links.dart';
import '../widgets/cycle_plus.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/ui.dart';
import 'extras.dart';
import 'more.dart';

/// Pestaña Hoy.
class TodayScreen extends StatelessWidget {
  final void Function([DateTime? day]) onRegister;
  final VoidCallback onCalendar;

  /// Dentro de otra pantalla con scroll (Hoy de CicloPlus): sin scroll propio.
  final bool embedded;
  const TodayScreen({super.key, required this.onRegister, required this.onCalendar, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final s = AppStore.instance;
        final today = dateOnly(DateTime.now());
        final info = s.infoFor(today);
        final log = s.logFor(today);
        final pregnant = s.goal == 'pregnancy' && s.pregnancyWeek != null;
        return ListView(
          shrinkWrap: embedded,
          physics: embedded ? const NeverScrollableScrollPhysics() : null,
          padding: embedded ? EdgeInsets.zero : const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: [
            _Greeting(name: s.name),
            const SizedBox(height: 10),
            if (pregnant) _PregnancyCard(key: ValueKey(L.lang)) else _RingCard(onTap: onCalendar, onLogPeriod: () => onRegister()),
            if (s.reminders.pill) ...[
              const SizedBox(height: 12),
              _PillCard(today: today),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              decoration: card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('¿Cómo te sientes hoy?', 'How do you feel today?'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.text)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var i = 0; i < 5; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Choice(
                              selected: log.mood == i + 1,
                              onTap: () => s.updateLog(today, (l) => l.mood = l.mood == i + 1 ? 0 : i + 1),
                              child: Column(
                                children: [
                                  Img(moodImgs[i], size: 30, fallback: Icons.sentiment_satisfied_rounded, fallbackColor: C.orange),
                                  const SizedBox(height: 3),
                                  Text(moodNames[i],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: C.text)),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (!pregnant) ...[
              const SizedBox(height: 12),
              const QuickLogRow(),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
              decoration: card(),
              child: Row(
                children: [
                  const Img('lotus', size: 74, fallback: Icons.spa_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${tr('Tu consejo de hoy', 'Your tip for today')} ✨',
                            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: C.pinkDark)),
                        const SizedBox(height: 4),
                        Text(pregnant ? pregnancyTip(s.pregnancyWeek!) : phaseTip(info.phase),
                            style: const TextStyle(fontSize: 12.5, color: C.text, height: 1.35, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!pregnant) const PatternsCard(),
            const SizedBox(height: 16),
            PinkButton(label: tr('Registrar mi día', 'Log my day'), icon: Icons.add_rounded, onTap: () => onRegister()),
          ],
        );
      },
    );
  }
}

class _PregnancyCard extends StatelessWidget {
  const _PregnancyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    final w = s.pregnancyWeek!;
    final due = addDays(s.pregnancyStart!, 280);
    return GestureDetector(
      onTap: () => CP.openPregnancy(context),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
        decoration: card(),
        child: Row(
          children: [
            const Img('baby', size: 120, fallback: Icons.child_friendly_rounded),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${tr('Semana', 'Week')} $w', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: C.text)),
                  Text(tr('de embarazo', 'of pregnancy'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.text)),
                  const SizedBox(height: 8),
                  Pill('${tr('Parto previsto', 'Due')}: ${L.dateShort(due)}', img: 'n_calendar', color: C.pinkDark, bg: C.pinkSoft),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: C.text),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final String name;
  const _Greeting({required this.name});

  @override
  Widget build(BuildContext context) {
    final av = Avatars.current;
    final hasPhoto = av == 'photo';
    return SizedBox(
      height: 140,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(right: -18, top: 62, child: Img('hibiscus', size: 64, fallback: Icons.local_florist)),
          Positioned(
            left: hasPhoto ? 6 : -10,
            top: hasPhoto ? 14 : 0,
            child: GestureDetector(
              onTap: () => showAvatarPicker(context),
              child: hasPhoto
                ? Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: C.pink.withOpacity(0.25), blurRadius: 10)],
                    ),
                    child: const ClipOval(child: Avatar(size: 112)),
                  )
                : Stack(clipBehavior: Clip.none, children: [
                    LiveAvatar(id: av, size: 140, onEdit: () => showAvatarPicker(context)),
                    Positioned(
                      right: 8,
                      bottom: 6,
                      child: GestureDetector(
                        onTap: () => showAvatarPicker(context),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: C.pink.withValues(alpha: 0.3), blurRadius: 6)]),
                          child: Icon(Icons.edit_rounded, size: 16, color: C.pink),
                        ),
                      ),
                    ),
                  ]),
            ),
          ),
          Positioned(
            left: 134,
            right: 26,
            top: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${L.es ? '¡' : ''}${greeting(name)}! 👋',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: C.text, height: 1.12)),
                const SizedBox(height: 6),
                Text(tr('Cuida de ti hoy,\ntu bienestar importa 💗', 'Take care of yourself today,\nyour wellbeing matters 💗'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: C.text, height: 1.3, fontWeight: FontWeight.w600)),
                const SizedBox(height: 7),
                // Su objetivo, siempre a la vista.
                Builder(builder: (_) {
                  final st = AppStore.instance;
                  final w = st.pregnancyWeek;
                  final (emoji, label) = switch (st.goal) {
                    'pregnancy' => ('👣', w != null ? tr('Embarazo · semana {}', 'Pregnancy · week {}').replaceFirst('{}', '$w') : tr('Seguir mi embarazo', 'Track my pregnancy')),
                    'conceive' => ('🌱', tr('Intento concebir', 'Trying to conceive')),
                    _ => ('🩸', tr('Seguir mi período', 'Track my period')),
                  };
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: C.pinkLine),
                      boxShadow: [BoxShadow(color: C.pink.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(emoji, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: C.pinkDark)),
                      ),
                    ]),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingCard extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onLogPeriod;
  const _RingCard({required this.onTap, required this.onLogPeriod});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    final today = dateOnly(DateTime.now());
    final day = s.cycleDayToday;
    if (day == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: card(),
        child: Row(
          children: [
            SizedBox(
              width: 104,
              height: 104,
              child: CustomPaint(
                painter: RingPainter(progress: 0, empty: true),
                child: const Center(child: Text('🌸', style: TextStyle(fontSize: 34))),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Empecemos', "Let's start"), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: C.text)),
                  const SizedBox(height: 6),
                  Text(tr('Registra el primer día de tu periodo para ver tus predicciones.', 'Log the first day of your period to see predictions.'),
                      style: const TextStyle(fontSize: 12.5, color: C.muted, height: 1.3)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PeriodCycleScreen())),
                    child: Pill(tr('+ Registrar periodo', '+ Log period'), color: Colors.white, bg: C.pink),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final cycle = s.avgCycle;
    final info = s.infoFor(today);
    final chips = <Widget>[
      _InfoChip(icon: Icons.eco, color: const Color(0xFF2B5B2E), bg: const Color(0xFFDDF0D3), label: phaseName(info.phase ?? Phase.follicular)),
    ];
    final late = s.lateDays;
    final next = s.nextPeriod;
    if (late > 0) {
      chips.add(_InfoChip(
          icon: Icons.schedule_rounded,
          color: C.pinkDark,
          bg: C.pinkSoft,
          label: tr('Retraso de $late ${daysWord(late)}', '$late ${daysWord(late)} late')));
    } else if (next != null) {
      final n = daysBetween(today, next);
      chips.add(_InfoChip(
          icon: Icons.calendar_month_rounded,
          color: C.pinkDark,
          bg: C.pinkSoft,
          label: CyclePlus.rangeLabel() ??
              (n == 0 ? tr('Periodo previsto hoy', 'Period expected today') : tr('Periodo en $n ${daysWord(n)}', 'Period in $n ${daysWord(n)}'))));
    }
    final ov = s.nextOvulation;
    if (ov != null) {
      final n = daysBetween(today, ov);
      chips.add(_InfoChip(
          icon: Icons.radio_button_checked,
          color: C.purple,
          bg: C.lavenderSoft,
          label: n == 0 ? tr('Ovulación hoy', 'Ovulation today') : tr('Ovulación en $n ${daysWord(n)}', 'Ovulation in $n ${daysWord(n)}')));
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
        decoration: card(),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CustomPaint(
                    painter: RingPainter(progress: (day / math.max(cycle, day)).clamp(0.0, 1.0)),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tr('Día del ciclo', 'Cycle day'), style: const TextStyle(fontSize: 11.5, color: C.muted, fontWeight: FontWeight.w700)),
                          Text('$day', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: C.pinkDark, height: 1.1)),
                          Text(tr('de $cycle días', 'of $cycle days'), style: const TextStyle(fontSize: 12, color: C.muted, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [for (final c in chips) ...[c, const SizedBox(height: 8)]],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(tr('Predicciones estimadas según tus registros.', 'Estimates based on your logs.'),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: C.muted)),
          ],
        ),
      ),
    );
  }
}

final _chipImg = <IconData, String>{
  Icons.eco: 'leaf',
  Icons.calendar_month_rounded: 'n_drop',
  Icons.schedule_rounded: 'n_drop',
  Icons.radio_button_checked: 'target',
};

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String label;
  const _InfoChip({required this.icon, required this.color, required this.bg, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Img(_chipImg[icon] ?? 'leaf', size: 20, fallback: icon, fallbackColor: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color, height: 1.15)),
            ),
          ],
        ),
      );
}

class RingPainter extends CustomPainter {
  final double progress;
  final bool empty;
  RingPainter({required this.progress, this.empty = false});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.085;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = C.t(0xFFF5E6EE));
    if (empty) return;
    final full = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [C.t(0xFFFFB3CF), Color(0xFFB7E4CC), Color(0xFFD9CCF5), C.t(0xFFFFB3CF)],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * 0.999, false, full);
    final prog = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [C.pink, C.emerald, C.lavender, C.pink],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, prog);
    final a = -math.pi / 2 + math.pi * 2 * progress;
    final c = rect.center;
    final rr = rect.width / 2;
    final p = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
    canvas.drawCircle(p, stroke * 0.75, Paint()..color = Colors.white);
    canvas.drawCircle(
        p,
        stroke * 0.75,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = C.pink);
  }

  @override
  bool shouldRepaint(covariant RingPainter old) => old.progress != progress || old.empty != empty;
}

/// Píldora de hoy con racha de días seguidos (solo si el recordatorio de
/// la píldora está activado).
class _PillCard extends StatelessWidget {
  final DateTime today;
  const _PillCard({required this.today});

  @override
  Widget build(BuildContext context) {
    final taken = PillTracker.takenOn(today);
    final streak = PillTracker.streak();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: card(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: taken ? const Color(0xFFE3F1DC) : C.pinkBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(taken ? '✅' : '💊', style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Píldora de hoy', "Today's pill"),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: C.text)),
                const SizedBox(height: 2),
                Text(
                  streak > 0 ? '🔥 $streak ${tr('días seguidos', 'days in a row')}' : (taken ? tr('¡Tomada hoy!', 'Taken today!') : ''),
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.pinkDark),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => PillTracker.setTaken(today, !taken),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: taken ? const Color(0xFF3E9B4F) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: taken ? const Color(0xFF3E9B4F) : C.pink, width: 1.5),
              ),
              child: Text(
                taken ? tr('¡Tomada hoy!', 'Taken today!') : tr('Marcar como tomada', 'Mark as taken'),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: taken ? Colors.white : C.pinkDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

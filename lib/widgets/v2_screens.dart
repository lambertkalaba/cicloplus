import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../l10n/redesign_strings.dart';
import '../models/day_entry.dart';
import '../services/cycle_predictor.dart';
import 'today_v2.dart';

/// Piezas del rediseño CicloPlus 2.0 para Calendario, Registrar y Yo
/// (maqueta de ChatGPT aprobada por la usuaria).

/// Título grande de pantalla ("Calendario", "Registrar mi día"...) con un
/// subtítulo opcional, una ilustración a la derecha y algo a la derecha
/// (p. ej. el chip Regular/Irregular del calendario).
class V2ScreenTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showIllustration;

  const V2ScreenTitle({super.key, required this.title, this.subtitle, this.trailing, this.showIllustration = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: V2Colors.text, height: 1.1)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: const TextStyle(fontSize: 13, color: V2Colors.muted, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
        if (showIllustration) Image.asset('assets/decorative/calendar_heart.png', width: 64, height: 64),
      ],
    );
  }
}

/// Día del ciclo para una fecha cualquiera (1 = primer día de sangrado del
/// ciclo que contiene esa fecha), o null si no hay datos.
int? v2CycleDayFor(CyclePredictor predictor, DateTime date) {
  final d0 = DateTime(date.year, date.month, date.day);
  DateTime? start;
  for (final cycle in predictor.getCycles()) {
    if (cycle.isEmpty) continue;
    final p = cycle.first.split('-');
    final s = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    if (!s.isAfter(d0)) start = s;
  }
  if (start == null) return null;
  final n = d0.difference(start).inDays + 1;
  return n > 90 ? null : n;
}

/// Tarjeta del día seleccionado en el Calendario: fecha, día del ciclo,
/// fase, síntomas/ánimo registrados, nota y botón para editar.
class V2DayCard extends StatelessWidget {
  final DateTime date;
  final Map<String, DayEntry> data;
  final CyclePredictor predictor;
  final CyclePrediction prediction;
  final bool showPhase;
  final VoidCallback onEdit;

  const V2DayCard({
    super.key,
    required this.date,
    required this.data,
    required this.predictor,
    required this.prediction,
    required this.showPhase,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final r = RedesignStrings.current;
    final key = dateKey(date);
    final entry = data[key];
    final cycleDay = showPhase ? v2CycleDayFor(predictor, date) : null;
    final fertile = showPhase && prediction.fertileDates.contains(key);
    final isPeriod = (entry?.isPeriodDay ?? false) || false;
    final phase = showPhase ? predictor.phaseKeyForDate(date) : null;

    String? phaseLabel;
    Color phaseColor = V2Colors.emerald;
    Color phaseBg = V2Colors.greenSoft;
    if (fertile) {
      phaseLabel = r.fertileEstimated;
    } else if (isPeriod && showPhase) {
      phaseLabel = s.phaseName('menstrual');
      phaseColor = V2Colors.pinkDark;
      phaseBg = V2Colors.pinkSoft;
    } else if (phase != null) {
      phaseLabel = s.phaseName(phase);
      phaseColor = const Color(0xFF7A5BC7);
      phaseBg = V2Colors.lavenderSoft;
    }

    final chips = <Widget>[];
    if (entry != null) {
      if (entry.isPeriodDay) {
        chips.add(_chip('🩸', s.flowTextOnlyLabelFor(entry.flow)));
      }
      for (final id in entry.symptoms) {
        final emoji = kSymptomCatalog.firstWhere((c) => c['id'] == id, orElse: () => const {'emoji': '•'})['emoji'] ?? '•';
        final level = entry.symptomLevels[id];
        chips.add(_chip(emoji, s.symptomLabelFor(id), sub: level != null ? s.symptomLevelLabelFor(level) : null));
      }
      for (final id in entry.mood) {
        final emoji = kMoodCatalog.firstWhere((c) => c['id'] == id, orElse: () => const {'emoji': '🙂'})['emoji'] ?? '🙂';
        chips.add(_chip(emoji, s.moodLabelFor(id)));
      }
      if ((entry.water ?? 0) > 0) chips.add(_chip('💧', r.glasses(entry.water!)));
      if (entry.sleep != null) chips.add(_chip('🌙', '${entry.sleep!.toStringAsFixed(entry.sleep! % 1 == 0 ? 0 : 1)} h'));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: v2Card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 62,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [V2Colors.pink, V2Colors.pinkDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: V2Colors.pink.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${date.day}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                    Text(r.monthShort(date.month), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cycleDay != null ? r.dayOfCycleN(cycleDay) : '${date.day} ${r.monthShort(date.month)} ${date.year}',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: V2Colors.text),
                    ),
                    if (phaseLabel != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: phaseBg, borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.eco, size: 14, color: phaseColor),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(phaseLabel,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: phaseColor)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Image.asset('assets/decorative/calendar_heart.png', width: 58, height: 58),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF6DDE8)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.favorite_border, color: V2Colors.pink, size: 18),
              const SizedBox(width: 6),
              Text(r.symptomsLogged, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: V2Colors.text)),
            ],
          ),
          const SizedBox(height: 8),
          if (chips.isEmpty)
            Text(r.nothingLogged, style: const TextStyle(fontSize: 12.5, color: V2Colors.muted))
          else
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          if (entry != null && entry.note.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.edit_note, color: V2Colors.pink, size: 20),
                const SizedBox(width: 6),
                Text(s.calendarNotes, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: V2Colors.text)),
              ],
            ),
            const SizedBox(height: 4),
            Text(entry.note.trim(),
                maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: V2Colors.muted, height: 1.3)),
          ],
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: V2Colors.pink, width: 1.6),
                color: const Color(0xFFFFF5F9),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit_outlined, color: V2Colors.pinkDark, size: 18),
                  const SizedBox(width: 8),
                  Text(r.editDayRecords, style: const TextStyle(color: V2Colors.pinkDark, fontWeight: FontWeight.w800, fontSize: 14.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String emoji, String label, {String? sub}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF6DDE8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: V2Colors.text)),
              if (sub != null) Text(sub, style: const TextStyle(fontSize: 10.5, color: V2Colors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Cabecera de perfil de "Yo": avatar ilustrado, nombre y objetivo actual.
class V2ProfileCard extends StatelessWidget {
  final String name;
  final String goalLabel;
  final VoidCallback onEdit;

  const V2ProfileCard({super.key, required this.name, required this.goalLabel, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final r = RedesignStrings.current;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: v2Card(radius: 26).copyWith(
        gradient: const LinearGradient(colors: [Color(0xFFFFE9F2), Color(0xFFFFF7FA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: V2Colors.pink.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: ClipOval(child: Image.asset('assets/decorative/hero_woman.png', fit: BoxFit.cover)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: V2Colors.text)),
                const SizedBox(height: 4),
                Text(r.myGoalNow, style: const TextStyle(fontSize: 12, color: V2Colors.muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: V2Colors.greenSoft, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.track_changes, size: 16, color: V2Colors.emerald),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(goalLabel, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: V2Colors.emeraldDark)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: V2Colors.pinkDark),
            style: IconButton.styleFrom(backgroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// "Mi ciclo en números": ciclo medio, periodo medio y regularidad.
class V2CycleNumbersCard extends StatelessWidget {
  final CyclePredictor predictor;

  const V2CycleNumbersCard({super.key, required this.predictor});

  @override
  Widget build(BuildContext context) {
    final r = RedesignStrings.current;
    final irregular = predictor.isIrregular();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: v2Card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: V2Colors.pink),
              const SizedBox(width: 6),
              Text(r.myCycleNumbers, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: V2Colors.text)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _tile('📅', r.daysN(predictor.getAvgCycleLength()), r.avgCycle, V2Colors.pinkDark)),
              const SizedBox(width: 8),
              Expanded(child: _tile('🩸', r.daysN(predictor.getAvgPeriodLength()), r.avgPeriod, V2Colors.pinkDark)),
              const SizedBox(width: 8),
              Expanded(
                child: _tile(irregular ? '〰️' : '✅', irregular ? r.irregular : r.regular,
                    irregular ? r.variableCycles : r.stableCycles, irregular ? const Color(0xFFC77700) : V2Colors.emeraldDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tile(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF6DDE8)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          FittedBox(child: Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color))),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, maxLines: 2,
              style: const TextStyle(fontSize: 11, color: V2Colors.muted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Título de sección con icono ("Accesos rápidos", "Mi objetivo"...).
class V2SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;

  const V2SectionTitle({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: V2Colors.pink, size: 20),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: V2Colors.text)),
      ],
    );
  }
}

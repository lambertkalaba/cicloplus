import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/cycle_predictor.dart';
import '../theme/app_theme.dart';

/// Tarjeta superior con "próximo periodo" y "ventana fértil".
class StatusCard extends StatelessWidget {
  final CyclePrediction prediction;

  const StatusCard({super.key, required this.prediction});

  String _nextPeriodLabel(AppStrings s) {
    final next = prediction.nextPeriodStart;
    if (next == null) return s.statusRegisterPeriod;

    // Con ciclo irregular mostramos un rango de días en vez de una fecha
    // exacta, que sería poco confiable con tanta variación entre ciclos.
    if (prediction.isIrregular && prediction.rangeStart != null && prediction.rangeEnd != null) {
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      final diffStart = prediction.rangeStart!.difference(todayMidnight).inDays;
      final diffEnd = prediction.rangeEnd!.difference(todayMidnight).inDays;
      if (diffEnd < 0) return s.statusRangeDaysAgo(-diffStart, -diffEnd);
      if (diffStart <= 0 && diffEnd >= 0) return s.statusRangeBetweenTodayAnd(diffEnd);
      return s.statusRangeInDays(diffStart, diffEnd);
    }

    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final diff = next.difference(todayMidnight).inDays;
    if (diff == 0) return s.statusToday;
    if (diff > 0) return s.statusInDays(diff);
    return s.statusDaysAgo(-diff);
  }

  String _fertileLabel(AppStrings s) {
    final ov = prediction.ovulationDate;
    if (ov == null) return s.statusFertileEmpty;
    // Con ciclo irregular usamos el rango ya ensanchado que calculó
    // CyclePredictor (mismo criterio que "Próximo periodo") en vez de la
    // ventana fija de 7 días — antes esta tarjeta mostraba una fecha con
    // apariencia exacta aunque el periodo, al lado, ya avisara que no lo era.
    final start = prediction.isIrregular && prediction.fertileRangeStart != null
        ? prediction.fertileRangeStart!
        : ov.subtract(const Duration(days: 5));
    final end = prediction.isIrregular && prediction.fertileRangeEnd != null
        ? prediction.fertileRangeEnd!
        : ov.add(const Duration(days: 1));
    if (start.month == end.month) {
      return '${start.day}–${end.day} ${s.monthShort(end.month)}';
    }
    return '${start.day} ${s.monthShort(start.month)} – ${end.day} ${s.monthShort(end.month)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _StatusColumn(label: s.statusNextPeriodLabel, value: _nextPeriodLabel(s))),
              Expanded(child: _StatusColumn(label: s.statusFertileWindowLabel, value: _fertileLabel(s))),
            ],
          ),
          if (prediction.isIrregular) ...[
            const SizedBox(height: 10),
            Text(
              s.statusIrregularNote,
              style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatusColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const _monthNamesShort = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
];

String _label(DateTime d) => '${d.day} ${_monthNamesShort[d.month - 1]}';

/// Lista de ciclos pasados registrados (fecha de inicio–fin y duración).
class HistoryList extends StatelessWidget {
  final List<List<String>> cycles;

  const HistoryList({super.key, required this.cycles});

  @override
  Widget build(BuildContext context) {
    if (cycles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Aún no hay ciclos registrados. Marca tus días de periodo en el calendario.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      );
    }

    final reversed = cycles.reversed.toList();

    return Column(
      children: reversed.map((cycle) {
        final start = _parseKey(cycle.first);
        final end = _parseKey(cycle.last);
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_label(start)} – ${_label(end)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
              Text(
                '${cycle.length} días',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

DateTime _parseKey(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

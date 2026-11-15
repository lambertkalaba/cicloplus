import '../models/day_entry.dart';
import 'cycle_predictor.dart';

/// Un punto de temperatura con su fecha, usado para la gráfica y para el
/// indicador de cambio térmico.
class TempPoint {
  final String dateKey;
  final double temp;
  const TempPoint(this.dateKey, this.temp);
}

/// Resultado de la comparación de ciclos por año.
class YearComparisonRow {
  final int year;
  final int avg;
  final int count;
  const YearComparisonRow({required this.year, required this.avg, required this.count});
}

DateTime _parseKey(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

String _fmt(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Réplica de las funciones de estadísticas e insights del prototipo web
/// (computeInsights, findThermalShift, computeStreak,
/// computeYearComparison). Toma directamente el mapa de días, igual que
/// `CyclePredictor`.
class StatsCalculator {
  final Map<String, DayEntry> data;
  late final CyclePredictor predictor;

  StatsCalculator(this.data) {
    predictor = CyclePredictor(data);
  }

  /// Busca síntomas que se repiten en los 3 días previos al inicio del
  /// periodo, a través de varios ciclos. Si un síntoma aparece en al
  /// menos la mitad de los ciclos registrados (mínimo 2 ciclos), se
  /// considera un patrón detectado. Devuelve pares (idSíntoma, porcentaje).
  List<MapEntry<String, int>> computeInsights() {
    final cycles = predictor.getCycles();
    if (cycles.length < 2) return [];

    final symptomCycleCount = <String, int>{};
    for (final cycle in cycles) {
      final start = _parseKey(cycle.first);
      final seenInThisCycle = <String>{};
      for (var i = 1; i <= 3; i++) {
        final d = start.subtract(Duration(days: i));
        final entry = data[_fmt(d)];
        if (entry != null) {
          seenInThisCycle.addAll(entry.symptoms);
        }
      }
      for (final s in seenInThisCycle) {
        symptomCycleCount[s] = (symptomCycleCount[s] ?? 0) + 1;
      }
    }

    final insights = <MapEntry<String, int>>[];
    symptomCycleCount.forEach((symptom, count) {
      final ratio = count / cycles.length;
      if (ratio >= 0.5) {
        insights.add(MapEntry(symptom, (ratio * 100).round()));
      }
    });
    return insights;
  }

  /// Regla "3 sobre 6" del método sintotérmico: 3 temperaturas seguidas,
  /// cada una al menos 0.2°C por encima de la temperatura más alta de las
  /// 6 previas, indican que probablemente ya ocurrió la ovulación.
  /// `sortedEntries` debe venir en orden cronológico. Devuelve el punto
  /// del 3er día de la subida confirmada, o null si no se detecta.
  static TempPoint? findThermalShift(List<TempPoint> sortedEntries) {
    for (var i = 6; i + 2 < sortedEntries.length; i++) {
      final lows = sortedEntries.sublist(i - 6, i).map((e) => e.temp);
      final highestLow = lows.reduce((a, b) => a > b ? a : b);
      final threeUp = [sortedEntries[i], sortedEntries[i + 1], sortedEntries[i + 2]]
          .every((e) => e.temp >= highestLow + 0.2);
      if (threeUp) return sortedEntries[i + 2];
    }
    return null;
  }

  /// Temperaturas registradas desde el inicio del ciclo actual (el más
  /// reciente), en orden cronológico. Usado para el indicador de cambio
  /// térmico.
  List<TempPoint> currentCycleTemps() {
    final cycles = predictor.getCycles();
    if (cycles.isEmpty) return [];
    final cycleStart = _parseKey(cycles.last.first);

    final keys = data.keys.where((k) {
      final entry = data[k]!;
      return entry.temp != null && !_parseKey(k).isBefore(cycleStart);
    }).toList()
      ..sort();

    return keys.map((k) => TempPoint(k, data[k]!.temp!)).toList();
  }

  /// Racha de días consecutivos con algún registro, contando hacia atrás
  /// desde hoy (o desde ayer si hoy todavía no se registró nada, para no
  /// romper la racha).
  int computeStreak() {
    final today = DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);
    if (!data.containsKey(_fmt(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (data.containsKey(_fmt(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Compara la duración promedio de ciclo por año calendario (año del
  /// inicio del ciclo más reciente de cada par comparado).
  List<YearComparisonRow> computeYearComparison() {
    final cycles = predictor.getCycles();
    final diffsByYear = <int, List<int>>{};
    for (var i = 1; i < cycles.length; i++) {
      final prevStart = _parseKey(cycles[i - 1].first);
      final curStart = _parseKey(cycles[i].first);
      final diff = curStart.difference(prevStart).inDays;
      if (diff <= 0 || diff >= 90) continue;
      final year = curStart.year;
      diffsByYear.putIfAbsent(year, () => []).add(diff);
    }
    final years = diffsByYear.keys.toList()..sort();
    return years.map((year) {
      final diffs = diffsByYear[year]!;
      final avg = (diffs.reduce((a, b) => a + b) / diffs.length).round();
      return YearComparisonRow(year: year, avg: avg, count: diffs.length);
    }).toList();
  }

  /// Rango [min, max] de duración de ciclo (diferencias válidas entre
  /// inicios de ciclo consecutivos), usado en la tarjeta de estadísticas
  /// junto con el promedio.
  ///
  /// A propósito usa el mismo límite superior de sanidad (≤120 días) que
  /// `CyclePredictor._rawCycleLengths()` — antes este método usaba <90
  /// mientras el predictor usaba <60, así que el promedio/min/max
  /// mostrado en Estadísticas podía no coincidir con el ciclo usado para
  /// predecir la próxima fecha. Aquí SÍ se incluyen ciclos largos (60-120
  /// días) a propósito: esta pantalla muestra el historial real de la
  /// usuaria (incluye ciclos irregulares/largos como información útil),
  /// mientras que CyclePredictor los separa en "típicos" solo para el
  /// cálculo de la fecha de predicción — ver `getAvgCycleLength`.
  List<int> cycleLengthDiffs() {
    final cycles = predictor.getCycles();
    final diffs = <int>[];
    for (var i = 1; i < cycles.length; i++) {
      final prevStart = _parseKey(cycles[i - 1].first);
      final curStart = _parseKey(cycles[i].first);
      final diff = curStart.difference(prevStart).inDays;
      if (diff > 0 && diff <= 120) diffs.add(diff);
    }
    return diffs;
  }
}

import 'dart:math';

import '../models/day_entry.dart';

const int kDefaultCycleLen = 28;
const int kDefaultPeriodLen = 5;

/// Formatea una fecha como clave 'yyyy-MM-dd' sin depender de locale.
String dateKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime _parseKey(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

/// Resultado de la predicción para pintar el calendario.
class CyclePrediction {
  final DateTime? nextPeriodStart;
  final DateTime? ovulationDate;
  final Set<String> predictedPeriodDates;
  final Set<String> fertileDates;

  /// Si el ciclo es irregular (mucha variación entre ciclos anteriores),
  /// [nextPeriodStart] deja de ser una fecha exacta confiable y en su
  /// lugar se ofrece un rango [rangeStart]–[rangeEnd] más realista.
  final bool isIrregular;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  /// Igual que [rangeStart]/[rangeEnd] pero para la ventana fértil: si el
  /// ciclo es irregular, la fecha de ovulación estimada también pierde
  /// precisión (depende de [nextPeriodStart]), así que la ventana fértil
  /// se ensancha en vez de mostrarse como un rango de fechas exacto.
  final DateTime? fertileRangeStart;
  final DateTime? fertileRangeEnd;

  const CyclePrediction({
    this.nextPeriodStart,
    this.ovulationDate,
    this.predictedPeriodDates = const {},
    this.fertileDates = const {},
    this.isIrregular = false,
    this.rangeStart,
    this.rangeEnd,
    this.fertileRangeStart,
    this.fertileRangeEnd,
  });
}

/// Lógica de predicción del ciclo. Es la misma lógica probada en el
/// prototipo web (agrupación de días consecutivos de flujo en "ciclos",
/// promedio de duración entre ciclos, y ventana fértil = ovulación -5 a +1).
class CyclePredictor {
  final Map<String, DayEntry> data;

  /// Si la usuaria activó a mano el interruptor "Ciclo irregular" en
  /// Configuración (`SettingsService.loadIrregularCycleMode`), se fuerza
  /// `isIrregular = true` en la predicción y se amplía el rango incluso
  /// si el historial de ciclos por sí solo no cruzaría el umbral
  /// estadístico de `isIrregular()`. Útil para quien sabe que su ciclo es
  /// irregular pero aún no tiene 3+ ciclos registrados para detectarlo
  /// automáticamente.
  final bool forceIrregular;

  /// Duración de ciclo autoreportada por la usuaria en el cuestionario de
  /// "Intentando concebir" (Configuración > Mi objetivo), en días. Se usa
  /// SOLO como respaldo en getAvgCycleLength() mientras todavía no hay
  /// suficientes periodos registrados (menos de 2 ciclos) — en cuanto hay
  /// datos reales, esos siempre tienen prioridad sobre lo autoreportado,
  /// así que este valor deja de influir apenas la usuaria empieza a
  /// registrar su periodo.
  final int? selfReportedCycleLen;

  /// Igual que [selfReportedCycleLen] pero para la duración del periodo,
  /// usado como respaldo en getAvgPeriodLength() mientras no hay ningún
  /// ciclo registrado todavía.
  final int? selfReportedPeriodLen;

  /// Multiplicador aplicado al ancho del rango (normalmente ± desviación
  /// estándar reciente, mínimo 3 días) cuando el modo irregular manual
  /// está activo — ensancha la ventana mostrada para reflejar mejor que
  /// una fecha exacta no es realista en este caso.
  static const double _manualIrregularSpreadMultiplier = 2.0;

  CyclePredictor(
    this.data, {
    this.forceIrregular = false,
    this.selfReportedCycleLen,
    this.selfReportedPeriodLen,
  });

  List<String> _periodDateKeys() {
    final keys = data.entries
        .where((e) => e.value.isPeriodDay)
        .map((e) => e.key)
        .toList();
    keys.sort();
    return keys;
  }

  /// Agrupa fechas de flujo consecutivas (o casi consecutivas) en ciclos.
  ///
  /// Tolera un hueco de hasta 2 días sin flujo registrado DENTRO de lo que
  /// sigue pareciendo la misma racha de período (p. ej. la usuaria olvidó
  /// marcar un día intermedio) — antes cualquier hueco >1.5 días cortaba
  /// el grupo en dos "ciclos" distintos, y con eso un solo olvido de
  /// registro podía hacer que `getAvgCycleLength()` calculara un promedio
  /// de solo unos pocos días (la distancia entre el trocito aislado y el
  /// resto de la racha) en vez de ignorar el hueco, distorsionando toda
  /// la predicción de "Previsto"/"Fértil" en el calendario.
  ///
  /// El umbral de tolerancia (2 días) es deliberadamente corto: sigue
  /// exigiendo que haya al menos un día CON flujo después del hueco para
  /// unir el grupo (si el hueco no vuelve a tener flujo, no hay nada que
  /// unir — ya se cortó solo). Manchado/spotting aislado a varios días de
  /// distancia de la racha principal sigue detectándose como grupo
  /// separado, tal como antes.
  static const double _sameCycleGapToleranceDays = 2.5;

  List<List<String>> getCycles() {
    final dates = _periodDateKeys();
    final cycles = <List<String>>[];
    var current = <String>[];

    for (final key in dates) {
      if (current.isEmpty) {
        current.add(key);
        continue;
      }
      final prev = _parseKey(current.last);
      final cur = _parseKey(key);
      final diffDays = cur.difference(prev).inHours / 24.0;
      if (diffDays <= _sameCycleGapToleranceDays) {
        current.add(key);
      } else {
        cycles.add(current);
        current = [key];
      }
    }
    if (current.isNotEmpty) cycles.add(current);
    return cycles;
  }

  /// Duraciones (en días) entre el inicio de cada ciclo y el siguiente,
  /// SIN filtrar por rango "típico" — solo se descartan diferencias
  /// imposibles (≤0, o >120 días, que casi siempre son un error de
  /// registro más que un ciclo real). A diferencia de la versión anterior
  /// (que excluía todo lo que no estuviera entre 15 y 60 días), esta lista
  /// conserva ciclos largos reales — por ejemplo los de 60–90+ días que
  /// pueden darse con SOP (ovario poliquístico) o perimenopausia — para
  /// que no desaparezcan silenciosamente del cálculo de irregularidad.
  List<double> _rawCycleLengths() {
    final cycles = getCycles();
    final lengths = <double>[];
    for (var i = 1; i < cycles.length; i++) {
      final startPrev = _parseKey(cycles[i - 1].first);
      final startCur = _parseKey(cycles[i].first);
      final diff = startCur.difference(startPrev).inHours / 24.0;
      if (diff > 0 && diff <= 120) lengths.add(diff);
    }
    return lengths;
  }

  /// Igual que [_rawCycleLengths], pero restringida al rango "típico" de
  /// un ciclo menstrual (15–60 días) — se usa solo para calcular la fecha
  /// de predicción y la ovulación, donde promediar un ciclo de 90 días
  /// junto con varios de 28 días daría una fecha sin sentido. Ciclos fuera
  /// de este rango siguen contando en [_rawCycleLengths] para que la app
  /// los reconozca como parte de un patrón irregular, en vez de
  /// ignorarlos por completo.
  List<double> _typicalCycleLengths() {
    return _rawCycleLengths().where((d) => d > 15 && d < 60).toList();
  }

  int getAvgCycleLength() {
    final cycles = getCycles();
    // Sin al menos 2 ciclos registrados no hay forma de promediar nada
    // real todavía — en vez de asumir el genérico de 28 días, se usa la
    // duración que la propia usuaria reportó en el cuestionario de
    // "Intentando concebir" (si la dio), que suele ser más certera que un
    // valor genérico para una cuenta nueva.
    if (cycles.length < 2) return selfReportedCycleLen ?? kDefaultCycleLen;

    final typical = _typicalCycleLengths();
    if (typical.isNotEmpty) {
      return (typical.reduce((a, b) => a + b) / typical.length).round();
    }
    // Si NINGÚN ciclo registrado cae en el rango típico (p. ej. todos son
    // de 65+ días), no tiene sentido devolver el valor genérico de 28 días
    // como si nada — sería una fecha con falsa confianza. En su lugar,
    // promediamos los ciclos reales tal cual, aunque estén fuera del
    // rango típico: sigue siendo mejor estimación que ignorarlos.
    final raw = _rawCycleLengths();
    if (raw.isNotEmpty) {
      return (raw.reduce((a, b) => a + b) / raw.length).round();
    }
    return selfReportedCycleLen ?? kDefaultCycleLen;
  }

  /// Umbral (días de desviación estándar) a partir del cual se considera
  /// que el ciclo es irregular. Con 3+ días de variación típica, una
  /// fecha exacta suele fallar — mejor comunicar un rango realista.
  static const double _irregularityThresholdDays = 3.0;

  bool isIrregular() {
    // El interruptor manual de Configuración siempre gana: si la usuaria
    // dice que su ciclo es irregular, lo tratamos como tal aunque el
    // historial registrado (o la falta de él) no lo confirme todavía.
    if (forceIrregular) return true;
    // Usamos _rawCycleLengths (no _typicalCycleLengths) a propósito: si
    // alguien tiene ciclos de 65+ días de forma constante, eso es
    // irregularidad real (posible SOP/perimenopausia), y antes se perdía
    // por completo porque esos ciclos quedaban fuera del rango "típico"
    // de 15-60 días usado solo para calcular la fecha de predicción.
    final lengths = _rawCycleLengths();
    if (lengths.length < 3) return false;
    final recent = lengths.length > 6 ? lengths.sublist(lengths.length - 6) : lengths;
    final stdDev = _stdDev(recent);
    // Además de la desviación estándar (variación entre ciclos), un ciclo
    // cuya duración típica reciente esté fuera del rango clínico habitual
    // (21–35 días) también cuenta como irregular, aunque sea consistente
    // — por ejemplo, alguien con ciclos siempre de 65 días no varía mucho
    // entre sí (stdDev bajo) pero claramente no sigue un patrón "normal".
    final mean = recent.reduce((a, b) => a + b) / recent.length;
    final outsideTypicalRange = mean < 21 || mean > 35;
    return stdDev >= _irregularityThresholdDays || outsideTypicalRange;
  }

  double _stdDev(List<double> values) {
    if (values.length < 2) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    return variance <= 0 ? 0 : sqrt(variance);
  }

  int getAvgPeriodLength() {
    final cycles = getCycles();
    // Igual que en getAvgCycleLength(): sin ningún periodo registrado
    // todavía, se prioriza lo autoreportado por la usuaria sobre el
    // genérico de 5 días.
    if (cycles.isEmpty) return selfReportedPeriodLen ?? kDefaultPeriodLen;
    final lens = cycles.map((c) => c.length).toList();

    // Un grupo de 1-2 días sueltos casi siempre es manchado
    // (spotting/intermenstrual), no un periodo completo — si se cuenta
    // como si fuera un "ciclo" más, arrastra el promedio de duración del
    // periodo hacia abajo de forma irreal (ej. periodos reales de 5 días
    // que bajan a 4 solo por un día de manchado registrado aparte).
    // Se excluye del promedio SOLO si hay al menos un ciclo "real" (3+
    // días) con el que calcular — si todo el historial son grupos de 1-2
    // días, se usan tal cual en vez de devolver el valor genérico.
    final realPeriods = lens.where((l) => l >= 3).toList();
    final source = realPeriods.isNotEmpty ? realPeriods : lens;
    final avg = source.reduce((a, b) => a + b) / source.length;
    return avg.round();
  }

  DateTime? predictNextPeriod() {
    final cycles = getCycles();
    if (cycles.isEmpty) return null;
    final lastCycle = cycles.last;
    final lastStart = _parseKey(lastCycle.first);
    final cycleLen = getAvgCycleLength();
    return lastStart.add(Duration(days: cycleLen));
  }

  /// Temperatura basal (BBT) registrada ese día, si la usuaria la anotó
  /// (`DayEntry.temp`), o null si no hay lectura para esa fecha.
  double? _tempFor(String key) => data[key]?.temp;

  /// Detecta el día de ovulación CONFIRMADO por temperatura basal dentro
  /// de un ciclo ya cerrado ([cycleStart], [cycleEndExclusive]), con el
  /// método "3 sobre 6" que usan apps de fertilidad como Fertility Friend
  /// o Kindara: busca 3 lecturas seguidas al menos 0.2°C por encima del
  /// promedio de las 6 lecturas válidas anteriores (la "línea base"), y
  /// devuelve el último día "bajo" justo antes de esa subida sostenida —
  /// la ovulación suele ocurrir ahí, un día antes de que la temperatura
  /// empiece a notarse más alta. Sin temperatura suficiente registrada
  /// ese ciclo, devuelve null (no es un diagnóstico médico, solo una
  /// estimación a partir de lo que la usuaria fue anotando).
  DateTime? _bbtConfirmedOvulation(DateTime cycleStart, DateTime cycleEndExclusive) {
    final days = <DateTime>[];
    for (var d = cycleStart; d.isBefore(cycleEndExclusive); d = d.add(const Duration(days: 1))) {
      days.add(d);
    }
    final temps = <double?>[for (final d in days) _tempFor(dateKey(d))];

    for (var i = 6; i <= days.length - 3; i++) {
      final baseline = <double>[];
      for (var j = i - 6; j < i; j++) {
        final t = temps[j];
        if (t != null) baseline.add(t);
      }
      // Con menos de 4 lecturas de las 6 posibles, la línea base no es
      // confiable — mejor no confirmar nada que confirmar con poco dato.
      if (baseline.length < 4) continue;
      final baselineAvg = baseline.reduce((a, b) => a + b) / baseline.length;

      final rise = temps.sublist(i, i + 3);
      if (rise.any((t) => t == null)) continue;
      final sustained = rise.every((t) => t! >= baselineAvg + 0.2);
      if (sustained) return days[i - 1];
    }
    return null;
  }

  /// Duración de la fase lútea (ovulación -> inicio del periodo
  /// siguiente) calculada con temperatura basal real de ciclos ya
  /// cerrados, en vez de asumir siempre 14 días fijos para todo el mundo
  /// — la fase lútea real varía bastante entre personas (típicamente
  /// 10-16 días) y usar la propia si hay temperatura registrada da una
  /// fecha de ovulación más personal. Solo cuenta ciclos donde el método
  /// de temperatura pudo confirmar un día de ovulación y donde la
  /// duración resultante cae en un rango fisiológicamente normal (9-17
  /// días) — fuera de ahí es casi seguro un error de lectura, no un dato
  /// real. Sin temperatura suficiente registrada en ningún ciclo,
  /// devuelve null y el cálculo sigue usando el valor por defecto.
  int? _personalizedLutealPhase() {
    final cycles = getCycles();
    if (cycles.length < 2) return null;

    final lengths = <int>[];
    for (var i = 0; i < cycles.length - 1; i++) {
      final cycleStart = _parseKey(cycles[i].first);
      final nextCycleStart = _parseKey(cycles[i + 1].first);
      final ovulation = _bbtConfirmedOvulation(cycleStart, nextCycleStart);
      if (ovulation == null) continue;
      final luteal = nextCycleStart.difference(ovulation).inDays;
      if (luteal >= 9 && luteal <= 17) lengths.add(luteal);
    }
    if (lengths.isEmpty) return null;
    return (lengths.reduce((a, b) => a + b) / lengths.length).round();
  }

  /// Días de fase lútea a usar en todos los cálculos de ovulación: la
  /// propia (ver [_personalizedLutealPhase]) si hay temperatura basal
  /// suficiente registrada, o 14 días (promedio general) si no.
  int _lutealPhaseLength() => _personalizedLutealPhase() ?? 14;

  DateTime? predictOvulation(DateTime? nextPeriod) {
    if (nextPeriod == null) return null;
    return nextPeriod.subtract(Duration(days: _lutealPhaseLength()));
  }

  /// Cuántos días han pasado desde el inicio del ciclo actual (día 0 =
  /// primer día de sangrado del ciclo en curso), o null si no hay datos
  /// suficientes o si el último ciclo registrado quedó en el futuro.
  /// Extraído de currentPhaseKey() para poder reutilizarlo en el
  /// diagrama de etapas de Revisión (posición del indicador sobre el
  /// círculo de 4 fases), sin duplicar la lógica de "día actual".
  int? currentDayInCycle() {
    final cycles = getCycles();
    if (cycles.isEmpty) return null;
    final lastCycleStart = _parseKey(cycles.last.first);
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final dayInCycle = todayMidnight.difference(lastCycleStart).inDays;
    if (dayInCycle < 0) return null;
    return dayInCycle;
  }

  /// Fase actual del ciclo ('menstrual' | 'folicular' | 'ovulacion' |
  /// 'lutea'), o null si no hay datos suficientes para calcularla.
  /// Se usa tanto en el consejo de la cabecera (main_tab_screen) como en
  /// el contenido educativo dinámico de Estadísticas.
  String? currentPhaseKey() {
    final dayInCycle = currentDayInCycle();
    if (dayInCycle == null) return null;

    final periodLen = getAvgPeriodLength();
    final cycleLen = getAvgCycleLength();
    final ovulationDay = cycleLen - _lutealPhaseLength();

    if (dayInCycle < periodLen) return 'menstrual';
    if (dayInCycle < ovulationDay - 2) return 'folicular';
    if (dayInCycle <= ovulationDay + 1) return 'ovulacion';
    return 'lutea';
  }

  /// Igual que [currentPhaseKey], pero para una fecha arbitraria (no solo
  /// hoy) — se usa para clasificar lecturas históricas de salud (HRV,
  /// frecuencia cardíaca, temperatura) según la fase del ciclo en la que
  /// cayó cada una, y así poder comparar esa métrica entre fases en
  /// Estadísticas. Busca en qué ciclo de [getCycles] cae la fecha (el
  /// ciclo cuyo rango [inicio, inicio del siguiente) la contiene, o el
  /// último ciclo si la fecha es posterior a su inicio y no hay un
  /// ciclo siguiente todavía), calcula el día dentro de ese ciclo y
  /// aplica los mismos umbrales que [currentPhaseKey]. Devuelve null si
  /// no hay ciclos registrados o si la fecha es anterior al primer ciclo.
  String? phaseKeyForDate(DateTime date) {
    final cycles = getCycles();
    if (cycles.isEmpty) return null;
    final target = DateTime(date.year, date.month, date.day);

    for (var i = 0; i < cycles.length; i++) {
      final cycleStart = _parseKey(cycles[i].first);
      final isLast = i == cycles.length - 1;
      final cycleEnd = isLast ? null : _parseKey(cycles[i + 1].first);
      final withinCycle = !target.isBefore(cycleStart) && (cycleEnd == null || target.isBefore(cycleEnd));
      if (!withinCycle) continue;

      final dayInCycle = target.difference(cycleStart).inDays;
      final periodLen = getAvgPeriodLength();
      final cycleLen = getAvgCycleLength();
      final ovulationDay = cycleLen - _lutealPhaseLength();

      if (dayInCycle < periodLen) return 'menstrual';
      if (dayInCycle < ovulationDay - 2) return 'folicular';
      if (dayInCycle <= ovulationDay + 1) return 'ovulacion';
      return 'lutea';
    }
    return null;
  }

  CyclePrediction predict() {
    final next = predictNextPeriod();
    if (next == null) return const CyclePrediction();

    final irregular = isIrregular();

    // Con ciclo irregular, la ventana de días marcados como "predicción"
    // en el calendario se ensancha (± la desviación estándar reciente,
    // con un mínimo de 3 días) en vez de un bloque fijo desde una sola
    // fecha exacta, para reflejar mejor la incertidumbre real.
    DateTime rangeStart = next;
    DateTime rangeEnd = next;
    var spread = 0;
    if (irregular) {
      final lengths = _rawCycleLengths();
      final recent = lengths.length > 6 ? lengths.sublist(lengths.length - 6) : lengths;
      spread = max(3, _stdDev(recent).round());
      // Con el modo irregular activado a mano, ensanchamos aún más el
      // rango (por defecto el doble, con un mínimo de 7 días) — sin
      // historial suficiente, `_stdDev` puede devolver un spread mínimo
      // de solo 3 días, que sigue sonando "demasiado exacto" para quien
      // ya sabe que su ciclo no es predecible.
      if (forceIrregular) {
        spread = max(7, (spread * _manualIrregularSpreadMultiplier).round());
      }
      rangeStart = next.subtract(Duration(days: spread));
      rangeEnd = next.add(Duration(days: spread));
    }

    final periodLen = getAvgPeriodLength();
    final periodDates = <String>{};
    final windowStart = irregular ? rangeStart : next;
    final windowDays = irregular ? rangeEnd.difference(rangeStart).inDays + periodLen : periodLen;
    for (var i = 0; i < windowDays; i++) {
      periodDates.add(dateKey(windowStart.add(Duration(days: i))));
    }

    final ov = predictOvulation(next)!;
    // La ventana fértil (ovulación -5 a +1) es la misma base de 7 días
    // siempre, pero si el ciclo es irregular la fecha de ovulación en sí
    // no es confiable (viene de `next`, que ya sabemos que puede fallar
    // por varios días) — así que igual que con el periodo, ensanchamos la
    // ventana con el mismo "spread" en vez de mostrar un rango de fechas
    // con falsa precisión. Antes esto NO pasaba: la ventana fértil se
    // mostraba siempre exacta aunque el periodo ya avisara que no lo era.
    final fertileWindowStart = ov.subtract(Duration(days: 5 + spread));
    final fertileWindowEnd = ov.add(Duration(days: 1 + spread));
    final fertileDates = <String>{};
    for (var d = fertileWindowStart; !d.isAfter(fertileWindowEnd); d = d.add(const Duration(days: 1))) {
      fertileDates.add(dateKey(d));
    }
    // Además de la ventana calculada por calendario, cualquier día DEL
    // CICLO ACTUAL con moco cervical de tipo fértil (clara de huevo o
    // acuoso, ver DayEntry.cervicalMucus) también cuenta como fértil,
    // aunque caiga fuera de esa ventana — es una señal física real
    // registrada por la usuaria, más fiable en el momento que una
    // estimación por promedios (mismo método sintotérmico que ya
    // describe el catálogo de moco cervical, ahora aplicado aquí).
    final currentCycleStart = _parseKey(getCycles().last.first);
    for (final entry in data.entries) {
      final mucus = entry.value.cervicalMucus;
      if (mucus != 'eggwhite' && mucus != 'watery') continue;
      final entryDate = _parseKey(entry.key);
      if (entryDate.isBefore(currentCycleStart)) continue;
      fertileDates.add(entry.key);
    }

    return CyclePrediction(
      nextPeriodStart: next,
      ovulationDate: ov,
      predictedPeriodDates: periodDates,
      fertileDates: fertileDates,
      isIrregular: irregular,
      rangeStart: irregular ? rangeStart : null,
      rangeEnd: irregular ? rangeEnd : null,
      fertileRangeStart: irregular ? fertileWindowStart : null,
      fertileRangeEnd: irregular ? fertileWindowEnd : null,
    );
  }

  /// Probabilidad de concepción (0.0-1.0) para un día arbitrario del ciclo
  /// (0 = primer día de sangrado), modelada como una curva tipo campana
  /// centrada en el día de ovulación (cycleLen - fase lútea, ver
  /// [_lutealPhaseLength]), con la ventana fértil real (ovulación -5 a
  /// +1, mismo criterio que `predict().fertileDates`) como la zona de
  /// probabilidad alta/media, y el resto del ciclo en probabilidad
  /// baja/cero. No pretende ser un modelo clínico preciso — es una
  /// aproximación visual razonable para mostrar la tendencia.
  double conceptionProbabilityForCycleDay(int dayInCycle) {
    final cycleLen = getAvgCycleLength();
    final ovulationDay = cycleLen - _lutealPhaseLength();
    final distance = (dayInCycle - ovulationDay).abs();
    if (distance > 6) return 0.05; // baja pero no exactamente cero
    // Campana simple: pico en ovulationDay, decae linealmente hacia los bordes de la ventana de 6 días.
    return (1.0 - (distance / 6.0)).clamp(0.05, 1.0);
  }

  /// Clasifica una probabilidad 0.0-1.0 en 'baja' | 'media' | 'alta'.
  String conceptionLevelLabel(double probability) {
    if (probability >= 0.66) return 'alta';
    if (probability >= 0.33) return 'media';
    return 'baja';
  }
}

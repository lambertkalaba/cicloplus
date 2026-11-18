import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/store.dart';
import '../strings.dart';

/// Un Ramadán: primer día y último día (incluidos).
class RamadanPeriod {
  const RamadanPeriod(this.start, this.end);
  final DateTime start;
  final DateTime end;
  int get length => end.difference(start).inDays + 1;
  bool contains(DateTime d) => !d.isBefore(start) && !d.isAfter(end);
}

/// Modo Ramadán: los días de regla que caen en Ramadán no se ayunan y se
/// recuperan después. Cuenta esos días con lo que ella registra y lleva la
/// cuenta de los que ya ha recuperado (marcados en `DayLog.extra['qada']`,
/// así se guardan y se sincronizan con el resto de su registro).
class Ramadan extends ChangeNotifier {
  Ramadan._();
  static final Ramadan instance = Ramadan._();

  /// Primer día previsto (calendario Umm al-Qura). Según el país y la luna
  /// puede empezar un día después: por eso se puede ajustar.
  static final _starts = <DateTime>[
    DateTime(2025, 3, 1),
    DateTime(2026, 2, 18),
    DateTime(2027, 2, 8),
    DateTime(2028, 1, 28),
    DateTime(2029, 1, 16),
    DateTime(2030, 1, 5),
    DateTime(2030, 12, 26),
    DateTime(2031, 12, 15),
    DateTime(2032, 12, 4),
    DateTime(2033, 11, 23),
    DateTime(2034, 11, 12),
  ];

  /// Idiomas en los que el modo viene activado de serie.
  static const _defaultOn = {'ar', 'ur', 'fa', 'id', 'ms', 'tr', 'uz', 'kk', 'az', 'ha', 'wo', 'so', 'bn'};

  bool _loaded = false;
  bool? _enabled;
  int _offset = 0;
  int _days = 30;

  bool get enabled => _enabled ?? _defaultOn.contains(L.lang);
  int get offset => _offset;
  int get days => _days;

  void ensureLoaded() {
    if (_loaded) return;
    _loaded = true;
    SharedPreferences.getInstance().then((p) {
      _enabled = p.getBool('ramadan_on');
      _offset = p.getInt('ramadan_offset') ?? 0;
      _days = p.getInt('ramadan_days') ?? 30;
      notifyListeners();
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    if (_enabled != null) await p.setBool('ramadan_on', _enabled!);
    await p.setInt('ramadan_offset', _offset);
    await p.setInt('ramadan_days', _days);
    notifyListeners();
  }

  Future<void> setEnabled(bool v) {
    _enabled = v;
    return _save();
  }

  Future<void> setOffset(int v) {
    _offset = v.clamp(-2, 2).toInt();
    return _save();
  }

  Future<void> setDays(int v) {
    _days = v == 29 ? 29 : 30;
    return _save();
  }

  List<RamadanPeriod> get all => [
        for (final s in _starts)
          RamadanPeriod(addDays(s, _offset), addDays(s, _offset + _days - 1)),
      ];

  /// El Ramadán de ahora, o el próximo.
  RamadanPeriod? currentOrNext([DateTime? today]) {
    final t = dateOnly(today ?? DateTime.now());
    for (final r in all) {
      if (!r.end.isBefore(t)) return r;
    }
    return null;
  }

  /// El último Ramadán que ya terminó.
  RamadanPeriod? lastFinished([DateTime? today]) {
    final t = dateOnly(today ?? DateTime.now());
    RamadanPeriod? last;
    for (final r in all) {
      if (r.end.isBefore(t)) last = r;
    }
    return last;
  }

  bool isActive([DateTime? today]) {
    final t = dateOnly(today ?? DateTime.now());
    final r = currentOrNext(t);
    return r != null && r.contains(t);
  }

  /// Días de regla registrados dentro de [r] (hasta hoy).
  int periodDays(RamadanPeriod r) {
    final s = AppStore.instance;
    final today = dateOnly(DateTime.now());
    var n = 0;
    for (var d = r.start; !d.isAfter(r.end) && !d.isAfter(today); d = addDays(d, 1)) {
      if (s.isPeriodDay(d)) n++;
    }
    return n;
  }

  static bool madeUpOn(DateTime d) => AppStore.instance.logFor(d).extra['qada'] == true;

  static Future<void> setMadeUp(DateTime d, bool v) => AppStore.instance.updateLog(d, (l) {
        if (v) {
          l.extra['qada'] = true;
        } else {
          l.extra.remove('qada');
        }
      });

  /// Días recuperados después de [r] (hasta el siguiente Ramadán).
  int madeUpAfter(RamadanPeriod r) {
    final list = all;
    final i = list.indexWhere((x) => x.start == r.start);
    final limit = i >= 0 && i + 1 < list.length ? addDays(list[i + 1].start, -1) : addDays(r.end, 354);
    var n = 0;
    AppStore.instance.logs.forEach((k, v) {
      if (v.extra['qada'] != true) return;
      final d = parseKey(k);
      if (d.isAfter(r.end) && !d.isAfter(limit)) n++;
    });
    return n;
  }

  /// Ramadán del que se están recuperando días ahora (el último que terminó).
  RamadanPeriod? get debtRamadan => lastFinished();

  /// Días que le quedan por recuperar del último Ramadán.
  int get pending {
    final r = debtRamadan;
    if (r == null) return 0;
    final p = periodDays(r) - madeUpAfter(r);
    return p < 0 ? 0 : p;
  }

  /// Días del Ramadán [r] en los que, según su ciclo, podría tener la regla.
  List<DateTime> predictedPeriodDays(RamadanPeriod r) {
    final s = AppStore.instance;
    final out = <DateTime>[];
    final today = dateOnly(DateTime.now());
    for (final st in s.predictedStarts(14)) {
      for (var i = 0; i < s.avgPeriod; i++) {
        final d = addDays(st, i);
        if (r.contains(d) && d.isAfter(today)) out.add(d);
      }
    }
    return out;
  }

  /// "8 feb – 9 mar 2027".
  static String range(RamadanPeriod r) {
    String dm(DateTime d) => '${d.day} ${L.monthShort(d.month).toLowerCase()}';
    return '${dm(r.start)} – ${dm(r.end)} ${r.end.year}';
  }

  /// Texto corto del estado: "Faltan 12 días", "Día 5 de 30"...
  String status([DateTime? today]) {
    final t = dateOnly(today ?? DateTime.now());
    final r = currentOrNext(t);
    if (r == null) return '';
    if (r.contains(t)) {
      return tr('Día {} de {}', 'Day {} of {}')
          .replaceFirst('{}', '${t.difference(r.start).inDays + 1}')
          .replaceFirst('{}', '${r.length}');
    }
    final n = r.start.difference(t).inDays;
    return n == 1 ? tr('Empieza mañana', 'Starts tomorrow') : tr('Faltan {} días', '{} days to go').replaceFirst('{}', '$n');
  }

  /// ¿Se enseña la tarjeta en Hoy? Si está activado y el Ramadán está en
  /// curso, empieza en menos de 2 semanas o quedan días por recuperar.
  bool get showOnToday {
    if (!enabled) return false;
    final t = dateOnly(DateTime.now());
    final r = currentOrNext(t);
    if (r != null && (r.contains(t) || r.start.difference(t).inDays <= 14)) return true;
    return pending > 0;
  }
}

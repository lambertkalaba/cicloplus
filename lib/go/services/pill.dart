import '../data/store.dart';

/// Píldora anticonceptiva: marca de "tomada" por día (en `DayLog.extra`)
/// y racha de días seguidos.
class PillTracker {
  PillTracker._();

  static bool takenOn(DateTime d) => AppStore.instance.logFor(d).extra['pillTaken'] == true;

  static Future<void> setTaken(DateTime d, bool taken) => AppStore.instance.updateLog(d, (l) {
        if (taken) {
          l.extra['pillTaken'] = true;
        } else {
          l.extra.remove('pillTaken');
        }
      });

  /// Días seguidos con la píldora tomada, contando hoy (o desde ayer si hoy
  /// aún no se ha marcado).
  static int streak() {
    var d = dateOnly(DateTime.now());
    if (!takenOn(d)) d = addDays(d, -1);
    var n = 0;
    while (takenOn(d) && n < 3650) {
      n++;
      d = addDays(d, -1);
    }
    return n;
  }
}

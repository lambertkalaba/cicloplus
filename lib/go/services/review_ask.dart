import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/store.dart';

/// Pide una reseña en la tienda (ventanita oficial de Google/Apple, sin salir
/// de la app) solo en un buen momento: al guardar el registro del día, cuando
/// ya lleva días usando la app y tiene datos. Como mucho 3 veces y con 4 meses
/// entre una y otra. Google/Apple además deciden si la enseñan o no.
class ReviewAsk {
  static const _first = 'review_first_open';
  static const _last = 'review_last_ask';
  static const _count = 'review_ask_count';

  static Future<void> markOpen() async {
    final p = await SharedPreferences.getInstance();
    if (!p.containsKey(_first)) await p.setInt(_first, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> afterSave() async {
    try {
      final p = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final first = p.getInt(_first) ?? now;
      if (!p.containsKey(_first)) await p.setInt(_first, now);
      const day = 86400000;
      if (now - first < 3 * day) return;
      final s = AppStore.instance;
      if (s.logs.length < 5 && s.periodStarts.length < 2) return;
      final n = p.getInt(_count) ?? 0;
      if (n >= 3) return;
      if (now - (p.getInt(_last) ?? 0) < 120 * day) return;
      final r = InAppReview.instance;
      if (!await r.isAvailable()) return;
      await p.setInt(_last, now);
      await p.setInt(_count, n + 1);
      await Future.delayed(const Duration(milliseconds: 900));
      await r.requestReview();
    } catch (_) {}
  }
}

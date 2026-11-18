import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/store.dart';
import '../strings.dart';
import 'michi_sound.dart';
import 'michi_voice.dart';
import 'ui.dart';

/// Chistes de Michi: 500 por idioma (assets/jokes/<idioma>.json), máximo dos
/// al día. Michi elige el tipo de chiste según cómo está ella hoy:
///  * fun  → se siente bien o con energía
///  * soft → cansada, triste o con dolor (chistes tiernos, de cuidarse)
///  * calm → día normal o sin registrar (chistes tranquilos)
/// Cada tipo lleva su propio contador guardado, así no se repite ninguno
/// hasta haber contado todos los de ese tipo (meses).
class MichiJokes {
  MichiJokes._();

  static Map<String, List<String>>? _cache;
  static String? _cacheLang;

  static Future<Map<String, List<String>>> _load() async {
    final lang = L.lang;
    if (_cache != null && _cacheLang == lang) return _cache!;
    Map<String, dynamic> j;
    try {
      j = jsonDecode(await rootBundle.loadString('assets/jokes/$lang.json')) as Map<String, dynamic>;
    } catch (_) {
      j = jsonDecode(await rootBundle.loadString('assets/jokes/en.json')) as Map<String, dynamic>;
    }
    _cache = {for (final e in j.entries) e.key: (e.value as List).map((x) => x.toString()).toList()};
    _cacheLang = lang;
    return _cache!;
  }

  /// Tipo de chiste según el registro de hoy.
  static String get mood {
    final l = AppStore.instance.logFor(DateTime.now());
    if (l.pain >= 2) return 'soft';
    if (l.mood >= 4) return 'fun';
    if (l.mood >= 1 && l.mood <= 2) return 'soft';
    if (l.symptoms.any((s) => const {'tired', 'fatigue', 'cansancio', 'cramps', 'colicos', 'headache'}.contains(s))) {
      return 'soft';
    }
    return l.mood == 3 ? 'calm' : (DateTime.now().day.isEven ? 'calm' : 'fun');
  }

  /// Orden barajado fijo para cada tipo (mismo orden siempre en este móvil).
  static List<int> _order(int n, String cat) {
    final list = List<int>.generate(n, (i) => i);
    list.shuffle(Random(cat.codeUnits.fold<int>(7, (a, b) => a * 31 + b) & 0x7fffffff));
    return list;
  }

  /// Saca el siguiente chiste sin repetir del tipo dado.
  static Future<int> _next(SharedPreferences p, String cat, int n) async {
    final k = 'michi_joke_ptr_$cat';
    final ptr = p.getInt(k) ?? 0;
    await p.setInt(k, ptr + 1);
    return _order(n, cat)[ptr % n];
  }

  static String _today() {
    final d = DateTime.now();
    return '${d.year}-${d.month}-${d.day}';
  }

  /// Chiste n (1 o 2) de hoy; si ya se sacó, devuelve el mismo.
  static Future<String> _joke(SharedPreferences p, int n) async {
    final all = await _load();
    final key = 'michi_joke_pick$n';
    final saved = p.getString(key);
    if (p.getString('michi_joke_day') == _today() && saved != null) {
      final parts = saved.split(':');
      final list = all[parts[0]];
      final i = int.tryParse(parts.length > 1 ? parts[1] : '');
      if (list != null && i != null && i < list.length) return list[i];
    }
    var cat = mood;
    if (!(all[cat]?.isNotEmpty ?? false)) cat = all.keys.first;
    final list = all[cat]!;
    final i = await _next(p, cat, list.length);
    await p.setString(key, '$cat:$i');
    return list[i];
  }

  static Future<void> show(BuildContext context) async {
    final p = await SharedPreferences.getInstance();
    final today = _today();
    final seen = p.getString('michi_joke_day') == today ? (p.getInt('michi_joke_n') ?? 0) : 0;
    if (!context.mounted) return;
    var n = seen == 0 ? 1 : seen; // el que toca enseñar ahora (1 o 2)
    if (seen == 0) {
      await p.remove('michi_joke_pick1');
      await p.remove('michi_joke_pick2');
    }
    final first = await _joke(p, 1);
    var second = n == 2 ? await _joke(p, 2) : '';
    if (seen == 0) {
      await p.setString('michi_joke_day', today);
      await p.setInt('michi_joke_n', 1);
    }
    HapticFeedback.lightImpact();
    if (!MichiVoice.enabled) MichiSound.meow();
    if (!context.mounted) return;
    // Michi lo cuenta en voz alta (si la voz está activada).
    MichiVoice.say(n == 1 ? first : second);
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: C.t(0xFFFFF7FB),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Img('michi_happy', size: 90, fallback: Icons.pets_rounded),
              const SizedBox(height: 8),
              Text(n == 1 ? tr('El chiste de hoy 😹', "Today's joke 😹") : tr('¡Uno más! 😹', 'One more! 😹'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: C.pinkDark)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => MichiVoice.say(n == 1 ? first : second),
                child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: Text(
                  n == 1 ? first : second,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, height: 1.4, fontWeight: FontWeight.w700, color: C.text),
                ),
              ),
              ),
              const SizedBox(height: 14),
              if (n == 1)
                TextButton.icon(
                  onPressed: () async {
                    await p.setInt('michi_joke_n', 2);
                    final s = await _joke(p, 2);
                    if (!MichiVoice.enabled) MichiSound.purr();
                    MichiVoice.say(s);
                    set(() {
                      second = s;
                      n = 2;
                    });
                  },
                  icon: const Text('😸'),
                  label: Text(tr('Otro, porfa', 'Another one, please'), style: TextStyle(fontWeight: FontWeight.w900, color: C.pinkDark)),
                )
              else
                Text(tr('Mañana te cuento otro 🐾', "I'll tell you another one tomorrow 🐾"),
                    style: const TextStyle(fontSize: 13, color: C.muted, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    );
    MichiVoice.stop();
  }
}

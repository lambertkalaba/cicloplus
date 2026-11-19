import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/store.dart';
import '../strings.dart';
import 'notifications.dart';
import '../widgets/michi_events.dart' show MichiEvents;

/// Tradición elegida por ella (opcional). Se guarda SOLO en el móvil
/// (SharedPreferences): no se sincroniza ni sale nunca del dispositivo.
///   null       → no ha elegido nada (se comporta como "Ninguna")
///   'none'     → Ninguna
///   'muslim'   → Musulmana: Ramadán
///   'christian'→ Cristiana: felicitación el día de su santo
class Traditions extends ChangeNotifier {
  Traditions._();
  static final Traditions instance = Traditions._();

  static const ids = ['none', 'muslim', 'christian'];
  static const _notifId = 4100;

  bool _loaded = false;
  String? _id;
  String? _santoMd; // 'MM-DD' elegido a mano

  /// Lo que ha elegido (null si nunca ha entrado en Tradiciones).
  String? get chosen => _id;
  String get id => _id ?? 'none';
  bool get muslim => _id == 'muslim';
  bool get christian => _id == 'christian';

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final p = await SharedPreferences.getInstance();
    _id = p.getString('tradition');
    // Quien ya tenía el Ramadán activado antes de existir Tradiciones.
    if (_id == null && p.getBool('ramadan_on') == true) {
      _id = 'muslim';
      await p.setString('tradition', _id!);
    }
    // Quien tenía "Felicitarme por mi santo" en Configuración.
    if (_id == null && p.getBool('michiSaint') == true) {
      _id = 'christian';
      await p.setString('tradition', _id!);
    }
    _santoMd = p.getString('santo_md');
    notifyListeners();
    scheduleSanto();
  }

  Future<void> setId(String v) async {
    _id = v;
    final p = await SharedPreferences.getInstance();
    await p.setString('tradition', v);
    notifyListeners();
    scheduleSanto();
  }

  Future<void> setSanto(int month, int day) async {
    _santoMd = '${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    final p = await SharedPreferences.getInstance();
    await p.setString('santo_md', _santoMd!);
    notifyListeners();
    scheduleSanto();
  }

  /// (mes, día) de su santo: el que eligió a mano o el de su nombre.
  (int, int)? get santo {
    final md = _santoMd;
    if (md != null && md.length == 5) return (int.parse(md.substring(0, 2)), int.parse(md.substring(3)));
    return santoForName(AppStore.instance.name) ?? MichiEvents.saintFor(AppStore.instance.name);
  }

  bool get santoFromName => _santoMd == null && santo != null;

  bool isSantoDay(DateTime d) {
    if (!christian) return false;
    final s = santo;
    return s != null && d.month == s.$1 && d.day == s.$2;
  }

  /// Próximo día de su santo (hoy incluido).
  DateTime? nextSanto([DateTime? from]) {
    final s = santo;
    if (s == null) return null;
    final t = dateOnly(from ?? DateTime.now());
    var d = DateTime(t.year, s.$1, s.$2);
    if (d.isBefore(t)) d = DateTime(t.year + 1, s.$1, s.$2);
    return d;
  }

  String get greeting {
    final n = AppStore.instance.name.trim().split(RegExp(r'\s+')).first;
    return n.isEmpty ? tr('¡Feliz santo! 🎉', 'Happy name day! 🎉') : tr('¡Feliz santo, {}! 🎉', 'Happy name day, {}! 🎉').replaceFirst('{}', n);
  }

  /// Aviso a las 10:00 del día de su santo.
  /// El aviso del santo lo programa Michi junto a sus demás mensajes
  /// (Notifier.reschedule → MichiEvents.nameDay). Aquí solo se reprograma
  /// para que el cambio se note enseguida.
  Future<void> scheduleSanto() async {
    await Notifier.instance.cancelOnce(_notifId);
    await Notifier.instance.reschedule();
  }

  static String _norm(String s) {
    const a = 'áàâäãéèêëíìîïóòôöõúùûüñç';
    const b = 'aaaaaeeeeiiiiooooouuuunc';
    final out = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = a.indexOf(ch);
      out.write(i >= 0 ? b[i] : ch);
    }
    return out.toString().trim();
  }

  /// Santo según el nombre (santoral católico más común en España).
  static (int, int)? santoForName(String name) {
    final n = _norm(name);
    if (n.isEmpty) return null;
    final full = _names[n];
    if (full != null) return full;
    final first = n.split(RegExp(r'\s+')).first;
    return _names[first];
  }

  static const Map<String, (int, int)> _names = {
    // Mujeres
    'agata': (2, 5), 'agueda': (2, 5), 'agnes': (1, 21), 'ines': (1, 21), 'adriana': (9, 8),
    'alba': (8, 15), 'alejandra': (3, 20), 'alicia': (6, 23), 'amparo': (5, 11), 'ana': (7, 26),
    'andrea': (11, 30), 'angela': (1, 27), 'angeles': (8, 2), 'antonia': (6, 13), 'araceli': (5, 2),
    'asuncion': (8, 15), 'aurora': (6, 19), 'barbara': (12, 4), 'beatriz': (7, 29), 'begona': (10, 11),
    'belen': (12, 25), 'blanca': (8, 5), 'carla': (11, 4), 'carlota': (11, 4), 'carmen': (7, 16),
    'carolina': (11, 4), 'catalina': (11, 25), 'cecilia': (11, 22), 'celia': (10, 21), 'clara': (8, 11),
    'concepcion': (12, 8), 'conchi': (12, 8), 'concha': (12, 8), 'consuelo': (8, 31), 'cristina': (7, 24),
    'diana': (6, 10), 'dolores': (9, 15), 'lola': (9, 15), 'elena': (8, 18), 'helena': (8, 18),
    'elisa': (12, 2), 'elisabet': (11, 17), 'emilia': (8, 24), 'encarnacion': (3, 25), 'encarna': (3, 25),
    'esperanza': (12, 18), 'esther': (7, 1), 'ester': (7, 1), 'eugenia': (12, 25), 'eva': (12, 24),
    'fatima': (5, 13), 'gema': (5, 14), 'gemma': (4, 11), 'gloria': (3, 25), 'guadalupe': (12, 12),
    'irene': (10, 20), 'isabel': (11, 17), 'jessica': (11, 4), 'josefa': (3, 19), 'pepa': (3, 19),
    'juana': (5, 30), 'judit': (5, 5), 'julia': (5, 22), 'laura': (10, 19), 'leticia': (8, 18),
    'lidia': (8, 3), 'lourdes': (2, 11), 'lucia': (12, 13), 'luisa': (3, 15), 'macarena': (5, 31),
    'magdalena': (7, 22), 'manuela': (1, 1), 'margarita': (11, 16), 'maria': (9, 12), 'mari': (9, 12),
    'marina': (7, 18), 'marisa': (9, 12), 'marta': (7, 29), 'martina': (1, 30), 'mercedes': (9, 24),
    'milagros': (7, 9), 'miriam': (8, 15), 'monica': (8, 27), 'montserrat': (4, 27), 'montse': (4, 27),
    'natalia': (7, 27), 'nerea': (5, 12), 'nieves': (8, 5), 'noelia': (12, 25), 'noemi': (12, 25),
    'nuria': (9, 8), 'olga': (7, 11), 'patricia': (8, 25), 'paula': (1, 26), 'paloma': (8, 15),
    'pilar': (10, 12), 'raquel': (9, 2), 'rebeca': (3, 23), 'remedios': (2, 3), 'rocio': (5, 24),
    'rosa': (8, 23), 'rosario': (10, 7), 'sandra': (8, 28), 'sara': (10, 9), 'silvia': (11, 3),
    'sofia': (9, 30), 'sonia': (9, 18), 'soledad': (10, 11), 'susana': (8, 11), 'teresa': (10, 15),
    'tere': (10, 15), 'trinidad': (6, 15), 'valeria': (4, 28), 'vanesa': (10, 15), 'veronica': (7, 12),
    'victoria': (12, 23), 'virginia': (12, 21), 'yolanda': (12, 17), 'ainhoa': (8, 15), 'aitana': (8, 15),
    'daniela': (12, 11), 'gabriela': (9, 29), 'claudia': (3, 20), 'lorena': (5, 30), 'marisol': (9, 12),
    'mar': (9, 15), 'estrella': (8, 15), 'cristiana': (12, 15), 'rut': (9, 1), 'ruth': (9, 1),
    'anna': (7, 26), 'marie': (8, 15), 'maria jose': (3, 19), 'mari carmen': (7, 16), 'maria del carmen': (7, 16),
    'maria jesus': (12, 25), 'maria luisa': (3, 15), 'maria pilar': (10, 12), 'maria angeles': (8, 2),
    // Hombres (por si la usa un chico o para "Mi pareja")
    'jose': (3, 19), 'juan': (6, 24), 'antonio': (6, 13), 'manuel': (1, 1), 'francisco': (10, 4),
    'david': (12, 29), 'javier': (12, 3), 'daniel': (12, 11), 'carlos': (11, 4), 'jesus': (12, 25),
    'alejandro': (2, 26), 'miguel': (9, 29), 'rafael': (9, 29), 'pedro': (6, 29), 'pablo': (6, 29),
    'angel': (10, 2), 'luis': (8, 25), 'sergio': (9, 8), 'fernando': (5, 30), 'jorge': (4, 23),
    'alberto': (11, 15), 'diego': (11, 13), 'adrian': (9, 8), 'raul': (6, 21), 'ivan': (6, 24),
    'ruben': (8, 4), 'oscar': (2, 3), 'andres': (11, 30), 'joaquin': (7, 26), 'santiago': (7, 25),
    'mario': (1, 19), 'eduardo': (10, 13), 'roberto': (6, 7), 'victor': (7, 28), 'jaime': (7, 25),
    'ignacio': (7, 31), 'alvaro': (2, 19), 'enrique': (7, 13), 'ramon': (8, 31), 'vicente': (1, 22),
    'marcos': (4, 25), 'lucas': (10, 18), 'mateo': (9, 21), 'martin': (11, 11), 'hugo': (4, 1),
    'nicolas': (12, 6), 'tomas': (7, 3), 'gabriel': (9, 29), 'samuel': (8, 20), 'cristian': (12, 15),
  };
}

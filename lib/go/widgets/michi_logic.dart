import 'package:shared_preferences/shared_preferences.dart';

import '../../services/settings_service.dart';
import '../data/store.dart';
import '../strings.dart';

/// Lógica compartida de Michi: racha con escudo, cómo se siente él según
/// cómo te sientes tú y tu fase del ciclo, y frases de ánimo.
class MichiLogic {
  MichiLogic._();

  static bool logged(DateTime d) {
    final l = AppStore.instance.logs[dayKey(d)];
    return l != null && !l.isEmpty;
  }

  static DayLog? todayLog() {
    final l = AppStore.instance.logs[dayKey(dateOnly(DateTime.now()))];
    return (l == null || l.isEmpty) ? null : l;
  }

  /// Racha con escudo: un día olvidado por semana no rompe la racha
  /// (el día perdonado no suma). Devuelve (días, escudo usado en los últimos 7).
  static ({int days, bool shieldRecent}) streakInfo() {
    final today = dateOnly(DateTime.now());
    var d = today;
    if (!logged(d)) d = addDays(d, -1);
    var n = 0;
    var sinceShield = 999; // días contados desde el último escudo
    var shieldRecent = false;
    var guard = 0;
    while (guard++ < 4000) {
      if (logged(d)) {
        n++;
        sinceShield++;
        d = addDays(d, -1);
        continue;
      }
      // Hueco de un solo día, con registro antes, y sin escudo en 7 días.
      if (n > 0 && sinceShield >= 7 && logged(addDays(d, -1))) {
        if (today.difference(d).inDays <= 7) shieldRecent = true;
        sinceShield = 0;
        d = addDays(d, -1);
        continue;
      }
      break;
    }
    return (days: n, shieldRecent: shieldRecent);
  }

  static int get streak => streakInfo().days;

  /// Hoy has vuelto tras 2+ días sin registrar (y ya lo usabas antes).
  static bool get returnedToday {
    final t = dateOnly(DateTime.now());
    if (!logged(t)) return false;
    if (logged(addDays(t, -1)) || logged(addDays(t, -2))) return false;
    return AppStore.instance.logs.values.where((l) => !l.isEmpty).length > 1;
  }

  /// La racha se ha roto: ni hoy ni ayer ni anteayer (el escudo no llega).
  static bool get missingYou {
    final t = dateOnly(DateTime.now());
    if (logged(t) || logged(addDays(t, -1)) || logged(addDays(t, -2))) return false;
    return AppStore.instance.logs.values.any((l) => !l.isEmpty);
  }

  static bool get _pms {
    final t = dateOnly(DateTime.now());
    final info = AppStore.instance.infoFor(t);
    if (info.phase != Phase.luteal) return false;
    for (final s in AppStore.instance.predictedStarts(2)) {
      final diff = dateOnly(s).difference(t).inDays;
      if (diff >= 0 && diff <= 5) return true;
    }
    return false;
  }

  /// Índice del ánimo de hoy 1..5 (Bien, Cansada, Con dolor, Tranquila, Motivada), 0 si nada.
  static int get todayMood {
    final l = todayLog();
    if (l == null) return 0;
    if (l.mood >= 1 && l.mood <= 5) return l.mood;
    if (l.pain >= 2) return 3;
    return 0;
  }

  /// 'period' | 'fertile' | 'pms' | null
  static String? get phaseKey {
    final st = AppStore.instance;
    if (st.goal == 'pregnancy' && st.pregnancyWeek != null) return null; // embarazada: sin fases
    final info = AppStore.instance.infoFor(dateOnly(DateTime.now()));
    if (info.period || info.predictedPeriod) return 'period';
    if (info.fertile || info.ovulation) return 'fertile';
    if (_pms) return 'pms';
    return null;
  }

  static const _moodImg = ['michi_happy', 'michi_tired', 'michi_pain', 'michi_calm', 'michi_motivated'];

  /// Postura de Michi cuando está tranquilo (sin animaciones especiales).
  /// [fedToday]: ya registraste hoy.
  static String pose({required bool fedToday}) {
    if (isBirthday) return 'michi_party';
    if (fedToday && returnedToday) return 'michi_return';
    final m = fedToday ? todayMood : 0;
    if (m > 0) return _moodImg[m - 1];
    switch (phaseKey) {
      case 'period':
        return 'michi_period';
      case 'fertile':
        return 'michi_flowers';
      case 'pms':
        return 'michi_snack';
    }
    final o = AppStore.instance.michiOutfit;
    if (o.isNotEmpty) return o;
    final s = streak;
    if (s >= 30) return 'michi_crown';
    if (s >= 3) return 'michi_collar';
    final now = DateTime.now();
    if (now.month == 12 || now.month <= 2) return 'michi_scarf';
    return now.day.isOdd ? 'michi_flower' : 'cat_wave';
  }

  static String sleepPose() => streak >= 7 ? 'michi_bed' : 'cat_house';

  /// Frase de ánimo que refleja cómo estás tú hoy (o null).
  static String? cheer({required bool fedToday}) {
    if (isBirthday) return birthdayText();
    if (fedToday && returnedToday) return tr('¡Has vuelto! ¡Qué alegría! 🥹', "You're back! I'm so happy! 🥹");
    final m = fedToday ? todayMood : 0;
    switch (m) {
      case 1:
        return tr('¡Qué bien verte feliz! Hoy brillas ✨', "So happy to see you happy! You're shining today ✨");
      case 2:
        return tr('Yo también tengo sueño… Descansa un poquito, te lo mereces 💤', "I'm sleepy too… Rest a little, you deserve it 💤");
      case 3:
        return tr('Estoy contigo. Descansa, eres más fuerte de lo que crees 💗', "I'm with you. Rest, you're stronger than you think 💗");
      case 4:
        return tr('Respiremos juntas… qué paz 🌸', "Let's breathe together… so peaceful 🌸");
      case 5:
        return tr('¡A por todas! Hoy nadie nos para 💪', 'Go for it! Nothing can stop us today 💪');
    }
    switch (phaseKey) {
      case 'period':
        return tr('Mantita, agua calentita y mimos. Yo te cuido 🩷', "Blanket, a warm bottle and cuddles. I'll look after you 🩷");
      case 'fertile':
        return tr('Hoy todo florece, ¡como tú! 🌷', 'Everything is blooming today, just like you! 🌷');
      case 'pms':
        return tr('Si te apetece algo dulce, ¡te acompaño! 🍪', "If you fancy something sweet, I'll join you! 🍪");
    }
    return null;
  }

  static String letter() => tr('Te he escrito una carta: te echo de menos. ¿Vuelves? 💌', 'I wrote you a letter: I miss you. Will you come back? 💌');
  static String shieldText() => tr('Escudo usado: tu racha sigue a salvo 🛡️', 'Shield used: your streak is safe 🛡️');

  /// Todas las paradas de los dos mundos (día de racha, premio, postal).
  static final stops = <MichiStop>[
    MichiStop(3, 1, 'prize_collar', '🎀', 'post_garden', () => tr('Jardín de flores', 'Flower garden')),
    MichiStop(7, 1, 'prize_bed', '🛏️', 'post_bridge', () => tr('Puente del río', 'River bridge')),
    MichiStop(14, 1, 'prize_yarn', '🧶', 'post_hill', () => tr('Colina de los globos', 'Balloon hill')),
    MichiStop(30, 1, 'prize_crown', '👑', 'post_castle', () => tr('Castillo en las nubes', 'Castle in the clouds')),
    MichiStop(35, 2, 'prize_shell', '🐚', 'post_beach', () => tr('Playa de caracolas', 'Seashell beach')),
    MichiStop(42, 2, 'prize_lolly', '🍭', 'post_candy', () => tr('Bosque de caramelos', 'Candy forest')),
    MichiStop(50, 2, 'prize_star', '⭐', 'post_lake', () => tr('Lago de las estrellas', 'Starry lake')),
    MichiStop(60, 2, 'prize_moon', '🌙', 'post_moon', () => tr('Palacio de la luna', 'Moon palace')),
  ];

  static const _postKey = 'michi_postcards';

  /// Postales conseguidas (se guardan para siempre, aunque se rompa la racha).
  static Future<Set<int>> postcards() async {
    final p = await SharedPreferences.getInstance();
    final got = (p.getStringList(_postKey) ?? const []).map(int.tryParse).whereType<int>().toSet();
    final s = streak;
    final add = stops.where((x) => x.day <= s && !got.contains(x.day)).map((x) => x.day).toList();
    if (add.isNotEmpty) {
      got.addAll(add);
      await p.setStringList(_postKey, got.map((e) => '$e').toList());
    }
    return got;
  }

  // ---------------- Cumpleaños ----------------
  static DateTime? _birth;
  static bool _birthLoaded = false;

  static Future<void> loadBirthday() async {
    if (_birthLoaded) return;
    _birthLoaded = true;
    try {
      _birth = await SettingsService().loadProfileBirthDate();
    } catch (_) {}
  }

  static bool get isBirthday {
    final b = _birth;
    if (b == null) return false;
    final n = DateTime.now();
    return b.month == n.month && b.day == n.day;
  }

  static String birthdayTitle() => tr('¡Feliz cumpleaños! 🎂', 'Happy birthday! 🎂');
  static String birthdayText() => tr('Michi te ha preparado una tarta. ¡Que tengas un día precioso!', 'Michi baked you a cake. Have a wonderful day!');

  /// Historia corta de cada parada del mapa.
  static String story(int day) {
    switch (day) {
      case 35:
        return tr('Michi jugó en la playa rosa y encontró una caracola que canta.', 'Michi played on the pink beach and found a singing seashell.');
      case 42:
        return tr('Michi se perdió en el bosque de caramelos y ganó una piruleta gigante.', 'Michi wandered the candy forest and won a giant lollipop.');
      case 50:
        return tr('Michi navegó por el lago y atrapó una estrella fugaz.', 'Michi sailed across the lake and caught a shooting star.');
      case 60:
        return tr('¡Michi llegó al palacio de la luna y la luna le regaló su brillo! 🌙', 'Michi reached the moon palace and the moon gave him its glow! 🌙');
      case 3:
        return tr('Michi olió todas las flores del jardín y encontró un collar precioso.', 'Michi smelled every flower in the garden and found a lovely collar.');
      case 7:
        return tr('Michi cruzó el puente saludando a los peces y descubrió una camita blandita.', 'Michi crossed the bridge waving at the fish and found a soft little bed.');
      case 14:
        return tr('Michi subió la colina persiguiendo globos y ganó un ovillo mágico.', 'Michi climbed the hill chasing balloons and won a magic ball of yarn.');
      default:
        return tr('¡Michi llegó al castillo de las nubes y lo coronaron rey! 👑', 'Michi reached the castle in the clouds and was crowned king! 👑');
    }
  }
}

class MichiStop {
  final int day;
  final int world;
  final String prize;
  final String emoji;
  final String postcard;
  final String Function() name;
  const MichiStop(this.day, this.world, this.prize, this.emoji, this.postcard, this.name);
}

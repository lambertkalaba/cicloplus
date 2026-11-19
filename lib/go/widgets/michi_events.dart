import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/store.dart';
import '../screens/michi_stories.dart' show StoryParticles, StoryFx;
import '../strings.dart';
import '../services/traditions.dart';
import '../screens/traditions.dart' show TraditionsScreen;
import '../screens/michi_more.dart' show MichiCounters;
import 'michi_sound.dart';
import 'ui.dart';

/// Un momento especial de Michi hoy (fiesta, santo, aniversario…).
class MichiEvent {
  const MichiEvent(this.emoji, this.text, this.fx, {this.pose = 'michi_party'});
  final String emoji;
  final String text;
  final StoryFx fx;
  final String pose;
}

enum MichiSeason { spring, summer, autumn, winter, tropical }

/// Michi sabe qué día es: estaciones, fiestas del país de la usuaria,
/// su santo (si lo quiere), aniversarios y cuándo le vienen bien unas flores.
class MichiEvents {
  MichiEvents._();

  // ───────────────────────── País ─────────────────────────

  /// Países que se pueden elegir (código, nombre en su idioma).
  static const countries = <(String, String)>[
    ('ES', 'España'), ('MX', 'México'), ('AR', 'Argentina'), ('CO', 'Colombia'), ('CL', 'Chile'), ('PE', 'Perú'),
    ('VE', 'Venezuela'), ('EC', 'Ecuador'), ('BO', 'Bolivia'), ('UY', 'Uruguay'), ('PY', 'Paraguay'), ('CR', 'Costa Rica'),
    ('PA', 'Panamá'), ('DO', 'República Dominicana'), ('GT', 'Guatemala'), ('HN', 'Honduras'), ('SV', 'El Salvador'),
    ('NI', 'Nicaragua'), ('CU', 'Cuba'), ('PR', 'Puerto Rico'), ('US', 'United States'), ('CA', 'Canada'),
    ('GB', 'United Kingdom'), ('IE', 'Ireland'), ('AU', 'Australia'), ('NZ', 'New Zealand'), ('FR', 'France'),
    ('BE', 'Belgique / België'), ('CH', 'Schweiz / Suisse'), ('DE', 'Deutschland'), ('AT', 'Österreich'), ('IT', 'Italia'),
    ('PT', 'Portugal'), ('BR', 'Brasil'), ('NL', 'Nederland'), ('PL', 'Polska'), ('RO', 'România'), ('HU', 'Magyarország'),
    ('CZ', 'Česko'), ('SK', 'Slovensko'), ('GR', 'Ελλάδα'), ('SE', 'Sverige'), ('DK', 'Danmark'), ('FI', 'Suomi'),
    ('NO', 'Norge'), ('RU', 'Россия'), ('UA', 'Україна'), ('TR', 'Türkiye'), ('IN', 'भारत / India'), ('PK', 'پاکستان'),
    ('BD', 'বাংলাদেশ'), ('NP', 'नेपाल'), ('LK', 'ශ්‍රී ලංකාව'), ('CN', '中国'), ('TW', '臺灣'), ('HK', '香港'), ('JP', '日本'),
    ('KR', '대한민국'), ('VN', 'Việt Nam'), ('TH', 'ประเทศไทย'), ('MY', 'Malaysia'), ('SG', 'Singapore'), ('ID', 'Indonesia'),
    ('PH', 'Pilipinas'), ('MM', 'မြန်မာ'), ('SA', 'السعودية'), ('AE', 'الإمارات'), ('EG', 'مصر'), ('MA', 'المغرب'),
    ('DZ', 'الجزائر'), ('IR', 'ایران'), ('IL', 'ישראל'), ('AZ', 'Azərbaycan'), ('KZ', 'Қазақстан'), ('UZ', 'Oʻzbekiston'),
    ('NG', 'Nigeria'), ('GH', 'Ghana'), ('KE', 'Kenya'), ('TZ', 'Tanzania'), ('ZA', 'South Africa'), ('ET', 'ኢትዮጵያ'),
    ('CD', 'RD Congo'), ('SN', 'Sénégal'), ('CI', "Côte d'Ivoire"), ('CM', 'Cameroun'),
  ];

  static String flag(String code) => code.length != 2
      ? '🌍'
      : String.fromCharCodes(code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 65));

  /// País elegido en Configuración; si no, el país de la tienda donde
  /// descargó la app (Google Play / App Store); si no, el del teléfono.
  static String get country {
    final c = AppStore.instance.michiCountry;
    if (c.isNotEmpty) return c;
    if (_store != null && _store!.isNotEmpty) return _store!;
    final dev = WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    return (dev ?? '').toUpperCase();
  }

  static String? _store;
  static bool _storeLoading = false;

  /// Lee el país de la tienda (se guarda para usarlo sin esperar).
  static Future<void> loadStoreCountry() async {
    final p = await SharedPreferences.getInstance();
    _store ??= p.getString('michi_store_country');
    if (_storeLoading) return;
    _storeLoading = true;
    try {
      final sf = await Purchases.storefront;
      final code = _toAlpha2(sf?.countryCode ?? '');
      if (code.isNotEmpty) {
        _store = code;
        await p.setString('michi_store_country', code);
      }
    } catch (_) {
      // Sin tienda (emulador, sin conexión…): se usa el país del teléfono.
    }
  }

  /// App Store da el país en 3 letras (FRA); Google Play en 2 (FR).
  static String _toAlpha2(String c) {
    final u = c.trim().toUpperCase();
    if (u.length == 2) return u;
    return _alpha3[u] ?? '';
  }

  static const _alpha3 = {
    'ESP': 'ES', 'MEX': 'MX', 'ARG': 'AR', 'COL': 'CO', 'CHL': 'CL', 'PER': 'PE', 'VEN': 'VE', 'ECU': 'EC', 'BOL': 'BO',
    'URY': 'UY', 'PRY': 'PY', 'CRI': 'CR', 'PAN': 'PA', 'DOM': 'DO', 'GTM': 'GT', 'HND': 'HN', 'SLV': 'SV', 'NIC': 'NI',
    'CUB': 'CU', 'PRI': 'PR', 'USA': 'US', 'CAN': 'CA', 'GBR': 'GB', 'IRL': 'IE', 'AUS': 'AU', 'NZL': 'NZ', 'FRA': 'FR',
    'BEL': 'BE', 'CHE': 'CH', 'DEU': 'DE', 'AUT': 'AT', 'ITA': 'IT', 'PRT': 'PT', 'BRA': 'BR', 'NLD': 'NL', 'POL': 'PL',
    'ROU': 'RO', 'HUN': 'HU', 'CZE': 'CZ', 'SVK': 'SK', 'GRC': 'GR', 'SWE': 'SE', 'DNK': 'DK', 'FIN': 'FI', 'NOR': 'NO',
    'RUS': 'RU', 'UKR': 'UA', 'TUR': 'TR', 'IND': 'IN', 'PAK': 'PK', 'BGD': 'BD', 'NPL': 'NP', 'LKA': 'LK', 'CHN': 'CN',
    'TWN': 'TW', 'HKG': 'HK', 'JPN': 'JP', 'KOR': 'KR', 'VNM': 'VN', 'THA': 'TH', 'MYS': 'MY', 'SGP': 'SG', 'IDN': 'ID',
    'PHL': 'PH', 'MMR': 'MM', 'SAU': 'SA', 'ARE': 'AE', 'EGY': 'EG', 'MAR': 'MA', 'DZA': 'DZ', 'IRN': 'IR', 'ISR': 'IL',
    'AZE': 'AZ', 'KAZ': 'KZ', 'UZB': 'UZ', 'NGA': 'NG', 'GHA': 'GH', 'KEN': 'KE', 'TZA': 'TZ', 'ZAF': 'ZA', 'ETH': 'ET',
    'COD': 'CD', 'SEN': 'SN', 'CIV': 'CI', 'CMR': 'CM',
  };

  static const _south = {'AR', 'CL', 'UY', 'PY', 'AU', 'NZ', 'ZA', 'BR', 'BO'};
  static const _tropical = {
    'CO', 'VE', 'EC', 'PE', 'CR', 'PA', 'DO', 'GT', 'HN', 'SV', 'NI', 'CU', 'PR', 'IN', 'BD', 'LK', 'TH', 'MY', 'SG', 'ID',
    'PH', 'MM', 'NG', 'GH', 'KE', 'TZ', 'ET', 'CD', 'SN', 'CI', 'CM', 'AE', 'SA',
  };
  static const _muslim = {'SA', 'AE', 'EG', 'MA', 'DZ', 'ID', 'MY', 'PK', 'BD', 'TR', 'IR', 'AZ', 'KZ', 'UZ', 'SN'};
  static const _orthodox = {'RU', 'GR', 'RO', 'UA', 'ET'};

  // ───────────────────────── Estación ─────────────────────────

  static MichiSeason get season {
    final c = country;
    if (_tropical.contains(c)) return MichiSeason.tropical;
    var m = DateTime.now().month;
    if (_south.contains(c)) m = (m + 5) % 12 + 1;
    if (m == 12 || m <= 2) return MichiSeason.winter;
    if (m <= 5) return MichiSeason.spring;
    if (m <= 8) return MichiSeason.summer;
    return MichiSeason.autumn;
  }

  /// Emojis que flotan alrededor de Michi según la estación.
  static StoryFx get seasonFx => switch (season) {
        MichiSeason.spring => StoryFx.petals,
        MichiSeason.summer => StoryFx.sun,
        MichiSeason.autumn => StoryFx.leaves,
        MichiSeason.winter => StoryFx.snow,
        MichiSeason.tropical => StoryFx.tropical,
      };

  static String get seasonEmoji => switch (season) {
        MichiSeason.spring => '🌸',
        MichiSeason.summer => '☀️',
        MichiSeason.autumn => '🍂',
        MichiSeason.winter => '❄️',
        MichiSeason.tropical => '🌺',
      };

  /// Frase de la estación (cambia cada día).
  static String seasonPhrase() {
    final i = DateTime.now().difference(DateTime(2026)).inDays % 3;
    switch (season) {
      case MichiSeason.spring:
        return [
          tr('¡Ya es primavera! Todo florece, igual que tú 🌸', "It's spring! Everything is blooming, just like you 🌸"),
          tr('Huele a flores… ¿salimos a dar un paseo? 🌷', 'It smells of flowers… shall we go for a walk? 🌷'),
          tr('Los días son más largos: más ratitos para cuidarte ☀️', 'The days are longer: more little moments to look after yourself ☀️'),
        ][i];
      case MichiSeason.summer:
        return [
          tr('¡Verano! No olvides el agua y la crema solar 🧴', "Summer! Don't forget water and sunscreen 🧴"),
          tr('Hace calor… yo me tumbo a la sombra, ¿y tú? 🍉', "It's hot… I'm lying in the shade, what about you? 🍉"),
          tr('Noches de verano: perfectas para mirar las estrellas ✨', 'Summer nights: perfect for stargazing ✨'),
        ][i];
      case MichiSeason.autumn:
        return [
          tr('Llegó el otoño: mantita, té calentito y tú 🍂', 'Autumn is here: a blanket, warm tea and you 🍂'),
          tr('Me encanta saltar sobre las hojas secas 🍁', 'I love jumping on the dry leaves 🍁'),
          tr('Días más cortos: acuéstate pronto y descansa 🌙', 'Shorter days: go to bed early and rest 🌙'),
        ][i];
      case MichiSeason.winter:
        return [
          tr('¡Qué frío! Abrígate bien, yo ya tengo mi bufanda 🧣', "So cold! Wrap up warm, I've already got my scarf 🧣"),
          tr('Invierno = chocolate caliente y mimos ☕', 'Winter = hot chocolate and cuddles ☕'),
          tr('Si nieva, ¿hacemos un muñeco de nieve? ⛄', 'If it snows, shall we build a snowman? ⛄'),
        ][i];
      case MichiSeason.tropical:
        return [
          tr('¡Qué día tan bonito! Bebe mucha agua 💧', 'What a lovely day! Drink plenty of water 💧'),
          tr('Sol, flores y tú: el plan perfecto 🌺', 'Sun, flowers and you: the perfect plan 🌺'),
          tr('Si llueve, nos quedamos en casa escuchando la lluvia 🌧️', "If it rains, we'll stay home and listen to the rain 🌧️"),
        ][i];
    }
  }

  // ───────────────────────── Fiestas ─────────────────────────

  static DateTime _easter(int y) {
    final a = y % 19, b = y ~/ 100, c = y % 100, d = b ~/ 4, e = b % 4, f = (b + 8) ~/ 25, g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30, i = c ~/ 4, k = c % 4, l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31, day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(y, month, day);
  }

  static DateTime _orthodoxEaster(int y) {
    final a = y % 4, b = y % 7, c = y % 19, d = (19 * c + 15) % 30, e = (2 * a + 4 * b - d + 34) % 7;
    final month = (d + e + 114) ~/ 31, day = ((d + e + 114) % 31) + 1;
    return DateTime(y, month, day).add(const Duration(days: 13));
  }

  /// n-ésimo día de la semana del mes (weekday: 1 = lunes … 7 = domingo).
  static DateTime _nth(int y, int month, int weekday, int n) {
    var d = DateTime(y, month, 1);
    while (d.weekday != weekday) {
      d = d.add(const Duration(days: 1));
    }
    return d.add(Duration(days: 7 * (n - 1)));
  }

  static bool _isDay(DateTime d, DateTime t) => d.year == t.year && d.month == t.month && d.day == t.day;
  static bool _md(DateTime t, int m, int d) => t.month == m && t.day == d;
  static bool _inTable(DateTime t, List<String> dates) => dates.contains(dayKey(t));

  static const _lunarNY = ['2026-02-17', '2027-02-06', '2028-01-26', '2029-02-13', '2030-02-03'];
  static const _midAutumn = ['2026-09-25', '2027-09-15', '2028-10-03', '2029-09-22', '2030-09-12'];
  static const _diwali = ['2026-11-08', '2027-10-29', '2028-10-17', '2029-11-05', '2030-10-26'];
  static const _holi = ['2027-03-22', '2028-03-11', '2029-03-01', '2030-03-20'];
  static const _ramadan = ['2027-02-08', '2028-01-28', '2029-01-16', '2030-01-06'];
  static const _eidFitr = ['2027-03-10', '2028-02-27', '2029-02-15', '2030-02-05'];
  static const _eidAdha = ['2026-05-27', '2027-05-17', '2028-05-05', '2029-04-24', '2030-04-13'];

  /// Días nacionales (mes, día).
  static const _national = <String, List<(int, int)>>{
    'ES': [(10, 12)], 'MX': [(9, 16)], 'AR': [(5, 25), (7, 9)], 'CO': [(7, 20)], 'CL': [(9, 18)], 'PE': [(7, 28)],
    'VE': [(7, 5)], 'EC': [(8, 10)], 'BO': [(8, 6)], 'UY': [(8, 25)], 'PY': [(5, 15)], 'CR': [(9, 15)], 'PA': [(11, 3)],
    'DO': [(2, 27)], 'GT': [(9, 15)], 'HN': [(9, 15)], 'SV': [(9, 15)], 'NI': [(9, 15)], 'US': [(7, 4)], 'CA': [(7, 1)],
    'FR': [(7, 14)], 'BE': [(7, 21)], 'CH': [(8, 1)], 'DE': [(10, 3)], 'AT': [(10, 26)], 'IT': [(6, 2)], 'PT': [(6, 10)],
    'BR': [(9, 7)], 'NL': [(4, 27)], 'PL': [(11, 11)], 'RO': [(12, 1)], 'HU': [(8, 20)], 'CZ': [(10, 28)], 'GR': [(3, 25)],
    'SE': [(6, 6)], 'NO': [(5, 17)], 'FI': [(12, 6)], 'UA': [(8, 24)], 'TR': [(10, 29)], 'IN': [(1, 26), (8, 15)],
    'PK': [(8, 14)], 'BD': [(3, 26)], 'LK': [(2, 4)], 'CN': [(10, 1)], 'TW': [(10, 10)], 'KR': [(8, 15)], 'VN': [(9, 2)],
    'MY': [(8, 31)], 'SG': [(8, 9)], 'ID': [(8, 17)], 'PH': [(6, 12)], 'SA': [(9, 23)], 'AE': [(12, 2)], 'IL': [(5, 14)],
    'AZ': [(5, 28)], 'KZ': [(12, 16)], 'UZ': [(9, 1)], 'NG': [(10, 1)], 'GH': [(3, 6)], 'KE': [(12, 12)], 'TZ': [(12, 9)],
    'ZA': [(4, 27)], 'CD': [(6, 30)], 'SN': [(4, 4)], 'CI': [(8, 7)], 'CM': [(5, 20)], 'IE': [(3, 17)], 'NZ': [(2, 6)],
  };

  static MichiEvent? holiday([DateTime? at]) {
    final n = at ?? DateTime.now();
    final t = DateTime(n.year, n.month, n.day);
    final c = country;
    final y = t.year;
    final tdn = Traditions.instance..ensureLoaded();
    final muslim = tdn.chosen == null || tdn.chosen == 'none' ? _muslim.contains(c) : tdn.muslim;
    final ev = <MichiEvent?>[
      if (_md(t, 1, 1)) MichiEvent('🎆', tr('¡Feliz Año Nuevo! Que este año te trate con mucho cariño 🎆', 'Happy New Year! May this year treat you with lots of love 🎆'), StoryFx.sparkles),
      if (_md(t, 12, 31)) MichiEvent('✨', tr('¡Última noche del año! Gracias por este año a tu lado ✨', 'Last night of the year! Thank you for this year by your side ✨'), StoryFx.sparkles),
      if (_md(t, 3, 8)) MichiEvent('💜', tr('¡Feliz Día de la Mujer! Hoy y siempre, eres increíble 💜', "Happy Women's Day! Today and always, you're amazing 💜"), StoryFx.hearts),
      if (_md(t, 2, 14) && c != 'BR' && c != 'SA' && c != 'IR') MichiEvent('💘', tr('¡Feliz San Valentín! Te mando todo mi amor gatuno 💘', "Happy Valentine's Day! Sending you all my kitty love 💘"), StoryFx.hearts),
      if (_md(t, 10, 31) && !muslim) MichiEvent('🎃', tr('¡Feliz Halloween! Me he disfrazado de calabaza, ¿te gusto? 🎃', 'Happy Halloween! I dressed up as a pumpkin, do you like it? 🎃'), StoryFx.candy),
      if (_md(t, 12, 25) && !muslim && c != 'RU' && c != 'ET' || (_md(t, 1, 7) && (c == 'RU' || c == 'ET')))
        MichiEvent('🎄', tr('¡Feliz Navidad! Gracias por ser mi persona favorita 🎄', 'Merry Christmas! Thank you for being my favourite person 🎄'), StoryFx.stars, pose: 'michi_scarf'),
      if (!muslim && !_orthodox.contains(c) && !{'CN', 'JP', 'TH', 'IN', 'NP', 'VN', 'TW', 'LK', 'MM'}.contains(c) && _isDay(_easter(y), t) ||
          _orthodox.contains(c) && _isDay(_orthodoxEaster(y), t))
        MichiEvent('🐣', tr('¡Feliz Pascua! Te he escondido un huevito de chocolate 🐣', 'Happy Easter! I hid a little chocolate egg for you 🐣'), StoryFx.petals),
      if ({'BR', 'BO', 'UY', 'PA', 'PT'}.contains(c) && t.difference(_easter(y)).inDays >= -50 && t.difference(_easter(y)).inDays <= -47 && t.isBefore(_easter(y)))
        MichiEvent('🎭', tr('¡Es Carnaval! ¿Bailamos? Yo ya tengo mi antifaz 🎭', "It's Carnival! Shall we dance? I've got my mask on 🎭"), StoryFx.candy),
      if (_md(t, 1, 6) && {'ES', 'MX', 'PR', 'DO', 'UY', 'AR', 'VE', 'PY'}.contains(c))
        MichiEvent('👑', tr('¡Han venido los Reyes Magos! Les pedí que te trajeran mucha alegría 👑', 'The Three Kings are here! I asked them to bring you lots of joy 👑'), StoryFx.stars),
      if (_md(t, 1, 6) && c == 'IT') MichiEvent('🧹', tr('¡Ha llegado la Befana! Para ti, solo dulces 🍬', 'The Befana has arrived! Only sweets for you 🍬'), StoryFx.candy),
      if (_md(t, 6, 23) && c == 'ES') MichiEvent('🔥', tr('¡Noche de San Juan! Pide un deseo: yo pido que seas muy feliz 🔥', "St John's Night! Make a wish: I wish for you to be very happy 🔥"), StoryFx.sparkles),
      if (_md(t, 6, 24) && c == 'BR') MichiEvent('🌽', tr('¡Viva São João! Ya tengo mi sombrero de paja para la fiesta junina 🌽', "Viva São João! I've got my straw hat for the June festival 🌽"), StoryFx.sparkles),
      if (_md(t, 6, 13) && c == 'PT') MichiEvent('🌿', tr('¡Feliz Santo Antonio! Fiesta, música y albahaca 🌿', "Happy St Anthony's Day! Party, music and basil 🌿"), StoryFx.petals),
      if (_md(t, 6, 12) && c == 'BR') MichiEvent('💘', tr('¡Feliz Día de los Enamorados! Te quiero mucho 💘', "Happy Lovers' Day! I love you so much 💘"), StoryFx.hearts),
      if (_md(t, 10, 12) && c == 'BR') MichiEvent('🧸', tr('¡Feliz Día de los Niños! Hoy jugamos como niños 🧸', "Happy Children's Day! Today we play like kids 🧸"), StoryFx.balloons),
      if ((_md(t, 11, 1) || _md(t, 11, 2)) && c == 'MX') MichiEvent('🌼', tr('Día de Muertos: hoy recordamos con cariño a quienes amamos 🌼', 'Day of the Dead: today we lovingly remember those we love 🌼'), StoryFx.petals, pose: 'michi_flowers'),
      if (_md(t, 7, 20) && {'AR', 'UY'}.contains(c)) MichiEvent('🤝', tr('¡Feliz Día del Amigo! Tú eres mi mejor amiga 🤝', "Happy Friendship Day! You're my best friend 🤝"), StoryFx.hearts),
      if (c == 'CO' && _isDay(_nth(y, 9, 6, 3), t)) MichiEvent('💛', tr('¡Feliz Día del Amor y la Amistad! 💛', 'Happy Love and Friendship Day! 💛'), StoryFx.hearts),
      if (c == 'US' && _isDay(_nth(y, 11, 4, 4), t) || c == 'CA' && _isDay(_nth(y, 10, 1, 2), t))
        MichiEvent('🦃', tr('¡Feliz Día de Acción de Gracias! Yo doy gracias por tenerte 🦃', "Happy Thanksgiving! I'm thankful to have you 🦃"), StoryFx.petals),
      if (_md(t, 11, 5) && c == 'GB') MichiEvent('🎇', tr('¡Noche de las hogueras! Fuegos artificiales para ti 🎇', 'Bonfire Night! Fireworks just for you 🎇'), StoryFx.sparkles),
      if (_md(t, 12, 6) && {'DE', 'AT', 'CH', 'NL', 'BE', 'PL', 'CZ', 'SK', 'HU'}.contains(c) || _md(t, 12, 5) && c == 'NL')
        MichiEvent('🎅', tr('¡Feliz San Nicolás! Mira en tus botas: te he dejado algo dulce 🍫', "Happy St Nicholas' Day! Look in your boots: I left you something sweet 🍫"), StoryFx.stars),
      if (_md(t, 8, 15) && c == 'IT') MichiEvent('☀️', tr('¡Feliz Ferragosto! Día de playa y helado 🍦', 'Happy Ferragosto! A day for the beach and ice cream 🍦'), StoryFx.sparkles),
      if (_md(t, 3, 17) && {'IE', 'US', 'GB'}.contains(c)) MichiEvent('☘️', tr('¡Feliz San Patricio! Hoy todo es verde ☘️', "Happy St Patrick's Day! Everything is green today ☘️"), StoryFx.petals),
      if (_md(t, 3, 3) && c == 'JP') MichiEvent('🎎', tr('¡Feliz Hinamatsuri! Hoy es el día de las niñas 🎎', "Happy Hinamatsuri! Today is Girls' Day 🎎"), StoryFx.petals),
      if (_md(t, 7, 7) && c == 'JP') MichiEvent('🎋', tr('¡Feliz Tanabata! He colgado tu deseo en el bambú 🎋', 'Happy Tanabata! I hung your wish on the bamboo 🎋'), StoryFx.stars),
      if (_md(t, 4, 13) && c == 'TH') MichiEvent('💦', tr('¡Feliz Songkran! ¡Guerra de agua! 💦', 'Happy Songkran! Water fight! 💦'), StoryFx.bubbles),
      if (_md(t, 3, 21) && {'IR', 'AZ', 'KZ', 'UZ'}.contains(c)) MichiEvent('🌱', tr('¡Feliz Nouruz! Feliz año nuevo y feliz primavera 🌱', 'Happy Nowruz! Happy new year and happy spring 🌱'), StoryFx.petals),
      if (_inTable(t, _lunarNY) && {'CN', 'TW', 'HK', 'SG', 'VN', 'KR', 'MY'}.contains(c))
        MichiEvent('🧧', tr('¡Feliz Año Nuevo Lunar! Te deseo suerte y alegría 🧧', 'Happy Lunar New Year! I wish you luck and joy 🧧'), StoryFx.sparkles),
      if (_inTable(t, _midAutumn) && {'CN', 'TW', 'HK', 'SG', 'VN', 'KR'}.contains(c))
        MichiEvent('🥮', tr('¡Feliz fiesta de la luna llena de otoño! Miremos juntos la luna 🥮', "Happy mid-autumn full moon festival! Let's look at the moon together 🥮"), StoryFx.stars),
      if (_inTable(t, _diwali) && {'IN', 'NP', 'SG', 'MY', 'LK'}.contains(c)) MichiEvent('🪔', tr('¡Feliz Diwali! Que la luz llene tu casa 🪔', 'Happy Diwali! May light fill your home 🪔'), StoryFx.sparkles),
      if (_inTable(t, _holi) && {'IN', 'NP'}.contains(c)) MichiEvent('🎨', tr('¡Feliz Holi! Me he llenado de colores 🎨', "Happy Holi! I'm covered in colours 🎨"), StoryFx.candy),
      if (_inTable(t, _ramadan) && muslim) MichiEvent('🌙', tr('¡Ramadán Mubarak! Que este mes te traiga paz 🌙', 'Ramadan Mubarak! May this month bring you peace 🌙'), StoryFx.stars),
      if ((_inTable(t, _eidFitr) || _inTable(t, _eidAdha)) && muslim) MichiEvent('🌙', tr('¡Eid Mubarak! Feliz fiesta 🌙✨', 'Eid Mubarak! Happy celebrations 🌙✨'), StoryFx.sparkles),
      if ((_national[c] ?? const []).any((x) => _md(t, x.$1, x.$2)))
        MichiEvent(flag(c), tr('¡Feliz día de tu país! Hoy lo celebramos juntos 🎉', "Happy national day! Let's celebrate together today 🎉"), StoryFx.balloons),
    ];
    for (final e in ev) {
      if (e != null) return e;
    }
    return null;
  }

  // ───────────────────────── Santo ─────────────────────────

  /// Onomásticas (santoral católico) de los nombres más comunes y sus variantes.
  static const _saints = <String, (int, int)>{
    'maria': (8, 15), 'mary': (8, 15), 'marie': (8, 15), 'mari': (8, 15), 'mariana': (7, 26), 'marina': (7, 20),
    'ana': (7, 26), 'anna': (7, 26), 'anne': (7, 26), 'ane': (7, 26), 'anita': (7, 26), 'annie': (7, 26), 'hanna': (7, 26),
    'carmen': (7, 16), 'dolores': (9, 15), 'lola': (9, 15), 'pilar': (10, 12), 'rosario': (10, 7), 'mercedes': (9, 24),
    'concepcion': (12, 8), 'inmaculada': (12, 8), 'immacolata': (12, 8), 'conchi': (12, 8), 'pura': (12, 8),
    'guadalupe': (12, 12), 'lupe': (12, 12), 'fatima': (5, 13), 'lourdes': (2, 11), 'montserrat': (4, 27), 'montse': (4, 27),
    'begona': (10, 11), 'covadonga': (9, 8), 'macarena': (12, 18), 'esperanza': (12, 18), 'rocio': (6, 9), 'soledad': (10, 11),
    'paz': (1, 24), 'luz': (6, 1), 'nieves': (8, 5), 'asuncion': (8, 15), 'consuelo': (9, 4), 'remedios': (9, 1),
    'milagros': (7, 9), 'angeles': (8, 2), 'aurora': (8, 13), 'paloma': (5, 26),
    'isabel': (11, 17), 'elisabeth': (11, 17), 'elizabeth': (11, 17), 'elisabetta': (11, 17), 'isabella': (11, 17), 'elisa': (11, 17), 'eliza': (11, 17), 'beth': (11, 17),
    'teresa': (10, 15), 'tereza': (10, 15), 'therese': (10, 1), 'laura': (10, 19), 'lucia': (12, 13), 'lucy': (12, 13), 'luzia': (12, 13),
    'cristina': (7, 24), 'christina': (7, 24), 'kristina': (7, 24), 'cristiane': (7, 24), 'marta': (7, 29), 'martha': (7, 29), 'marthe': (7, 29),
    'sara': (10, 9), 'sarah': (10, 9), 'raquel': (9, 2), 'rachel': (9, 2), 'rebeca': (3, 23), 'rebecca': (3, 23),
    'clara': (8, 11), 'claire': (8, 11), 'chiara': (8, 11), 'klara': (8, 11), 'julia': (5, 22), 'giulia': (5, 22), 'julie': (5, 22),
    'catalina': (4, 29), 'catarina': (4, 29), 'caterina': (4, 29), 'katherine': (4, 29), 'catherine': (4, 29), 'katarzyna': (11, 25), 'kate': (4, 29),
    'margarita': (11, 16), 'margaret': (11, 16), 'margherita': (2, 22), 'marguerite': (11, 16), 'magdalena': (7, 22), 'madalena': (7, 22), 'madeleine': (7, 22),
    'monica': (8, 27), 'monika': (8, 27), 'rosa': (8, 23), 'rose': (8, 23), 'rita': (5, 22), 'silvia': (11, 3), 'sylvia': (11, 3),
    'veronica': (7, 9), 'patricia': (3, 17), 'beatriz': (7, 29), 'beatrice': (7, 29), 'irene': (10, 20), 'cecilia': (11, 22),
    'agnes': (1, 21), 'ines': (1, 21), 'agata': (2, 5), 'agueda': (2, 5), 'barbara': (12, 4), 'susana': (8, 11), 'susanne': (8, 11),
    'eva': (12, 24), 'elena': (8, 18), 'helena': (8, 18), 'helen': (8, 18), 'olga': (7, 11), 'natalia': (7, 27), 'natalie': (7, 27),
    'victoria': (11, 17), 'vitoria': (11, 17), 'paula': (1, 26), 'paola': (1, 26), 'pauline': (1, 26), 'alicia': (6, 28),
    'andrea': (11, 30), 'josefa': (3, 19), 'josefina': (3, 19), 'josephine': (3, 19), 'giuseppina': (3, 19), 'pepa': (3, 19),
    'juana': (5, 30), 'joana': (5, 30), 'jeanne': (5, 30), 'giovanna': (5, 30), 'joanna': (5, 30), 'joan': (5, 30),
    'francisca': (3, 9), 'francesca': (3, 9), 'francoise': (3, 9), 'antonia': (6, 13), 'antonella': (6, 13),
    'carolina': (11, 4), 'caroline': (11, 4), 'carla': (11, 4), 'luisa': (3, 15), 'louise': (3, 15), 'eugenia': (12, 25),
    'emilia': (5, 30), 'amelia': (1, 5), 'sofia': (9, 18), 'sophia': (9, 18), 'sophie': (9, 18), 'zofia': (5, 15),
    'valentina': (7, 25), 'daniela': (12, 11), 'gabriela': (9, 29), 'gabrielle': (9, 29), 'raphaela': (9, 29), 'rafaela': (9, 29),
    'angela': (1, 27), 'angelica': (1, 27), 'camila': (7, 14), 'camilla': (7, 14), 'julieta': (7, 30), 'juliana': (6, 19),
    'adriana': (9, 8), 'alejandra': (3, 20), 'alexandra': (3, 20), 'sandra': (3, 20), 'marisa': (8, 15), 'maite': (8, 15),
    'noelia': (12, 25), 'noemi': (12, 25), 'nuria': (9, 8), 'ainhoa': (8, 15), 'irina': (5, 5), 'yolanda': (12, 17),
    'jose': (3, 19), 'joseph': (3, 19), 'giuseppe': (3, 19), 'juan': (6, 24), 'joao': (6, 24), 'jean': (6, 24), 'john': (6, 24),
    'giovanni': (6, 24), 'pedro': (6, 29), 'pierre': (6, 29), 'peter': (6, 29), 'pietro': (6, 29), 'pablo': (6, 29), 'paulo': (6, 29), 'paul': (6, 29),
    'antonio': (6, 13), 'anthony': (6, 13), 'antoine': (6, 13), 'francisco': (10, 4), 'francesco': (10, 4), 'francois': (10, 4), 'francis': (10, 4),
    'manuel': (1, 1), 'jesus': (1, 1), 'miguel': (9, 29), 'michael': (9, 29), 'michel': (9, 29), 'michele': (9, 29),
    'carlos': (11, 4), 'charles': (11, 4), 'carlo': (11, 4), 'luis': (8, 25), 'louis': (8, 25), 'luigi': (6, 21),
    'javier': (12, 3), 'xavier': (12, 3), 'david': (12, 29), 'daniel': (12, 11), 'alejandro': (2, 26), 'andres': (11, 30),
    'andrew': (11, 30), 'andre': (11, 30), 'jorge': (4, 23), 'george': (4, 23), 'giorgio': (4, 23), 'martin': (11, 11),
    'tomas': (7, 3), 'thomas': (7, 3), 'santiago': (7, 25), 'jaime': (7, 25), 'diego': (11, 13), 'marcos': (4, 25), 'mark': (4, 25),
    'lucas': (10, 18), 'luke': (10, 18), 'mateo': (9, 21), 'matthew': (9, 21), 'rafael': (9, 29), 'gabriel': (9, 29),
    'fernando': (5, 30), 'ignacio': (7, 31), 'alberto': (11, 15), 'roberto': (6, 7), 'ricardo': (4, 3), 'sergio': (9, 25),
    'vicente': (1, 22), 'ramon': (8, 31), 'enrique': (7, 13), 'felipe': (5, 3), 'nicolas': (12, 6), 'nicholas': (12, 6),
    'esteban': (12, 26), 'stephen': (12, 26), 'cristobal': (7, 10), 'agustin': (8, 28), 'sebastian': (1, 20), 'adrian': (9, 8),
    'alvaro': (2, 19), 'joaquin': (7, 26), 'benito': (7, 11), 'benedetto': (7, 11), 'domingo': (8, 8), 'bernardo': (8, 20),
    'jan': (6, 24), 'piotr': (6, 29), 'pawel': (6, 29), 'krzysztof': (7, 25), 'tomasz': (7, 3), 'stanislaw': (5, 8),
  };

  static String _norm(String s) {
    const from = 'áàâäãåéèêëíìîïóòôöõúùûüñçøæœšśźżłčřž';
    const to = 'aaaaaaeeeeiiiiooooouuuuncoaoszzzlcrz';
    final b = StringBuffer();
    for (final ch in s.toLowerCase().runes.map(String.fromCharCode)) {
      final i = from.indexOf(ch);
      b.write(i >= 0 ? to[i] : ch);
    }
    return b.toString();
  }

  static String get firstName {
    final n = AppStore.instance.name.trim();
    if (n.isEmpty) return '';
    return n.split(RegExp(r'\s+')).first;
  }

  /// Santo de un nombre según el santoral de Michi (varios idiomas).
  static (int, int)? saintFor(String name) => _saints[_norm(name.trim().split(RegExp(r'\s+')).first)];

  static MichiEvent? nameDay([DateTime? at]) {
    final t = at ?? DateTime.now();
    // Un solo interruptor: Yo > Tradiciones > Cristiana.
    if (!Traditions.instance.isSantoDay(t)) return null;
    final n = firstName;
    final text = n.isEmpty
        ? tr('¡Feliz santo! 🎉', 'Happy name day! 🎉')
        : tr('¡Feliz santo, {}! Hoy es tu día y Michi lo sabe 😇', "Happy name day, {}! Today is your day and Michi knows it 😇").replaceFirst('{}', n);
    return MichiEvent('😇', text, StoryFx.sparkles);
  }

  /// ¿Tenemos su santo en el calendario? (para explicarlo en Configuración)
  static bool get knowsNameDay => _saints.containsKey(_norm(firstName));

  // ───────────────────────── Aniversario ─────────────────────────

  static DateTime? get _firstDay {
    DateTime? first;
    for (final e in AppStore.instance.logs.entries) {
      if (e.value.isEmpty) continue;
      final d = DateTime.tryParse(e.key);
      if (d != null && (first == null || d.isBefore(first))) first = d;
    }
    return first;
  }

  static MichiEvent? anniversary([DateTime? at]) {
    final f = _firstDay;
    if (f == null) return null;
    final t = at ?? DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final days = today.difference(DateTime(f.year, f.month, f.day)).inDays;
    if (days <= 0) return null;
    if (f.month == t.month && f.day == t.day) {
      final years = t.year - f.year;
      if (years == 1) {
        return MichiEvent('🎂', tr('¡Hoy hace un año que nos conocemos! Gracias por quedarte 🎂', "It's been a year since we met! Thank you for staying 🎂"), StoryFx.balloons);
      }
      return MichiEvent('🎂', tr('¡Hoy hace {} años que nos conocemos! 🎂', "It's been {} years since we met! 🎂").replaceFirst('{}', '$years'), StoryFx.balloons);
    }
    if (days == 100 || days == 200 || days == 500) {
      return MichiEvent('🎉', tr('¡Hoy hace {} días que nos conocemos! 🎉', "It's been {} days since we met! 🎉").replaceFirst('{}', '$days'), StoryFx.balloons);
    }
    return null;
  }

  /// El momento especial de hoy, por orden de importancia.
  static MichiEvent? today() => nameDay() ?? anniversary() ?? periodStart() ?? holiday();

  /// Primer día de la regla: Michi llega con la bolsa de agua caliente.
  static MichiEvent? periodStart() {
    final t = dateOnly(DateTime.now());
    final l = AppStore.instance.logs[dayKey(t)];
    final y = AppStore.instance.logs[dayKey(addDays(t, -1))];
    if (l == null || l.flow <= 0 || (y != null && y.flow > 0)) return null;
    return MichiEvent('🫖', tr('Te traigo una bolsa de agua caliente y una mantita. Hoy, con calma 🩷', 'I brought you a hot water bottle and a blanket. Take it easy today 🩷'),
        StoryFx.hearts, pose: 'michi_period');
  }

  // ───────────────────────── Flores ─────────────────────────

  static const _flowersKey = 'michi_flowers_day';

  /// ¿Le ha traído flores hoy? (si está triste, cansada o con dolor, o
  /// de vez en cuando porque sí). Se abre una vez al día.
  static Future<bool> hasFlowers() async {
    if (_flowerReason() == 0) return false;
    final p = await SharedPreferences.getInstance();
    return p.getString(_flowersKey) != dayKey(DateTime.now());
  }

  static Future<void> markFlowers() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_flowersKey, dayKey(DateTime.now()));
  }

  /// 0 = nada, 1 = para animarte, 2 = porque sí.
  static int _flowerReason() {
    final l = AppStore.instance.logs[dayKey(DateTime.now())];
    if (l != null && !l.isEmpty && (l.mood == 2 || l.mood == 3 || l.pain >= 2)) return 1;
    final n = DateTime.now();
    final seed = n.year * 400 + n.month * 32 + n.day;
    if (math.Random(seed).nextInt(7) == 0) return 2;
    return 0;
  }

  static String flowersMessage() {
    final i = DateTime.now().day % 3;
    if (_flowerReason() == 1) {
      return [
        tr('Te he visto un poco triste y te he traído flores. Todo pasa, y yo estoy aquí 💐', "I saw you were a bit sad, so I brought you flowers. Everything passes, and I'm here 💐"),
        tr('Para ti, para que hoy pese un poquito menos. Te quiero mucho 🌷', 'For you, so that today feels a little lighter. I love you so much 🌷'),
        tr('Unas flores y un ronroneo: tu kit de días difíciles 🌸', 'Some flowers and a purr: your kit for difficult days 🌸'),
      ][i];
    }
    return [
      tr('¡Sorpresa! Flores porque sí, porque te lo mereces 💐', 'Surprise! Flowers just because, because you deserve them 💐'),
      tr('He pasado por el jardín y me he acordado de ti 🌼', 'I went by the garden and thought of you 🌼'),
      tr('Un ramito para alegrarte el día 🌷', 'A little bouquet to brighten your day 🌷'),
    ][i];
  }
}

/// Ramo de flores de Michi que se abre con pétalos cayendo.
Future<void> showMichiFlowers(BuildContext context) async {
  HapticFeedback.mediumImpact();
  await MichiEvents.markFlowers();
  MichiSound.chime();
  MichiCounters.add('flowers');
  if (!context.mounted) return;
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (_, __, ___) => const _FlowersCard(),
    transitionBuilder: (_, a, __, child) => ScaleTransition(
      scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: a, child: child),
    ),
  );
}

class _FlowersCard extends StatefulWidget {
  const _FlowersCard();

  @override
  State<_FlowersCard> createState() => _FlowersCardState();
}

class _FlowersCardState extends State<_FlowersCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 320,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
            Container(
              margin: const EdgeInsets.only(top: 90),
              padding: const EdgeInsets.fromLTRB(22, 64, 22, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [C.t(0xFFFFF4F8), C.t(0xFFFFE1EC)]),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: C.pinkLine, width: 2),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(tr('Michi te ha traído flores', 'Michi brought you flowers'),
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: C.pinkDark)),
                const SizedBox(height: 10),
                Text(MichiEvents.flowersMessage(),
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 15.5, height: 1.4, fontWeight: FontWeight.w700, color: C.text)),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: C.pink, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12)),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(tr('¡Gracias, Michi! 💗', 'Thank you, Michi! 💗'), style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ]),
            ),
            // Michi entra con el ramo.
            AnimatedBuilder(
              animation: _c,
              builder: (_, __) {
                final t = Curves.elasticOut.transform(_c.value.clamp(0.0, 1.0));
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - t)),
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * t,
                    child: SizedBox(
                      width: 170,
                      height: 150,
                      child: Stack(clipBehavior: Clip.none, children: [
                        const Positioned(left: 10, bottom: 0, child: Img('michi_flowers', size: 140, fallback: Icons.pets_rounded)),
                        Positioned(
                          right: 0,
                          top: 20,
                          child: Transform.rotate(angle: -0.3 + 0.3 * t, child: const Text('💐', style: TextStyle(fontSize: 54))),
                        ),
                      ]),
                    ),
                  ),
                );
              },
            ),
            const Positioned.fill(child: IgnorePointer(child: StoryParticles(fx: StoryFx.petals, count: 16))),
          ]),
        ),
      ),
    );
  }
}

/// Ajustes de Michi (se usa en las dos pantallas de Configuración).
class MichiSettings extends StatelessWidget {
  const MichiSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final auto = s.michiCountry.isEmpty;
        final shown = auto ? MichiEvents.country : s.michiCountry;
        final name = MichiEvents.countries.where((x) => x.$1 == shown).map((x) => x.$2).firstOrNull ?? shown;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Text('🐱', style: TextStyle(fontSize: 24)),
            title: Text(tr('Mostrar a Michi', 'Show Michi'), style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(tr('Tu gatito en la pantalla de inicio. Si lo ocultas, no pierdes nada: te espera para cuando vuelvas.',
                'Your kitten on the home screen. If you hide him, you lose nothing: he will wait for you to come back.')),
            value: s.showMichi,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF2FB45A),
            onChanged: (v) {
              s.showMichi = v;
              s.commit();
            },
          ),
          if (!s.showMichi)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Text('🌸', style: TextStyle(fontSize: 22)),
              title: Text(tr('Mostrar el jardín en su lugar', 'Show the garden instead'), style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(tr('La flor que crece cada día que entras. Si lo desactivas, no aparece nada.',
                  'The flower that grows every day you open the app. If you turn it off, nothing is shown.')),
              value: s.showGarden,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF2FB45A),
              onChanged: (v) {
                s.showGarden = v;
                s.commit();
              },
            ),
          if (s.showMichi) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Text('🔊', style: TextStyle(fontSize: 22)),
              title: Text(tr('Sonidos de Michi', "Michi's sounds"), style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(tr('Ronroneo al acariciarlo y maullidos suaves. Respetan el modo silencio.',
                  'Purring when you pet him and soft meows. They respect silent mode.')),
              value: s.michiSounds,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF2FB45A),
              onChanged: (v) {
                s.michiSounds = v;
                s.commit();
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Text('🗣️', style: TextStyle(fontSize: 22)),
              title: Text(tr('Voz de Michi', "Michi's voice"), style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(tr('Michi te habla y te cuenta los chistes en voz alta cuando lo tocas.',
                  'Michi talks to you and tells jokes out loud when you tap him.')),
              value: s.michiVoice,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF2FB45A),
              onChanged: (v) {
                s.michiVoice = v;
                s.commit();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(s.michiScene == 'map' ? '☁️' : '🏠', style: const TextStyle(fontSize: 22)),
              title: Text(tr('Dónde vive Michi', 'Where Michi lives'), style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(s.michiScene == 'map' ? tr('Mundo de las nubes', 'Cloud world') : tr('Su casa', 'His house')),
              trailing: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'house', label: Text('🏠')),
                  ButtonSegment(value: 'map', label: Text('☁️')),
                ],
                selected: {s.michiScene == 'map' ? 'map' : 'house'},
                onSelectionChanged: (v) {
                  s.michiScene = v.first;
                  s.commit();
                },
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Text('✨', style: TextStyle(fontSize: 22)),
              title: Text(tr('Tradiciones', 'Traditions'), style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(tr('Fechas especiales, solo si quieres', 'Special dates, only if you want')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TraditionsScreen())),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(MichiEvents.flag(shown), style: const TextStyle(fontSize: 22)),
              title: Text(tr('Fiestas de tu país', "Your country's celebrations"), style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(auto ? '${tr('Automático', 'Automatic')} · $name' : name),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _pickCountry(context),
            ),
          ],
        ]);
      },
    );
  }

  Future<void> _pickCountry(BuildContext context) async {
    final s = AppStore.instance;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: ListView(children: [
          ListTile(
            leading: const Text('🌍', style: TextStyle(fontSize: 22)),
            title: Text(tr('Automático', 'Automatic'), style: const TextStyle(fontWeight: FontWeight.w800)),
            trailing: s.michiCountry.isEmpty ? Icon(Icons.check_rounded, color: C.pink) : null,
            onTap: () => Navigator.of(context).pop(''),
          ),
          for (final c in MichiEvents.countries)
            ListTile(
              leading: Text(MichiEvents.flag(c.$1), style: const TextStyle(fontSize: 22)),
              title: Text(c.$2),
              trailing: s.michiCountry == c.$1 ? Icon(Icons.check_rounded, color: C.pink) : null,
              onTap: () => Navigator.of(context).pop(c.$1),
            ),
        ]),
      ),
    );
    if (picked == null) return;
    s.michiCountry = picked;
    await s.commit();
  }
}

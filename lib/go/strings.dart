import 'dart:ui' as ui;

import 'data/store.dart';
import 'go_i18n.dart';

/// Textos: español, inglés y el resto de idiomas de CicloPlus (go_i18n.dart).
class L {
  static bool es = true;

  /// Idioma elegido en CicloPlus (es, en, fr, de, ru, ar, hi, bn, pt).
  static String lang = 'es';

  static void setLang(String code) {
    lang = code;
    es = code == 'es';
  }

  static void init() {
    setLang(ui.PlatformDispatcher.instance.locale.languageCode == 'en' ? 'en' : 'es');
  }

  static const _months = {
    'es': ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'],
    'en': ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
    'fr': ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'],
    'de': ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'],
    'pt': ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'],
    'ru': ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'],
    'ar': ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'],
    'hi': ['जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'],
    'bn': ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'],
  };

  static const _weekdays = {
    'es': ['L', 'M', 'X', 'J', 'V', 'S', 'D'],
    'en': ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    'fr': ['L', 'M', 'M', 'J', 'V', 'S', 'D'],
    'de': ['M', 'D', 'M', 'D', 'F', 'S', 'S'],
    'pt': ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'],
    'ru': ['П', 'В', 'С', 'Ч', 'П', 'С', 'В'],
    'ar': ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'],
    'hi': ['सो', 'मं', 'बु', 'गु', 'शु', 'श', 'र'],
    'bn': ['সো', 'ম', 'বু', 'বৃ', 'শু', 'শ', 'র'],
  };

  static List<String> get _m => _months[lang] ?? _months['en']!;

  static String month(int m) => _m[m - 1];
  static String monthShort(int m) {
    final n = month(m);
    return n.length <= 4 ? n : n.substring(0, 3);
  }

  static List<String> get weekdaysShort => _weekdays[lang] ?? _weekdays['en']!;

  static String dateLong(DateTime d) {
    if (lang == 'es') return '${d.day} de ${month(d.month).toLowerCase()} de ${d.year}';
    if (lang == 'en') return '${month(d.month)} ${d.day}, ${d.year}';
    if (lang == 'de') return '${d.day}. ${month(d.month)} ${d.year}';
    return '${d.day} ${month(d.month).toLowerCase()} ${d.year}';
  }

  static String dateShort(DateTime d) => lang == 'en' ? '${monthShort(d.month)} ${d.day}' : '${d.day} ${monthShort(d.month)}';
}

/// Devuelve el texto en el idioma elegido. Español e inglés vienen en el
/// propio código; el resto se busca en goI18n (si falta, sale en inglés).
String tr(String es, String en) {
  if (L.lang == 'es') return es;
  if (L.lang == 'en') return en;
  return goI18n[L.lang]?[es] ?? en;
}

/// Síntomas fijos (los de la imagen) con su icono.
const symptomKeys = ['dolor', 'animo', 'energia', 'antojos', 'hinchazon', 'sueno', 'acne', 'cabeza'];

String symptomName(String k) {
  switch (k) {
    case 'dolor':
      return tr('Dolor', 'Pain');
    case 'animo':
      return tr('Ánimo', 'Mood');
    case 'energia':
      return tr('Energía', 'Energy');
    case 'antojos':
      return tr('Antojos', 'Cravings');
    case 'hinchazon':
      return tr('Hinchazón', 'Bloating');
    case 'sueno':
      return tr('Sueño', 'Sleepy');
    case 'acne':
      return tr('Acné', 'Acne');
    case 'cabeza':
      return tr('Cabeza', 'Headache');
  }
  return k;
}

String? symptomAsset(String k) => symptomKeys.contains(k) ? 's_$k' : null;

List<String> get flowNames => [tr('Ninguno', 'None'), tr('Ligero', 'Light'), tr('Medio', 'Medium'), tr('Abundante', 'Heavy')];
List<String> get painNames => [tr('Sin dolor', 'No pain'), tr('Leve', 'Mild'), tr('Moderada', 'Moderate'), tr('Intensa', 'Severe')];
List<String> get painAdj => ['', tr('leve', 'mild'), tr('moderado', 'moderate'), tr('intenso', 'severe')];
/// Estados de ánimo (valor guardado = índice + 1).
List<String> get moodNames => [tr('Bien', 'Good'), tr('Cansada', 'Tired'), tr('Con dolor', 'In pain'), tr('Tranquila', 'Calm'), tr('Motivada', 'Motivated')];
const moodImgs = ['m4', 'm2', 'm1', 'm3', 'm5'];
const moodEmojis = ['😊', '😴', '😣', '😌', '😍'];

/// Puntuación de energía y de ánimo (1-5) de cada estado.
const moodEnergy = [4, 1, 2, 3, 5];
const moodScore = [4, 2, 1, 4, 5];
List<String> get sexNames => [tr('Nada', 'None'), tr('Con protección', 'Protected'), tr('Sin protección', 'Unprotected')];

String goalName(String g) {
  switch (g) {
    case 'conceive':
      return tr('Intento concebir', 'Trying to conceive');
    case 'pregnancy':
      return tr('Seguir mi embarazo', 'Track my pregnancy');
  }
  return tr('Seguir mi período', 'Track my period');
}

String phaseName(Phase p) {
  switch (p) {
    case Phase.period:
      return tr('Menstruación', 'Period');
    case Phase.follicular:
      return tr('Fase folicular', 'Follicular phase');
    case Phase.fertile:
      return tr('Fase fértil estimada', 'Estimated fertile window');
    case Phase.ovulation:
      return tr('Ovulación estimada', 'Estimated ovulation');
    case Phase.luteal:
      return tr('Fase lútea', 'Luteal phase');
  }
}

String phaseTip(Phase? p) {
  switch (p) {
    case Phase.period:
      return tr('Descansa, hidrátate y date algún capricho. Un poco de calor en la tripa ayuda con el dolor.',
          'Rest, hydrate and treat yourself. A little warmth on your belly helps with cramps.');
    case Phase.follicular:
      return tr('Tu energía va subiendo: buen momento para empezar proyectos y hacer ejercicio.',
          'Your energy is rising: a great time to start projects and work out.');
    case Phase.fertile:
    case Phase.ovulation:
      return tr('Estás en tus días más fértiles. Puedes sentirte con más energía y buen ánimo.',
          'You are in your most fertile days. You may feel more energetic and upbeat.');
    case Phase.luteal:
      return tr('Puede que notes antojos o cansancio. Duerme bien y cuida lo que comes.',
          'You may notice cravings or tiredness. Sleep well and eat mindfully.');
    case null:
      return tr('Registra tu periodo para ver consejos según tu fase.', 'Log your period to see tips for your phase.');
  }
}

String greeting(String name) {
  final h = DateTime.now().hour;
  final base = h < 12
      ? tr('Buenos días', 'Good morning')
      : h < 20
          ? tr('Buenas tardes', 'Good afternoon')
          : tr('Buenas noches', 'Good evening');
  return name.isEmpty ? base : '$base, $name';
}

String daysWord(int n) => n == 1 ? tr('día', 'day') : tr('días', 'days');

String fmtNum(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

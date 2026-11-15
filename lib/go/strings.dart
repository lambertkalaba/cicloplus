import 'dart:ui' as ui;

import 'data/store.dart';

/// Textos: español por defecto, inglés si el teléfono no está en español.
class L {
  static bool es = true;

  static void init() {
    es = ui.PlatformDispatcher.instance.locale.languageCode != 'en';
  }

  static const _monthsEs = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];
  static const _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static String month(int m) => (es ? _monthsEs : _monthsEn)[m - 1];
  static String monthShort(int m) => month(m).substring(0, 3);
  static List<String> get weekdaysShort => es ? ['L', 'M', 'X', 'J', 'V', 'S', 'D'] : ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  static String dateLong(DateTime d) => es ? '${d.day} de ${month(d.month).toLowerCase()} de ${d.year}' : '${month(d.month)} ${d.day}, ${d.year}';
  static String dateShort(DateTime d) => es ? '${d.day} ${monthShort(d.month)}' : '${monthShort(d.month)} ${d.day}';
}

String tr(String es, String en) => L.es ? es : en;

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

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Ids de cada categoría que puede mostrarse/ocultarse en el calendario
/// desde el panel "Leyenda" (ver `CalendarScreen._showLegendSheet`). Se usan
/// como claves estables tanto para persistir qué está activo
/// (`SettingsService.loadCalendarLegendVisible`) como para decidir, en
/// `CalendarGrid`, qué icono pintar o no en cada día — pensado para que la
/// usuaria pueda mostrar su calendario a alguien (pareja, médico) ocultando
/// de antemano las categorías que prefiere mantener privadas.
class CalendarLegendCategory {
  static const period = 'period';
  static const predicted = 'predicted';
  static const fertile = 'fertile';
  static const sexUnprotected = 'sex_unprotected';
  static const sexProtected = 'sex_protected';
  static const masturbation = 'masturbation';
  static const pill = 'pill';
  static const diu = 'diu';
  static const moodSymptoms = 'mood_symptoms';
  static const note = 'note';

  /// Todas las categorías, en el mismo orden en que se muestran en el
  /// panel — usado como fallback "todo visible" y para iterar al construir
  /// la UI de switches.
  static const all = <String>[
    period,
    predicted,
    fertile,
    sexUnprotected,
    sexProtected,
    masturbation,
    pill,
    diu,
    moodSymptoms,
    note,
  ];
}

/// Un tema de color del catálogo (igual a `THEMES` en el prototipo web).
class AppThemeOption {
  final String id;
  final String name;
  final int primary;
  final int primaryDark;
  final int primaryLight;
  final int background;

  const AppThemeOption({
    required this.id,
    required this.name,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.background,
  });
}

/// Catálogo de temas disponibles, con los mismos valores hex que el
/// prototipo (`THEMES` en CicloPlus_prototipo.html).
const List<AppThemeOption> kAppThemes = [
  AppThemeOption(
    id: 'pink',
    name: 'Rosa',
    primary: 0xFFD6336C,
    primaryDark: 0xFFA61E4D,
    primaryLight: 0xFFF8D7E3,
    background: 0xFFFFF5F7,
  ),
  AppThemeOption(
    id: 'purple',
    name: 'Violeta',
    primary: 0xFF7048E8,
    primaryDark: 0xFF4C2889,
    primaryLight: 0xFFE5DBFF,
    background: 0xFFF8F6FF,
  ),
  AppThemeOption(
    id: 'blue',
    name: 'Azul',
    primary: 0xFF1C7ED6,
    primaryDark: 0xFF0B4F8A,
    primaryLight: 0xFFD0EBFF,
    background: 0xFFF2F9FF,
  ),
  AppThemeOption(
    id: 'green',
    name: 'Verde',
    primary: 0xFF2F9E44,
    primaryDark: 0xFF1C6B2C,
    primaryLight: 0xFFD3F9D8,
    background: 0xFFF3FBF4,
  ),
  AppThemeOption(
    id: 'dark',
    name: 'Oscuro',
    primary: 0xFFE64980,
    primaryDark: 0xFF1A1A2E,
    primaryLight: 0xFF3A2740,
    background: 0xFF181622,
  ),
];

AppThemeOption themeById(String id) =>
    kAppThemes.firstWhere((t) => t.id == id, orElse: () => kAppThemes.first);

/// Una paleta completa de colores para las 4 categorías que se pintan en
/// el calendario (Periodo/Previsto/Fértil/Hoy) — independiente del "Color
/// de app" (`AppThemeOption`, que solo cambia el AppBar y los acentos del
/// resto de la app). Se creó porque con la paleta pastel original algunas
/// personas no lograban distinguir bien "Previsto" de "Fértil" en la
/// leyenda (colores de relleno muy claros, casi blancos, sobre el fondo
/// pastel de la pantalla) — en vez de forzar un único ajuste de color para
/// todo el mundo, se ofrecen varias paletas ya probadas para que cada
/// quien elija la que mejor pueda leer.
class CalendarPaletteOption {
  final String id;
  final String name;
  final int periodFill;
  final int predictedFill;
  final int predictedBorder;
  final int fertileFill;
  final int fertileBorder;
  final int todayRing;
  final int ovulationFill;

  const CalendarPaletteOption({
    required this.id,
    required this.name,
    required this.periodFill,
    required this.predictedFill,
    required this.predictedBorder,
    required this.fertileFill,
    required this.fertileBorder,
    required this.todayRing,
    required this.ovulationFill,
  });
}

/// Catálogo de paletas de calendario disponibles en Configuración >
/// "Colores del calendario". 'pastel' reproduce los valores originales de
/// `CalendarPhaseColors` (diseño v0 aprobado) para quien prefiera dejarlo
/// como estaba; las otras dos aumentan la saturación/contraste de
/// Previsto y Fértil, que eran los colores reportados como difíciles de
/// distinguir.
// Las 3 paletas usan deliberadamente la MISMA familia de 4 tonos (rojo =
// período, azul = previsto, AMARILLO/dorado = fértil, morado = ovulación),
// solo con distinta intensidad — así ninguna categoría se confunde con otra
// sin importar la paleta elegida.
//
// "Fértil" pasó primero de rosa a NARANJA (para separarlo del rojo de
// "Período" al pintar ese como cuadrado sólido), pero la usuaria reportó
// que seguía sin distinguirse bien: naranja está demasiado cerca de rojo en
// el círculo de color, y a tamaño pequeño (rayita de 1-2px en los estilos
// Elegante/iOS) la diferencia se pierde casi del todo. Se cambia aquí a un
// AMARILLO/dorado franco (muy lejos de rojo en tono), que es la opción con
// mayor distancia perceptual posible frente a rojo, azul Y morado a la vez.
const List<CalendarPaletteOption> kCalendarPalettes = [
  CalendarPaletteOption(
    id: 'pastel',
    name: 'Pastel (original)',
    periodFill: 0xFFEF5350,
    predictedFill: 0xFFE9F6FD,
    predictedBorder: 0xFF5CC0EC,
    fertileFill: 0xFFFFF8E1,
    fertileBorder: 0xFFF9A825,
    todayRing: 0xFF2F9E44,
    ovulationFill: 0xFF9B59B6,
  ),
  CalendarPaletteOption(
    id: 'vivid',
    name: 'Vivo',
    periodFill: 0xFFE53935,
    predictedFill: 0xFFAEE3F9,
    predictedBorder: 0xFF1C7ED6,
    fertileFill: 0xFFFFECB3,
    fertileBorder: 0xFFFF8F00,
    todayRing: 0xFF2F9E44,
    ovulationFill: 0xFF9B59B6,
  ),
  CalendarPaletteOption(
    id: 'highContrast',
    name: 'Alto contraste',
    periodFill: 0xFFB71C1C,
    predictedFill: 0xFF74C0FC,
    predictedBorder: 0xFF0B4F8A,
    fertileFill: 0xFFFFD54F,
    fertileBorder: 0xFFF57F17,
    todayRing: 0xFF2F9E44,
    ovulationFill: 0xFF5F3DC4,
  ),
  // ---- Paletas añadidas a petición de la usuaria ("no solo son 3
  // colores sino más") — se mantiene la MISMA familia de 4 tonos que las
  // 3 de arriba (rojo=período, azul=previsto, amarillo/dorado=fértil,
  // morado=ovulación) para no reintroducir el problema de distinguibilidad
  // que ya se corrigió; lo que cambia es la intensidad/temperatura de cada
  // una, para dar variedad real sin perder la lectura rápida del calendario.
  CalendarPaletteOption(
    id: 'suave',
    name: 'Suave',
    periodFill: 0xFFFFAB91,
    predictedFill: 0xFFE3F2FD,
    predictedBorder: 0xFF64B5F6,
    fertileFill: 0xFFFFF9C4,
    fertileBorder: 0xFFFFD54F,
    todayRing: 0xFF2F9E44,
    ovulationFill: 0xFFCE93D8,
  ),
  CalendarPaletteOption(
    id: 'calido',
    name: 'Cálido',
    periodFill: 0xFFD84315,
    predictedFill: 0xFFBBDEFB,
    predictedBorder: 0xFF1565C0,
    fertileFill: 0xFFFFE082,
    fertileBorder: 0xFFE65100,
    todayRing: 0xFF2F9E44,
    ovulationFill: 0xFF6A1B9A,
  ),
  CalendarPaletteOption(
    id: 'joya',
    name: 'Joya',
    periodFill: 0xFF8E0000,
    predictedFill: 0xFF64B5F6,
    predictedBorder: 0xFF0D47A1,
    fertileFill: 0xFFFFC107,
    fertileBorder: 0xFFBF360C,
    todayRing: 0xFF2F9E44,
    ovulationFill: 0xFF4A148C,
  ),
];

CalendarPaletteOption calendarPaletteById(String id) =>
    kCalendarPalettes.firstWhere((p) => p.id == id, orElse: () => kCalendarPalettes.first);

/// Una opción de apariencia para la ilustración de la tarjeta "Sincroniza
/// con tu pareja" en la pantalla Hoy — puramente decorativa/local, igual
/// de espíritu que las paletas del calendario de arriba.
class CoupleIllustrationOption {
  final String id;
  final String name;
  final String asset;

  const CoupleIllustrationOption({required this.id, required this.name, required this.asset});
}

const List<CoupleIllustrationOption> kCoupleIllustrations = [
  CoupleIllustrationOption(
    id: 'mixta',
    name: 'Ella clara, él oscuro',
    asset: 'assets/decorative/couple_illustration.png',
  ),
  CoupleIllustrationOption(
    id: 'mixta_inversa',
    name: 'Ella oscura, él claro',
    asset: 'assets/decorative/couple_illustration_negra_blanco.png',
  ),
  CoupleIllustrationOption(
    id: 'blanca',
    name: 'Ella clara, él claro',
    asset: 'assets/decorative/couple_illustration_white.png',
  ),
  CoupleIllustrationOption(
    id: 'negra',
    name: 'Ella oscura, él oscuro',
    asset: 'assets/decorative/couple_illustration_black.png',
  ),
  CoupleIllustrationOption(
    id: 'lesbica',
    name: 'Ella y ella',
    asset: 'assets/decorative/couple_illustration_lesbica.png',
  ),
];

CoupleIllustrationOption coupleIllustrationById(String id) =>
    kCoupleIllustrations.firstWhere((o) => o.id == id, orElse: () => kCoupleIllustrations.first);

/// Configuración simple de un recordatorio diario recurrente (diario o
/// pastilla), con hora en formato "HH:mm".
class DailyTimeReminderSettings {
  final bool enabled;
  final String time; // 'HH:mm'

  const DailyTimeReminderSettings({this.enabled = false, required this.time});

  DailyTimeReminderSettings copyWith({bool? enabled, String? time}) =>
      DailyTimeReminderSettings(
        enabled: enabled ?? this.enabled,
        time: time ?? this.time,
      );

  int get hour => int.parse(time.split(':')[0]);
  int get minute => int.parse(time.split(':')[1]);
}

/// Una cita médica programada por la usuaria (ginecólogo, Papanicolau,
/// mamografía, etc.), con fecha+hora exacta y una etiqueta de texto libre.
/// A diferencia de los recordatorios diarios recurrentes, cada cita es una
/// notificación única que se dispara una sola vez.
class MedicalAppointment {
  final String id; // usado como notification id determinístico
  final String label; // texto libre, ej. "Ginecólogo", "Papanicolau"
  final DateTime dateTime;

  const MedicalAppointment({required this.id, required this.label, required this.dateTime});

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'dateTime': dateTime.toIso8601String(),
      };

  factory MedicalAppointment.fromJson(Map<String, dynamic> json) => MedicalAppointment(
        id: json['id'] as String,
        label: json['label'] as String,
        dateTime: DateTime.parse(json['dateTime'] as String),
      );
}

/// Un registro de test de ovulación (tira de LH), con fecha y resultado.
/// [result] es texto simple ('negative' | 'positive' | 'peak') en vez de un
/// enum propio, siguiendo el mismo patrón liviano que `_userGoalKey`.
class OvulationTestEntry {
  final DateTime date;
  final String result; // 'negative' | 'positive' | 'peak'

  const OvulationTestEntry({required this.date, required this.result});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'result': result,
      };

  factory OvulationTestEntry.fromJson(Map<String, dynamic> json) => OvulationTestEntry(
        date: DateTime.parse(json['date'] as String),
        result: json['result'] as String,
      );
}

/// Configuración del modo embarazo: activado sí/no + fecha de última
/// menstruación (LMP, "last menstrual period").
class PregnancySettings {
  final bool enabled;
  final DateTime? lmp;

  /// true si se está esperando mellizos/gemelos (embarazo múltiple). Ajusta
  /// la fecha probable de parto (37 semanas en vez de 40) y el resto de los
  /// cálculos de semanas en toda la app — ver PregnancyTrackingScreen.
  final bool isTwins;

  const PregnancySettings({this.enabled = false, this.lmp, this.isTwins = false});

  PregnancySettings copyWith({bool? enabled, DateTime? lmp, bool clearLmp = false, bool? isTwins}) =>
      PregnancySettings(
        enabled: enabled ?? this.enabled,
        lmp: clearLmp ? null : (lmp ?? this.lmp),
        isTwins: isTwins ?? this.isTwins,
      );
}

/// Consolida toda la configuración que en el prototipo web vivía en
/// localStorage (tema, PIN, modo embarazo, recordatorio diario y de
/// pastilla), usando SharedPreferences con el mismo patrón que el resto
/// de la app.
class SettingsService {
  static const _themeKey = 'cicloplus_theme';
  static const _partnerViewerThemeKey = 'cicloplus_partner_viewer_theme';
  static const _pinKey = 'cicloplus_pin';
  static const _pregnancyEnabledKey = 'cicloplus_pregnancy_enabled';
  static const _pregnancyLmpKey = 'cicloplus_pregnancy_lmp';
  static const _pregnancyTwinsKey = 'cicloplus_pregnancy_twins';
  static const _dailyReminderEnabledKey = 'cicloplus_daily_reminder_enabled';
  static const _dailyReminderTimeKey = 'cicloplus_daily_reminder_time';
  static const _pillReminderEnabledKey = 'cicloplus_pill_reminder_enabled';
  static const _pillReminderTimeKey = 'cicloplus_pill_reminder_time';
  static const _sexAlwaysVisibleKey = 'cicloplus_sex_always_visible';
  static const _hideCalendarHintKey = 'cicloplus_hide_calendar_hint';
  static const _heightCmKey = 'cicloplus_height_cm';
  static const _languageKey = 'cicloplus_language';
  static const _medicalAppointmentsKey = 'cicloplus_medical_appointments';
  static const _healthSyncEnabledKey = 'cicloplus_health_sync_enabled';
  static const _irregularCycleModeKey = 'cicloplus_irregular_cycle_mode';
  static const _wellnessEnabledKey = 'cicloplus_wellness_enabled';
  static const _profileNameKey = 'cicloplus_profile_name';
  static const _profileLastNameKey = 'cicloplus_profile_last_name';
  static const _profileBirthDateKey = 'cicloplus_profile_birth_date';
  static const _profileReferenceWeightKey = 'cicloplus_profile_reference_weight';
  // ---- Ampliación fase "Recordatorio"/"Yo" ----
  static const _breastSelfExamReminderEnabledKey = 'cicloplus_breast_self_exam_reminder_enabled';
  static const _breastSelfExamReminderAtKey = 'cicloplus_breast_self_exam_reminder_at';
  static const _drinkWaterReminderEnabledKey = 'cicloplus_drink_water_reminder_enabled';
  static const _drinkWaterReminderTimeKey = 'cicloplus_drink_water_reminder_time';
  static const _cyclePhaseReminderEnabledKey = 'cicloplus_cycle_phase_reminder_enabled';
  static const _cyclePhaseReminderTimeKey = 'cicloplus_cycle_phase_reminder_time';
  static const _userGoalKey = 'cicloplus_user_goal';
  static const _conceiveTargetDateKey = 'cicloplus_conceive_target_date';
  static const _conceiveTryingDurationKey = 'cicloplus_conceive_trying_duration';
  static const _conceiveRecentContraceptionKey = 'cicloplus_conceive_recent_contraception';
  static const _conceiveAvgCycleLengthKey = 'cicloplus_conceive_avg_cycle_length';
  static const _conceiveAvgPeriodLengthKey = 'cicloplus_conceive_avg_period_length';
  static const _conceiveUsesOvulationTestsKey = 'cicloplus_conceive_uses_ovulation_tests';
  static const _conceiveDiagnosedConditionsKey = 'cicloplus_conceive_diagnosed_conditions';
  static const _conceiveIntakeConfirmedAtKey = 'cicloplus_conceive_intake_confirmed_at';
  static const _ovulationTestsKey = 'cicloplus_ovulation_tests';
  static const _calendarLegendHiddenKey = 'cicloplus_calendar_legend_hidden';
  static const _calendarPaletteKey = 'cicloplus_calendar_palette';
  static const _calendarStyleKey = 'cicloplus_calendar_style';
  // ---- Forma ('square' | 'circle') y relleno ('filled' | 'outline') de
  // las marcas de día del estilo "Clásico" del calendario — independiente
  // de _calendarStyleKey (que elige Clásico/Elegante/iOS) y de la paleta
  // de colores: la usuaria puede combinar cualquier forma con cualquier
  // relleno, a su gusto. Ver CalendarStyleController y CalendarGrid. ----
  static const _calendarMarkerShapeKey = 'cicloplus_calendar_marker_shape';
  static const _calendarMarkerFillKey = 'cicloplus_calendar_marker_fill';
  static const _coupleIllustrationKey = 'cicloplus_couple_illustration';
  static const _profilePhotoKey = 'cicloplus_profile_photo';
  // ---- Datos de perfil usados por las calculadoras de la pantalla Peso
  // (IMC/ICA/grasa corporal): altura y fecha de nacimiento ya existían
  // (`_heightCmKey`/`_profileBirthDateKey`, reutilizados tal cual); cintura
  // y sexo biológico son nuevos, añadidos aquí en vez de en `DayEntry`
  // porque son datos de perfil (cambian rara vez), no datos diarios.
  static const _waistCmKey = 'cicloplus_waist_cm';
  static const _biologicalSexKey = 'cicloplus_biological_sex'; // 'female' | 'male'
  // ---- Apariencia de las fotos de barriga del Simulacro de embarazo:
  // 'default' | 'black'. Ver pregnancy_week_info.dart/pregnancyBellyImagePath.
  static const _bellyAppearanceKey = 'cicloplus_belly_appearance';
  // ---- Compartir las fotos del bebé/barriga con el socio vinculado (ver
  // "Invitar a un socio" y PartnerService). Por defecto false: aunque se
  // vincule a alguien, las fotos quedan ocultas para esa persona hasta que
  // la usuaria decide mostrarlas explícitamente aquí. El resto del
  // seguimiento (semana, fechas, consejos) se comparte igual, esto solo
  // afecta a las imágenes. ----
  static const _shareBabyPhotosKey = 'cicloplus_share_baby_photos';
  static const _pendingReconnectOwnerUidKey = 'cicloplus_pending_reconnect_owner_uid';
  static const _pendingReconnectRequestIdKey = 'cicloplus_pending_reconnect_request_id';
  // ---- Días en que se abrió la app (independiente de si ese día se
  // registró algún dato de salud) — usado por el "jardín" de Hoy para que
  // las flores se marchiten según los días SIN ENTRAR a la app, no según
  // los días sin registrar síntomas. Ver [recordAppOpenToday] y
  // garden_stage.dart. Claves 'yyyy-MM-dd', mismo formato que
  // cycle_predictor.dart:dateKey (duplicado aquí a propósito, sin import,
  // para no acoplar este servicio de preferencias a esa lógica de ciclo).
  static const _appOpenDatesKey = 'cicloplus_app_open_dates';

  // ---- Tema ----
  Future<String> loadThemeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'pink';
  }

  Future<void> saveThemeId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, id);
  }

  // ---- Color de la pantalla "Ver embarazo de tu pareja" (cuenta anónima
  // de solo lectura) — ajuste puramente local del dispositivo, igual que
  // el tema normal, pero con su propia clave y su propio valor por
  // defecto ('blue') para no heredar el rosa del tema principal la
  // primera vez que alguien entra como socio/pareja. ----
  Future<String> loadPartnerViewerTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_partnerViewerThemeKey) ?? 'blue';
  }

  Future<void> savePartnerViewerTheme(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_partnerViewerThemeKey, id);
  }

  // ---- Paleta de colores del calendario ----
  Future<String> loadCalendarPaletteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_calendarPaletteKey) ?? 'pastel';
  }

  Future<void> saveCalendarPaletteId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_calendarPaletteKey, id);
  }

  // ---- Paleta 'custom' del calendario: la usuaria elige cada uno de los
  // 7 colores a mano (ver CalendarPaletteOption) desde la hoja "Personalizar
  // colores" en Configuración. Se guarda un int por color, mismo patrón que
  // el resto de este servicio; si nunca se ha guardado nada se usan los
  // valores de la paleta 'pastel' como punto de partida razonable. ----
  static const _customPeriodFillKey = 'cicloplus_custom_period_fill';
  static const _customPredictedFillKey = 'cicloplus_custom_predicted_fill';
  static const _customPredictedBorderKey = 'cicloplus_custom_predicted_border';
  static const _customFertileFillKey = 'cicloplus_custom_fertile_fill';
  static const _customFertileBorderKey = 'cicloplus_custom_fertile_border';
  static const _customTodayRingKey = 'cicloplus_custom_today_ring';
  static const _customOvulationFillKey = 'cicloplus_custom_ovulation_fill';

  Future<CalendarPaletteOption> loadCustomCalendarPalette() async {
    final prefs = await SharedPreferences.getInstance();
    final base = kCalendarPalettes.first;
    return CalendarPaletteOption(
      id: 'custom',
      name: 'Personalizado',
      periodFill: prefs.getInt(_customPeriodFillKey) ?? base.periodFill,
      predictedFill: prefs.getInt(_customPredictedFillKey) ?? base.predictedFill,
      predictedBorder: prefs.getInt(_customPredictedBorderKey) ?? base.predictedBorder,
      fertileFill: prefs.getInt(_customFertileFillKey) ?? base.fertileFill,
      fertileBorder: prefs.getInt(_customFertileBorderKey) ?? base.fertileBorder,
      todayRing: prefs.getInt(_customTodayRingKey) ?? base.todayRing,
      ovulationFill: prefs.getInt(_customOvulationFillKey) ?? base.ovulationFill,
    );
  }

  Future<void> saveCustomCalendarPalette(CalendarPaletteOption p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_customPeriodFillKey, p.periodFill);
    await prefs.setInt(_customPredictedFillKey, p.predictedFill);
    await prefs.setInt(_customPredictedBorderKey, p.predictedBorder);
    await prefs.setInt(_customFertileFillKey, p.fertileFill);
    await prefs.setInt(_customFertileBorderKey, p.fertileBorder);
    await prefs.setInt(_customTodayRingKey, p.todayRing);
    await prefs.setInt(_customOvulationFillKey, p.ovulationFill);
  }

  // ---- Estilo de calendario ('clasico' | 'elegante') — mismo patrón que
  // la paleta de colores de arriba, pero para elegir entre el grid
  // clásico (CalendarGrid) y el nuevo diseño elevado (CalendarGridElegant)
  // en vez de solo los colores. Ver CalendarStyleController. ----
  Future<String> loadCalendarStyleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_calendarStyleKey) ?? 'elegante';
  }

  Future<void> saveCalendarStyleId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_calendarStyleKey, id);
  }

  // ---- Forma y relleno de las marcas de día (estilo "Clásico") ----
  Future<String> loadCalendarMarkerShape() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_calendarMarkerShapeKey) ?? 'raya';
  }

  Future<void> saveCalendarMarkerShape(String shape) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_calendarMarkerShapeKey, shape);
  }

  Future<String> loadCalendarMarkerFill() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_calendarMarkerFillKey) ?? 'outline';
  }

  Future<void> saveCalendarMarkerFill(String fill) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_calendarMarkerFillKey, fill);
  }

  // ---- Apariencia de la ilustración de "Sincroniza con tu pareja" ----
  // Puramente estético/local — solo cambia qué imagen se dibuja, igual
  // que la paleta del calendario. Valor por defecto 'mixta'.
  Future<String> loadCoupleIllustrationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_coupleIllustrationKey) ?? 'mixta';
  }

  Future<void> saveCoupleIllustrationId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_coupleIllustrationKey, id);
  }

  // ---- PIN ----
  Future<String?> loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey);
  }

  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
  }

  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
  }

  Future<bool> hasPin() async {
    final pin = await loadPin();
    return pin != null && pin.isNotEmpty;
  }

  // ---- Modo embarazo ----
  Future<PregnancySettings> loadPregnancySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_pregnancyEnabledKey) ?? false;
    final lmpRaw = prefs.getString(_pregnancyLmpKey);
    final lmp = lmpRaw != null ? DateTime.tryParse(lmpRaw) : null;
    final isTwins = prefs.getBool(_pregnancyTwinsKey) ?? false;
    return PregnancySettings(enabled: enabled, lmp: lmp, isTwins: isTwins);
  }

  Future<void> savePregnancySettings(PregnancySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pregnancyEnabledKey, settings.enabled);
    if (settings.lmp != null) {
      await prefs.setString(_pregnancyLmpKey, settings.lmp!.toIso8601String());
    } else {
      await prefs.remove(_pregnancyLmpKey);
    }
    await prefs.setBool(_pregnancyTwinsKey, settings.isTwins);
  }

  // ---- Recordatorio diario de registro ----
  Future<DailyTimeReminderSettings> loadDailyReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return DailyTimeReminderSettings(
      enabled: prefs.getBool(_dailyReminderEnabledKey) ?? false,
      time: prefs.getString(_dailyReminderTimeKey) ?? '20:00',
    );
  }

  Future<void> saveDailyReminderSettings(DailyTimeReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyReminderEnabledKey, settings.enabled);
    await prefs.setString(_dailyReminderTimeKey, settings.time);
  }

  // ---- Recordatorio de pastilla anticonceptiva ----
  Future<DailyTimeReminderSettings> loadPillReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return DailyTimeReminderSettings(
      enabled: prefs.getBool(_pillReminderEnabledKey) ?? false,
      time: prefs.getString(_pillReminderTimeKey) ?? '08:00',
    );
  }

  Future<void> savePillReminderSettings(DailyTimeReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pillReminderEnabledKey, settings.enabled);
    await prefs.setString(_pillReminderTimeKey, settings.time);
  }

  // ---- Vida sexual siempre visible (fuera de "Más detalles") ----
  Future<bool> loadSexAlwaysVisible() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sexAlwaysVisibleKey) ?? false;
  }

  Future<void> saveSexAlwaysVisible(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sexAlwaysVisibleKey, value);
  }

  // ---- Ocultar permanentemente el aviso del calendario, cuando la
  // usuaria lo cierra con la X ----
  Future<bool> loadHideCalendarHint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hideCalendarHintKey) ?? false;
  }

  Future<void> saveHideCalendarHint(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideCalendarHintKey, value);
  }

  // ---- Altura (dato fijo del perfil, usado para calcular el IMC junto
  // con el último peso registrado) ----
  Future<double?> loadHeightCm() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_heightCmKey);
  }

  Future<void> saveHeightCm(double? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_heightCmKey);
    } else {
      await prefs.setDouble(_heightCmKey, value);
    }
  }

  // ---- Nombre (para personalizar saludos, ej. "Hola, Ana") ----
  Future<String?> loadProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileNameKey);
  }

  Future<void> saveProfileName(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.trim().isEmpty) {
      await prefs.remove(_profileNameKey);
    } else {
      await prefs.setString(_profileNameKey, value.trim());
    }
  }

  // ---- Foto de perfil (mismo formato que las fotos de entrada de día:
  // data URL base64 de un JPEG ya redimensionado — ver PhotoService) ----
  Future<String?> loadProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profilePhotoKey);
  }

  Future<void> saveProfilePhoto(String? dataUrl) async {
    final prefs = await SharedPreferences.getInstance();
    if (dataUrl == null) {
      await prefs.remove(_profilePhotoKey);
    } else {
      await prefs.setString(_profilePhotoKey, dataUrl);
    }
  }

  // ---- Apellido (opcional) ----
  Future<String?> loadProfileLastName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileLastNameKey);
  }

  Future<void> saveProfileLastName(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.trim().isEmpty) {
      await prefs.remove(_profileLastNameKey);
    } else {
      await prefs.setString(_profileLastNameKey, value.trim());
    }
  }

  // ---- Fecha de nacimiento (contexto médico y para adaptar consejos
  // educativos según edad, ej. perimenopausia) ----
  Future<DateTime?> loadProfileBirthDate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileBirthDateKey);
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  Future<void> saveProfileBirthDate(DateTime? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_profileBirthDateKey);
    } else {
      await prefs.setString(_profileBirthDateKey, value.toIso8601String());
    }
  }

  // ---- Peso de referencia (dato base del perfil, distinto del peso que
  // se registra día a día en Bienestar — opcional, solo para tener un
  // punto de partida si la usuaria no lleva un registro diario de peso) ----
  Future<double?> loadProfileReferenceWeight() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_profileReferenceWeightKey);
  }

  Future<void> saveProfileReferenceWeight(double? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_profileReferenceWeightKey);
    } else {
      await prefs.setDouble(_profileReferenceWeightKey, value);
    }
  }

  // ---- Idioma de la app ('es' | 'en' | 'fr' | 'de') ----
  // Devuelve null si la persona nunca eligió un idioma a mano — en ese
  // caso LocaleController usa el idioma del sistema como valor inicial.
  Future<String?> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }

  Future<void> saveLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, code);
  }

  // ---- Citas médicas (lista, ordenadas por fecha al leer) ----
  Future<List<MedicalAppointment>> loadMedicalAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_medicalAppointmentsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => MedicalAppointment.fromJson(e as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  Future<void> saveMedicalAppointments(List<MedicalAppointment> appointments) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(appointments.map((a) => a.toJson()).toList());
    await prefs.setString(_medicalAppointmentsKey, raw);
  }

  // ---- Sincronización con Apple Salud / Google Fit (Health Connect) ----
  Future<bool> loadHealthSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_healthSyncEnabledKey) ?? false;
  }

  Future<void> saveHealthSyncEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_healthSyncEnabledKey, value);
  }

  // ---- Modo "ciclo irregular": activado a mano por la usuaria cuando su
  // ciclo varía demasiado como para confiar en una fecha exacta. Con esto
  // activo, CyclePredictor amplía el rango de predicción aunque el
  // historial de ciclos por sí solo no cruce el umbral de irregularidad
  // detectado automáticamente. ----
  Future<bool> loadIrregularCycleMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_irregularCycleModeKey) ?? false;
  }

  Future<void> saveIrregularCycleMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_irregularCycleModeKey, value);
  }

  // ---- Orden de las tarjetas de Registrar (Vida sexual si fija/Ánimo/
  // Energía/Piel y cabello/Medicamento) — configurable desde Configuración
  // > Opciones personalizadas > "Orden de las tarjetas de Registrar". Se
  // guarda la lista de ids tal cual (sin conocer aquí cuáles son válidos ni
  // el orden por defecto — eso vive en register_screen.dart como
  // kDefaultRegisterCardOrder, para no crear una dependencia circular entre
  // este servicio y esa pantalla); si no hay nada guardado todavía,
  // devuelve una lista vacía y quien llama aplica su propio orden por
  // defecto. ----
  static const _registerCardOrderKey = 'cicloplus_register_card_order';

  Future<List<String>> loadRegisterCardOrderRaw() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_registerCardOrderKey) ?? const [];
  }

  Future<void> saveRegisterCardOrder(List<String> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_registerCardOrderKey, order);
  }

  // ---- Sección "Bienestar" (temperatura, agua, sueño, peso): activada
  // por defecto (true), para no cambiar el comportamiento de quien ya
  // usaba la app. Si se desactiva, la sección se oculta del editor del
  // día, Estadísticas y Línea de tiempo — pero los datos ya guardados NO
  // se borran, solo dejan de mostrarse, por si la usuaria la reactiva
  // más adelante. ----
  Future<bool> loadWellnessEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wellnessEnabledKey) ?? true;
  }

  Future<void> saveWellnessEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wellnessEnabledKey, value);
  }

  // ---- Autoexamen de mamas: antes un booleano suelto que no programaba
  // ninguna notificación real. Ahora guarda también la fecha/hora exacta
  // (milisegundos epoch, igual patrón que ReminderSettings.periodStartAt)
  // elegida en el bottom sheet ReminderTimeSheet — se conserva aunque el
  // interruptor se apague, por si se reactiva más tarde (mismo criterio
  // que ReminderService.saveSettings). ----
  Future<bool> loadBreastSelfExamReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_breastSelfExamReminderEnabledKey) ?? false;
  }

  Future<void> saveBreastSelfExamReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_breastSelfExamReminderEnabledKey, value);
  }

  Future<DateTime?> loadBreastSelfExamReminderAt() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_breastSelfExamReminderAtKey);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  Future<void> saveBreastSelfExamReminderAt(DateTime? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_breastSelfExamReminderAtKey);
    } else {
      await prefs.setInt(_breastSelfExamReminderAtKey, value.millisecondsSinceEpoch);
    }
  }

  // ---- "Recuerda beber agua": a diferencia del resto de recordatorios de
  // esta ampliación, este es un hábito diario recurrente sin fecha con
  // sentido propio (no hay una "fecha calculada" del ciclo para beber
  // agua) — por eso reutiliza DailyTimeReminderSettings tal cual (mismo
  // modelo ya usado por Píldora/Registro Diario) en vez de un modelo
  // paralelo de fecha+hora como el de Autoexamen. Hora por defecto 10:00,
  // un valor razonable de media mañana. ----
  Future<DailyTimeReminderSettings> loadDrinkWaterReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return DailyTimeReminderSettings(
      enabled: prefs.getBool(_drinkWaterReminderEnabledKey) ?? false,
      time: prefs.getString(_drinkWaterReminderTimeKey) ?? '10:00',
    );
  }

  Future<void> saveDrinkWaterReminderSettings(DailyTimeReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_drinkWaterReminderEnabledKey, settings.enabled);
    await prefs.setString(_drinkWaterReminderTimeKey, settings.time);
  }

  // ---- Sección "Notificaciones" de Recordatorio: aviso de fase del ciclo
  // (consejos/recordatorios ligados a la fase actual). Es informativo y
  // recurrente, no ligado a una fecha puntual del ciclo: se dispara
  // automáticamente cuando CyclePredictor.currentPhaseKey() detecta que la
  // fase cambió respecto al último chequeo (ver DailyNotificationService.
  // rescheduleCyclePhaseReminder). En vez de pedir fecha, el sheet solo
  // pide a qué HORA del día revisar/notificar ese cambio — por defecto
  // 9:00, igual que el resto de avisos "informativos" de esta pantalla,
  // así se mantiene consistencia visual con el resto de interruptores en
  // vez de mostrar un sheet sin ningún campo editable. ----
  Future<bool> loadCyclePhaseReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cyclePhaseReminderEnabledKey) ?? false;
  }

  Future<void> saveCyclePhaseReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cyclePhaseReminderEnabledKey, value);
  }

  Future<String> loadCyclePhaseReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cyclePhaseReminderTimeKey) ?? '09:00';
  }

  Future<void> saveCyclePhaseReminderTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cyclePhaseReminderTimeKey, time);
  }

  // ---- "Mi objetivo" (pantalla "Yo"): 'period' | 'conceive' | 'pregnancy'.
  // Se guarda como texto simple en vez de un enum propio para seguir el
  // mismo patrón liviano que `_languageKey`. 'pregnancy' se mantiene
  // coherente con `PregnancySettings.enabled` (ver MeScreen._selectGoal):
  // elegir "Seguir mi embarazo" aquí también activa el modo embarazo ya
  // existente, en vez de crear un estado paralelo que lo contradiga. ----
  Future<String> loadUserGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userGoalKey) ?? 'period';
  }

  Future<void> saveUserGoal(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userGoalKey, value);
  }

  // ---- Cuestionario rápido cada vez que se elige "Intentar concebir"
  // (ver widgets/conceive_intake_sheet.dart) — igual patrón liviano que el
  // resto de flags/valores de esta clase. La regularidad del ciclo NO se
  // guarda aparte: esa pregunta lee/escribe directamente
  // `_irregularCycleModeKey` de arriba, para no duplicar el mismo dato. ----
  Future<DateTime?> loadConceiveTargetDate() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_conceiveTargetDateKey);
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  Future<void> saveConceiveTargetDate(DateTime? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_conceiveTargetDateKey);
    } else {
      await prefs.setString(_conceiveTargetDateKey, value.toIso8601String());
    }
  }

  Future<String?> loadConceiveTryingDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_conceiveTryingDurationKey);
  }

  Future<void> saveConceiveTryingDuration(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_conceiveTryingDurationKey, value);
  }

  Future<bool?> loadConceiveRecentContraception() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_conceiveRecentContraceptionKey)) return null;
    return prefs.getBool(_conceiveRecentContraceptionKey);
  }

  Future<void> saveConceiveRecentContraception(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_conceiveRecentContraceptionKey, value);
  }

  // ---- Preguntas añadidas al cuestionario para afinar el cálculo cuando
  // todavía no hay periodos registrados (ver CyclePredictor.
  // selfReportedCycleLen/selfReportedPeriodLen). Uso de tests de
  // ovulación y condiciones diagnosticadas son solo informativas por
  // ahora (no alimentan ningún cálculo), igual que tiempo intentándolo. ----
  Future<int?> loadConceiveAvgCycleLength() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_conceiveAvgCycleLengthKey);
  }

  Future<void> saveConceiveAvgCycleLength(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_conceiveAvgCycleLengthKey, value);
  }

  Future<int?> loadConceiveAvgPeriodLength() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_conceiveAvgPeriodLengthKey);
  }

  Future<void> saveConceiveAvgPeriodLength(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_conceiveAvgPeriodLengthKey, value);
  }

  Future<bool?> loadConceiveUsesOvulationTests() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_conceiveUsesOvulationTestsKey)) return null;
    return prefs.getBool(_conceiveUsesOvulationTestsKey);
  }

  Future<void> saveConceiveUsesOvulationTests(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_conceiveUsesOvulationTestsKey, value);
  }

  Future<List<String>> loadConceiveDiagnosedConditions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_conceiveDiagnosedConditionsKey) ?? const [];
  }

  Future<void> saveConceiveDiagnosedConditions(List<String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_conceiveDiagnosedConditionsKey, values);
  }

  // Fecha en que se confirmó por última vez el cuestionario de "Intentar
  // concebir" (al terminarlo, o al responder "Sigue igual" en el diálogo
  // corto de maybeShowConceiveIntake) — se usa para decidir si, al pasar
  // 3 meses, conviene tratarlo como si fuera la primera vez otra vez en
  // lugar de solo preguntar si sigue igual, ya que la situación de la
  // usuaria puede haber cambiado bastante en ese tiempo.
  Future<DateTime?> loadConceiveIntakeConfirmedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_conceiveIntakeConfirmedAtKey);
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  Future<void> saveConceiveIntakeConfirmedAt(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_conceiveIntakeConfirmedAtKey, value.toIso8601String());
  }

  // ---- Tests de ovulación (lista, ordenados por fecha descendente al leer,
  // igual patrón que loadMedicalAppointments/saveMedicalAppointments) ----
  Future<List<OvulationTestEntry>> loadOvulationTests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ovulationTestsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => OvulationTestEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> saveOvulationTests(List<OvulationTestEntry> tests) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(tests.map((t) => t.toJson()).toList());
    await prefs.setString(_ovulationTestsKey, raw);
  }

  // ---- Visibilidad de categorías en el calendario ("Leyenda") ----
  // Se guarda la lista de categorías OCULTAS (no las visibles), para que el
  // valor por defecto sea "todo visible" sin tener que escribir nada la
  // primera vez que se abre la app — igual patrón que `_wellnessEnabledKey`
  // pero invertido porque aquí el estado por defecto es "todo activado".
  Future<Set<String>> loadCalendarLegendHidden() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_calendarLegendHiddenKey);
    if (raw == null) return <String>{};
    return raw.toSet();
  }

  Future<void> saveCalendarLegendHidden(Set<String> hiddenIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_calendarLegendHiddenKey, hiddenIds.toList());
  }

  // ---- Días en que se abrió la app (ver comentario de _appOpenDatesKey
  // arriba) ----
  Future<Set<String>> loadAppOpenDates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_appOpenDatesKey);
    if (raw == null) return <String>{};
    return raw.toSet();
  }

  /// Marca HOY como un día en que se abrió la app (no hace nada si hoy ya
  /// estaba marcado — llamarlo varias veces el mismo día, p. ej. por un hot
  /// restart, es seguro). Se llama una vez al arrancar la app (ver
  /// main.dart), antes de construir ninguna pantalla, para que la tarjeta
  /// "Tu jardín" de Hoy ya tenga el dato del día actual desde el primer
  /// frame.
  ///
  /// Recorta la lista a los últimos 40 días al guardar — de sobra para la
  /// racha de hasta 30 días que revisa [gardenStageIndex] en
  /// garden_stage.dart, sin dejar que esta lista crezca sin límite con los
  /// meses/años de uso de la app.
  Future<void> recordAppOpenToday() async {
    final now = DateTime.now();
    final todayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final dates = await loadAppOpenDates();
    if (dates.contains(todayKey)) return;
    dates.add(todayKey);
    final sorted = dates.toList()..sort();
    final trimmed = sorted.length > 40 ? sorted.sublist(sorted.length - 40) : sorted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_appOpenDatesKey, trimmed);
  }

  /// Se llama UNA VEZ, justo al crear una cuenta nueva (ver
  /// AuthService.signUp/_loadOrCreateSocialUser), para que el "jardín" de
  /// Hoy ya se vea en floración máxima (etapa 4, "esplendor") desde el
  /// primer momento en vez de arrancar marchito — es la primera impresión
  /// de la cuenta, y con la simulación normal de [gardenStageIndex]
  /// (garden_stage.dart) una cuenta recién creada empezaría en etapa 1
  /// (los ~19 días "sin abrir la app" previos a hoy, que en realidad nunca
  /// existieron, pesan igual que una ausencia real).
  ///
  /// En vez de un caso especial aparte, reaprovecha la misma simulación:
  /// [gardenStageIndex] necesita 4 días seguidos "abriendo la app" para
  /// pasar de muerta a floración máxima (ver su documentación), así que
  /// basta con pre-sembrar HOY y los 3 días anteriores como si se hubiera
  /// abierto la app esos días — a partir de ahí el jardín sigue subiendo o
  /// bajando con el uso real, exactamente igual que cualquier otra cuenta.
  Future<void> seedGardenBloomOnAccountCreation() async {
    final now = DateTime.now();
    final dates = await loadAppOpenDates();
    for (int i = 0; i < 4; i++) {
      final d = now.subtract(Duration(days: i));
      final key =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      dates.add(key);
    }
    final sorted = dates.toList()..sort();
    final trimmed = sorted.length > 40 ? sorted.sublist(sorted.length - 40) : sorted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_appOpenDatesKey, trimmed);
  }

  // ---- Contorno de cintura (cm), usado por la calculadora de ICA en la
  // pantalla de detalle de Peso ("Tus datos") ----
  Future<double?> loadWaistCm() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_waistCmKey);
  }

  Future<void> saveWaistCm(double? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_waistCmKey);
    } else {
      await prefs.setDouble(_waistCmKey, value);
    }
  }

  // ---- Sexo biológico ('female' | 'male'), usado por la calculadora de %
  // de grasa corporal (fórmula de Deurenberg) en la pantalla de detalle de
  // Peso. Por defecto null (sin elegir todavía) — la UI decide qué mostrar
  // marcado por defecto (Mujer, ya que la app es de seguimiento menstrual).
  Future<String?> loadBiologicalSex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_biologicalSexKey);
  }

  Future<void> saveBiologicalSex(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_biologicalSexKey, value);
  }

  // ---- Apariencia de las fotos de barriga en el Simulacro de embarazo
  // ('default' | 'black') ----
  Future<String> loadBellyAppearance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_bellyAppearanceKey) ?? 'default';
  }

  Future<void> saveBellyAppearance(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bellyAppearanceKey, value);
  }

  // ---- Compartir fotos del bebé/barriga con el socio vinculado ----
  Future<bool> loadShareBabyPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_shareBabyPhotosKey) ?? false;
  }

  Future<void> saveShareBabyPhotos(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shareBabyPhotosKey, value);
  }

  // ---- Solicitud de reconexión pendiente (ver PartnerService) ----
  //
  // Cuando quien ve el embarazo de su pareja cierra sesión y luego vuelve a
  // pegar el mismo código, se crea una "solicitud de reconexión" que la
  // dueña tiene que aceptar — no se vincula al instante. Mientras espera
  // esa aprobación, guardamos aquí a qué dueña/solicitud está esperando,
  // para poder retomar la espera si cierra y reabre la app (la sesión
  // anónima sigue siendo la misma mientras no toque "Salir" otra vez).
  Future<Map<String, String>?> loadPendingReconnect() async {
    final prefs = await SharedPreferences.getInstance();
    final ownerUid = prefs.getString(_pendingReconnectOwnerUidKey);
    final requestId = prefs.getString(_pendingReconnectRequestIdKey);
    if (ownerUid == null || requestId == null) return null;
    return {'ownerUid': ownerUid, 'requestId': requestId};
  }

  Future<void> savePendingReconnect({required String ownerUid, required String requestId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingReconnectOwnerUidKey, ownerUid);
    await prefs.setString(_pendingReconnectRequestIdKey, requestId);
  }

  Future<void> clearPendingReconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingReconnectOwnerUidKey);
    await prefs.remove(_pendingReconnectRequestIdKey);
  }

  // ---- Borrado completo ----

  /// Borra TODOS los ajustes guardados en SharedPreferences por esta
  /// clase: tema, PIN, perfil (nombre/apellido/fecha nacimiento/altura/
  /// peso/foto), idioma, paleta del calendario, embarazo, recordatorios,
  /// objetivo, tests de ovulación, citas médicas, sincronización de salud,
  /// modo ciclo irregular... Usado por "Borrar todos los datos" (además
  /// del historial del ciclo en Firestore, que borra StorageService.deleteAll)
  /// y por "Borrar cuenta".
  ///
  /// Borra por prefijo (`cicloplus_`) en vez de listar cada clave a mano,
  /// para que nunca quede desactualizado si se añade un ajuste nuevo y se
  /// olvida incluirlo aquí explícitamente.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = prefs.getKeys().where((key) => key.startsWith('cicloplus_'));
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }
}

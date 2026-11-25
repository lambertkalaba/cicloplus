import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_bridge.dart';
import 'settings_sync.dart';

/// Clave de día "yyyy-mm-dd".
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime parseKey(String k) {
  final p = k.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// Registro de un día.
class DayLog {
  int flow; // 0 ninguno, 1 ligero, 2 medio, 3 abundante
  Set<String> symptoms;
  int pain; // 0 sin dolor, 1 leve, 2 moderada, 3 intensa
  int mood; // 0 sin registrar, 1 muy bajo … 5 excelente
  String note;
  int water; // vasos
  double? sleep; // horas
  double? weight; // kg
  int sex; // 0 nada, 1 con protección, 2 sin protección
  bool breastExam;
  int activity; // minutos de actividad física

  /// Datos que solo existían en CicloPlus (temperatura, moco cervical,
  /// manchado, medicación, energía, piel y cabello, autoexamen, detalles de
  /// vida sexual, foto…), guardados con los mismos nombres que en la nube.
  Map<String, dynamic> extra;

  DayLog({
    this.flow = 0,
    Set<String>? symptoms,
    this.pain = 0,
    this.mood = 0,
    this.note = '',
    this.water = 0,
    this.sleep,
    this.weight,
    this.sex = 0,
    this.breastExam = false,
    this.activity = 0,
    Map<String, dynamic>? extra,
  })  : symptoms = symptoms ?? <String>{},
        extra = extra ?? <String, dynamic>{};

  static dynamic _deep(dynamic v) => v is List ? List.from(v) : (v is Map ? Map<String, dynamic>.from(v) : v);

  static bool _filled(dynamic v) => !(v == null || v == false || v == '' || (v is List && v.isEmpty) || (v is Map && v.isEmpty));

  bool get hasExtra => extra.values.any(_filled);

  DayLog copy() => DayLog(
        flow: flow,
        symptoms: Set<String>.from(symptoms),
        pain: pain,
        mood: mood,
        note: note,
        water: water,
        sleep: sleep,
        weight: weight,
        sex: sex,
        breastExam: breastExam,
        activity: activity,
        extra: extra.map((k, v) => MapEntry(k, _deep(v))),
      );

  bool get isEmpty =>
      flow == 0 &&
      symptoms.isEmpty &&
      pain == 0 &&
      mood == 0 &&
      note.trim().isEmpty &&
      water == 0 &&
      sleep == null &&
      weight == null &&
      sex == 0 &&
      !breastExam &&
      activity == 0 &&
      !hasExtra;

  Map<String, dynamic> toJson() => {
        if (flow != 0) 'f': flow,
        if (symptoms.isNotEmpty) 's': symptoms.toList(),
        if (pain != 0) 'p': pain,
        if (mood != 0) 'm': mood,
        if (note.isNotEmpty) 'n': note,
        if (water != 0) 'w': water,
        if (sleep != null) 'sl': sleep,
        if (weight != null) 'kg': weight,
        if (sex != 0) 'sx': sex,
        if (breastExam) 'be': true,
        if (activity != 0) 'ac': activity,
        if (hasExtra) 'x': Map.fromEntries(extra.entries.where((e) => _filled(e.value))),
      };

  factory DayLog.fromJson(Map<String, dynamic> j) => DayLog(
        flow: (j['f'] as num?)?.toInt() ?? 0,
        symptoms: ((j['s'] as List?) ?? const []).map((e) => e.toString()).toSet(),
        pain: (j['p'] as num?)?.toInt() ?? 0,
        mood: (j['m'] as num?)?.toInt() ?? 0,
        note: (j['n'] as String?) ?? '',
        water: (j['w'] as num?)?.toInt() ?? 0,
        sleep: (j['sl'] as num?)?.toDouble(),
        weight: (j['kg'] as num?)?.toDouble(),
        sex: (j['sx'] as num?)?.toInt() ?? 0,
        breastExam: j['be'] == true,
        activity: (j['ac'] as num?)?.toInt() ?? 0,
        extra: (j['x'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)),
      );
}

/// Ajustes de recordatorios.
class ReminderSettings {
  bool period;
  int periodDaysBefore;
  bool fertile;
  bool ovulation;
  bool daily;
  int dailyMinutes; // minutos desde medianoche
  bool water;
  bool pill;
  int pillMinutes;
  bool breastExam;
  int breastExamDay; // día del mes
  bool weight;
  bool activity;
  int activityMinutes;
  bool bedtime;
  int bedtimeMinutes;

  ReminderSettings({
    this.period = true,
    this.periodDaysBefore = 2,
    this.fertile = false,
    this.ovulation = false,
    this.daily = false,
    this.dailyMinutes = 21 * 60,
    this.water = false,
    this.pill = false,
    this.pillMinutes = 22 * 60,
    this.breastExam = false,
    this.breastExamDay = 10,
    this.weight = false,
    this.activity = false,
    this.activityMinutes = 18 * 60,
    this.bedtime = false,
    this.bedtimeMinutes = 22 * 60 + 30,
  });

  Map<String, dynamic> toJson() => {
        'period': period,
        'periodDaysBefore': periodDaysBefore,
        'fertile': fertile,
        'ovulation': ovulation,
        'daily': daily,
        'dailyMinutes': dailyMinutes,
        'water': water,
        'pill': pill,
        'pillMinutes': pillMinutes,
        'breastExam': breastExam,
        'breastExamDay': breastExamDay,
        'weight': weight,
        'activity': activity,
        'activityMinutes': activityMinutes,
        'bedtime': bedtime,
        'bedtimeMinutes': bedtimeMinutes,
      };

  factory ReminderSettings.fromJson(Map<String, dynamic> j) => ReminderSettings(
        period: j['period'] as bool? ?? true,
        periodDaysBefore: (j['periodDaysBefore'] as num?)?.toInt() ?? 2,
        fertile: j['fertile'] as bool? ?? false,
        ovulation: j['ovulation'] as bool? ?? false,
        daily: j['daily'] as bool? ?? false,
        dailyMinutes: (j['dailyMinutes'] as num?)?.toInt() ?? 21 * 60,
        water: j['water'] as bool? ?? false,
        pill: j['pill'] as bool? ?? false,
        pillMinutes: (j['pillMinutes'] as num?)?.toInt() ?? 22 * 60,
        breastExam: j['breastExam'] as bool? ?? false,
        breastExamDay: (j['breastExamDay'] as num?)?.toInt() ?? 10,
        weight: j['weight'] as bool? ?? false,
        activity: j['activity'] as bool? ?? false,
        activityMinutes: (j['activityMinutes'] as num?)?.toInt() ?? 18 * 60,
        bedtime: j['bedtime'] as bool? ?? false,
        bedtimeMinutes: (j['bedtimeMinutes'] as num?)?.toInt() ?? 22 * 60 + 30,
      );
}

/// Fase del ciclo de un día.
enum Phase { period, follicular, fertile, ovulation, luteal }

/// Información calculada de un día concreto.
class DayInfo {
  final bool period; // periodo registrado
  final bool predictedPeriod;
  final bool fertile;
  final bool ovulation;
  final int? cycleDay;
  final Phase? phase;

  const DayInfo({
    this.period = false,
    this.predictedPeriod = false,
    this.fertile = false,
    this.ovulation = false,
    this.cycleDay,
    this.phase,
  });
}

/// Todo el estado de la app, guardado solo en el teléfono.
class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore instance = AppStore._();

  final Map<String, DayLog> logs = {};
  String name = '';

  /// Foto de perfil propia (nombre del archivo dentro de Documentos) o null.
  String? photoName;
  /// Avatar de la pantalla Hoy: '' = automático (su foto si tiene, si no
  /// la ilustración), 'photo' = su foto, o el nombre de una ilustración.
  String avatarId = '';
  String docsPath = '';

  String? get photoPath => photoName == null || docsPath.isEmpty ? null : '$docsPath/$photoName';
  String goal = 'track'; // track | conceive | pregnancy

  /// Objetivo «Seguir mi embarazo»: no se muestra nada de regla, fertilidad
  /// ni predicciones del ciclo.
  bool get pregnant => goal == 'pregnancy';

  /// Vuelve a pintar las pantallas (p. ej. al activar o caducar Premium).
  void refreshUi() => notifyListeners();

  /// Objetivo «Intento concebir»: se muestran test de ovulación, temperatura
  /// basal y moco cervical.
  bool get conceiving => goal == 'conceive';

  /// Primer día de la última regla antes del embarazo (para calcular la semana).
  DateTime? pregnancyStart;
  /// Bebés que espera: 0 = aún no lo sabe, 1 = uno, 2 = gemelos o mellizos.
  int pregnancyBabies = 0;
  String partnerName = '';
  int defaultCycle = 28;
  int defaultPeriod = 5;
  /// Días que pone la usuaria a mano (0 = la app aprende de sus registros).
  int manualCycle = 0;
  /// "Aprender de mis registros": si está apagado, siempre se usan las
  /// duraciones habituales que puso la usuaria.
  bool learnFromLogs = true;
  int manualPeriod = 0;
  int waterGoal = 8;
  bool onboarded = false;

  /// Mostrar el registro de relaciones sexuales (activado por defecto).
  bool showSex = true;

  /// Michi: mostrarlo, felicitar el santo y país para sus fiestas ('' = automático).
  bool showMichi = true;
  bool michiSaint = false;
  String michiCountry = '';
  bool michiSounds = true;
  /// Michi habla con voz (lee sus frases al tocarlo).
  bool michiVoice = true;
  /// Escenario de Michi: 'house' (su casa, por defecto) o 'map' (mundo de nubes).
  String michiScene = 'house';
  /// Color de la app: rosa (por defecto), lila, azul, menta o melocoton.
  String themeColor = 'rosa';
  /// Si Michi está oculto: enseñar el jardín de la flor en su lugar (o nada).
  bool showGarden = true;
  /// Ropa elegida en el armario ('' = automático).
  String michiOutfit = '';

  /// Modo perimenopausia y avisos discretos.
  bool perimenopause = false;
  bool discreetNotifs = false;
  List<String> customSymptoms = [];
  /// Respuestas de la bienvenida: síntomas habituales (salen primero al
  /// registrar), anticonceptivo y año de nacimiento (0 = no lo dijo).
  List<String> favSymptoms = [];
  String contraception = '';
  int birthYear = 0;
  ReminderSettings reminders = ReminderSettings();

  SharedPreferences? _prefs;

  /// Registros de día guardados en la cuenta de CicloPlus (Firestore).
  CloudBridge? _cloud;

  /// Conecta el diseño nuevo con la cuenta de la usuaria: carga sus días
  /// desde la nube y, si ya usaba CicloPlus, salta la bienvenida.
  /// Trae los días de la nube sin bloquear la pantalla. Solo sustituye los
  /// días que no se han tocado en el móvil mientras tanto.
  Future<void> _refreshFromCloud() async {
    final cloud = _cloud;
    if (cloud == null) return;
    final before = {for (final e in logs.entries) e.key: jsonEncode(e.value.toJson())};
    try {
      final cloudLogs = await cloud.loadAll().timeout(const Duration(seconds: 30));
      if (!identical(cloud, _cloud)) return; // cambió de usuario
      if (!cloud.loaded) {
        // Solo había copia local de Firestore: no se pisa lo del móvil.
        notifyListeners();
        throw StateError('offline');
      }
      var changed = false;
      for (final e in cloudLogs.entries) {
        final now = logs[e.key];
        final untouched = now == null ? !before.containsKey(e.key) : before[e.key] == jsonEncode(now.toJson());
        if (!untouched) continue;
        if (now == null || jsonEncode(now.toJson()) != jsonEncode(e.value.toJson())) {
          logs[e.key] = e.value;
          changed = true;
        }
      }
      if (changed) _recompute();
      notifyListeners(); // las tarjetas de CicloPlus ya tienen los datos de la nube
      // Sube lo que se haya cambiado en el móvil mientras se leía la nube.
      await _save();
    } catch (_) {
      // Reintenta en un minuto mientras siga siendo la misma sesión.
      Future.delayed(const Duration(minutes: 1), () {
        if (identical(cloud, _cloud) && !cloud.loaded) _refreshFromCloud();
      });
    }
  }

  Future<void> attachUser(String uid, {String? profileName}) async {
    if (_prefs == null) await load();
    // Móvil nuevo: trae de la nube los ajustes y el progreso de Michi.
    if (await SettingsSync.restoreIfNeeded(uid)) await load();
    _cloud = CloudBridge(uid);
    final p = _prefs!;
    final sameUser = p.getString('go_uid') == uid && logs.isNotEmpty;
    await p.setString('go_uid', uid);
    if (sameUser) {
      // Abre al momento con lo guardado en el móvil y trae la nube detrás.
      _refreshFromCloud();
    } else {
      try {
        final cloudLogs = await _cloud!.loadAll().timeout(const Duration(seconds: 12));
        logs
          ..clear()
          ..addAll(cloudLogs);
        if (!_cloud!.loaded) _refreshFromCloud(); // era la copia local: reintenta
      } catch (_) {
        // Sin conexión o lenta: se sigue intentando detrás.
        _refreshFromCloud();
      }
    }
    if (name.isEmpty && profileName != null && profileName.trim().isNotEmpty) name = profileName.trim();
    if (!onboarded && (logs.isNotEmpty || name.isNotEmpty)) onboarded = true;
    _recompute();
    notifyListeners();
    await _save();
    SettingsSync.start(uid);
  }

  /// Días tal como están en la nube (para las pantallas de CicloPlus).
  Map<String, Map<String, dynamic>> get cloudRaw => _cloud?.raw ?? const {};

  /// Guarda días que cambian desde pantallas de CicloPlus y refresca el diseño nuevo.
  Future<void> putCloudDays(Map<String, Map<String, dynamic>?> changes) async {
    if (_cloud == null || changes.isEmpty) return;
    try {
      await _cloud!.putRaw(changes);
    } catch (_) {}
    logs.clear();
    _cloud!.raw.forEach((k, v) {
      final l = CloudBridge.fromCloud(v);
      if (!l.isEmpty) logs[k] = l;
    });
    _recompute();
    notifyListeners();
  }

  /// Al cerrar sesión: olvida los días de esa cuenta en memoria.
  void detachUser() {
    SettingsSync.upload();
    SettingsSync.stop();
    _cloud = null;
    logs.clear();
    // Al cerrar sesión no se deja la copia de sus días en el móvil.
    _prefs?.remove('logs');
    _prefs?.remove('go_uid');
    _recompute();
    notifyListeners();
  }

  // Caché de cálculos.
  List<DateTime> _starts = [];
  Map<DateTime, int> _periodLengths = {};

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    refreshLh();
    logs.clear();
    final raw = p.getString('logs');
    if (raw != null) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        m.forEach((k, v) => logs[k] = DayLog.fromJson(v as Map<String, dynamic>));
      } catch (_) {}
    }
    name = p.getString('name') ?? '';
    photoName = p.getString('photoName');
    avatarId = p.getString('avatarId') ?? '';
    try {
      docsPath = (await getApplicationDocumentsDirectory()).path;
    } catch (_) {}
    goal = p.getString('goal') ?? 'track';
    final ps = p.getString('pregnancyStart');
    pregnancyStart = ps == null ? null : DateTime.tryParse(ps);
    pregnancyBabies = p.getInt('pregnancyBabies') ?? 0;
    partnerName = p.getString('partnerName') ?? '';
    defaultCycle = p.getInt('defaultCycle') ?? 28;
    defaultPeriod = p.getInt('defaultPeriod') ?? 5;
    manualCycle = p.getInt('manualCycle') ?? 0;
    manualPeriod = p.getInt('manualPeriod') ?? 0;
    learnFromLogs = p.getBool('learnFromLogs') ?? true;
    waterGoal = p.getInt('waterGoal') ?? 8;
    onboarded = p.getBool('onboarded') ?? false;
    showSex = p.getBool('showSex') ?? true;
    showMichi = p.getBool('showMichi') ?? true;
    michiSaint = p.getBool('michiSaint') ?? false;
    michiCountry = p.getString('michiCountry') ?? '';
    michiSounds = p.getBool('michiSounds') ?? true;
    michiVoice = p.getBool('michiVoice') ?? true;
    michiScene = p.getString('michiScene') ?? 'house';
    themeColor = p.getString('themeColor') ?? 'rosa';
    showGarden = p.getBool('showGarden') ?? true;
    michiOutfit = p.getString('michiOutfit') ?? '';
    perimenopause = p.getBool('perimenopause') ?? false;
    discreetNotifs = p.getBool('discreetNotifs') ?? false;
    customSymptoms = p.getStringList('customSymptoms') ?? [];
    favSymptoms = p.getStringList('favSymptoms') ?? [];
    contraception = p.getString('contraception') ?? '';
    birthYear = p.getInt('birthYear') ?? 0;
    final r = p.getString('reminders');
    if (r != null) {
      try {
        reminders = ReminderSettings.fromJson(jsonDecode(r) as Map<String, dynamic>);
      } catch (_) {}
    }
    _endedStarts = (p.getStringList('periodEndedStarts') ?? []).toSet();
    _recompute();
    await ensureOpenPeriod();
    notifyListeners();
  }

  /// Inicios de regla que la usuaria cerró a mano ("Se me ha terminado").
  Set<String> _endedStarts = {};

  /// Marca como terminada la regla en curso (o la que empieza en [start]).
  Future<void> markPeriodEnded([DateTime? start]) async {
    final st = start ?? lastStart;
    if (st == null) return;
    _endedStarts.add(dayKey(st));
    await (_prefs ?? await SharedPreferences.getInstance()).setStringList('periodEndedStarts', _endedStarts.toList());
  }

  /// Con "Me vino" solo se apunta el primer día. Como en otras apps de
  /// ciclo, mientras no diga "Se me ha terminado", la regla en curso sigue
  /// sumando días hasta su duración habitual (así la duración media no se
  /// queda en 1–2 días por no apuntar cada día).
  Future<void> ensureOpenPeriod() async {
    final st = lastStart;
    if (st == null || pregnant) return;
    if (_endedStarts.contains(dayKey(st))) return;
    final today = dateOnly(DateTime.now());
    final len = avgPeriod;
    if (daysBetween(st, today) >= len) return; // ya pasó: no tocamos el pasado
    var changed = false;
    for (var i = 1; i < len; i++) {
      final d = addDays(st, i);
      if (d.isAfter(today)) break;
      final l = logFor(d);
      if (l.flow == 0) {
        l.flow = i < 2 ? 3 : (i < len - 1 ? 2 : 1);
        logs[dayKey(d)] = l;
        changed = true;
      }
    }
    if (changed) await commit();
  }

  Future<void> _save() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    _prefs = p;
    final m = <String, dynamic>{};
    logs.forEach((k, v) {
      if (!v.isEmpty) m[k] = v.toJson();
    });
    // Copia en el móvil siempre (para abrir rápido y sin conexión);
    // con sesión iniciada, además se sube a la nube.
    await p.setString('logs', jsonEncode(m));
    if (_cloud != null) {
      try {
        await _cloud!.sync(logs);
      } catch (_) {}
    }
    await p.setString('name', name);
    await p.setString('avatarId', avatarId);
    if (photoName == null) {
      await p.remove('photoName');
    } else {
      await p.setString('photoName', photoName!);
    }
    await p.setString('goal', goal);
    await p.setInt('pregnancyBabies', pregnancyBabies);
    if (pregnancyStart == null) {
      await p.remove('pregnancyStart');
    } else {
      await p.setString('pregnancyStart', dayKey(pregnancyStart!));
    }
    await p.setString('partnerName', partnerName);
    await p.setInt('defaultCycle', defaultCycle);
    await p.setInt('defaultPeriod', defaultPeriod);
    await p.setInt('manualCycle', manualCycle);
    await p.setInt('manualPeriod', manualPeriod);
    await p.setBool('learnFromLogs', learnFromLogs);
    await p.setInt('waterGoal', waterGoal);
    await p.setBool('onboarded', onboarded);
    await p.setBool('showSex', showSex);
    await p.setBool('showMichi', showMichi);
    await p.setBool('michiSaint', michiSaint);
    await p.setString('michiCountry', michiCountry);
    await p.setBool('michiSounds', michiSounds);
    await p.setBool('michiVoice', michiVoice);
    await p.setString('michiScene', michiScene);
    await p.setString('themeColor', themeColor);
    await p.setBool('showGarden', showGarden);
    await p.setString('michiOutfit', michiOutfit);
    await p.setBool('perimenopause', perimenopause);
    await p.setBool('discreetNotifs', discreetNotifs);
    await p.setStringList('customSymptoms', customSymptoms);
    await p.setStringList('favSymptoms', favSymptoms);
    await p.setString('contraception', contraception);
    await p.setInt('birthYear', birthYear);
    await p.setString('reminders', jsonEncode(reminders.toJson()));
    SettingsSync.schedule();
  }

  /// Guarda y avisa a la interfaz (y a los recordatorios).
  Future<void> commit() async {
    _recompute();
    notifyListeners();
    await _save();
  }

  DayLog logFor(DateTime d) => logs[dayKey(d)]?.copy() ?? DayLog();

  Future<void> setLog(DateTime d, DayLog log) async {
    final k = dayKey(d);
    // Si quita la regla de un día de la regla en curso, es que ya terminó:
    // no la volvemos a alargar sola.
    if ((logs[k]?.flow ?? 0) > 0 && log.flow == 0) {
      final st = lastStart;
      if (st != null && !dateOnly(d).isBefore(st)) {
        _endedStarts.add(dayKey(st));
        await (_prefs ?? await SharedPreferences.getInstance()).setStringList('periodEndedStarts', _endedStarts.toList());
      }
    }
    if (log.isEmpty) {
      logs.remove(k);
    } else {
      logs[k] = log;
    }
    await commit();
  }

  Future<void> updateLog(DateTime d, void Function(DayLog l) change) async {
    final l = logFor(d);
    change(l);
    await setLog(d, l);
  }

  /// Marca un periodo completo empezando en [start].
  Future<void> addPeriod(DateTime start, {int? length}) async {
    final len = length ?? avgPeriod;
    _endedStarts.remove(dayKey(dateOnly(start)));
    for (var i = 0; i < len; i++) {
      final d = addDays(start, i);
      if (d.isAfter(dateOnly(DateTime.now()))) break;
      final l = logFor(d);
      if (l.flow == 0) l.flow = i < 2 ? 3 : (i < len - 1 ? 2 : 1);
      logs[dayKey(d)] = l;
    }
    await commit();
  }

  /// Quita el periodo que contiene [day].
  Future<void> removePeriodAround(DateTime day) async {
    var d = dateOnly(day);
    while ((logs[dayKey(addDays(d, -1))]?.flow ?? 0) > 0) {
      d = addDays(d, -1);
    }
    while ((logs[dayKey(d)]?.flow ?? 0) > 0) {
      final l = logs[dayKey(d)]!;
      l.flow = 0;
      if (l.isEmpty) logs.remove(dayKey(d));
      d = addDays(d, 1);
    }
    await commit();
  }

  Future<void> resetAll() async {
    logs.clear();
    _endedStarts = {};
    await (_prefs ?? await SharedPreferences.getInstance()).remove('periodEndedStarts');
    name = '';
    photoName = null;
    avatarId = '';
    goal = 'track';
    pregnancyStart = null;
    pregnancyBabies = 0;
    partnerName = '';
    defaultCycle = 28;
    defaultPeriod = 5;
    manualCycle = 0;
    manualPeriod = 0;
    learnFromLogs = true;
    waterGoal = 8;
    onboarded = false;
    showSex = true;
    showMichi = true;
    michiSaint = false;
    michiCountry = '';
    michiSounds = true;
    michiVoice = true;
    michiScene = 'house';
    themeColor = 'rosa';
    showGarden = true;
    michiOutfit = '';
    perimenopause = false;
    discreetNotifs = false;
    customSymptoms = [];
    favSymptoms = [];
    contraception = '';
    birthYear = 0;
    reminders = ReminderSettings();
    await commit();
  }

  // ───────────────────────── Cálculos del ciclo ─────────────────────────

  bool isPeriodDay(DateTime d) => (logs[dayKey(d)]?.flow ?? 0) > 0;

  void _recompute() {
    final days = logs.entries.where((e) => e.value.flow > 0).map((e) => parseKey(e.key)).toList()..sort();
    final starts = <DateTime>[];
    final lengths = <DateTime, int>{};
    DateTime? cur;
    DateTime? last;
    for (final d in days) {
      if (last == null || daysBetween(last, d) > 2) {
        cur = d;
        starts.add(d);
        lengths[d] = 1;
      } else {
        lengths[cur!] = daysBetween(cur!, d) + 1;
      }
      last = d;
    }
    _starts = starts;
    _periodLengths = lengths;
  }

  List<DateTime> get periodStarts => List.unmodifiable(_starts);

  /// Duraciones de los ciclos completos (entre inicios reales).
  List<int> get cycleLengths {
    final out = <int>[];
    for (var i = 1; i < _starts.length; i++) {
      final len = daysBetween(_starts[i - 1], _starts[i]);
      // Menos de 20 días casi siempre es un manchado entre reglas o un
      // registro de prueba, no un ciclo real: no debe cambiar la media.
      if (len >= 20 && len <= 60) out.add(len);
    }
    return out;
  }

  List<int> get periodLengths => _starts.map((s) => _periodLengths[s] ?? 1).toList();

  /// Ciclos/periodos registrados que hacen falta para dejar de usar las
  /// "duraciones habituales" que la usuaria puso a mano.
  static const int minLogsToLearn = 3;

  /// Duraciones de regla ya terminadas (la que sigue en curso no cuenta:
  /// si hoy es el día 2, aún no sabemos cuánto durará).
  List<int> get _finishedPeriodLengths {
    final today = dateOnly(DateTime.now());
    final out = <int>[];
    for (final st in _starts) {
      final len = _periodLengths[st] ?? 1;
      final lastDay = addDays(st, len - 1);
      if (daysBetween(lastDay, today) <= 1) continue; // en curso
      // 1–2 días suele ser manchado o una regla sin apuntar entera.
      if (len >= 3 && len <= 12) out.add(len);
    }
    return out;
  }

  /// La app va aprendiendo poco a poco: sin registros usa tu ajuste; con 1
  /// y 2 registros mezcla tu ajuste con lo registrado (cada vez pesa más
  /// lo registrado) y desde el 3.º usa solo tus registros.
  static int _blend(int setting, List<int> values, {required int outlierDays}) {
    if (values.isEmpty) return setting;
    final learned = _learned(values, outlierDays: outlierDays);
    final n = values.length;
    if (n >= minLogsToLearn) return learned;
    return ((setting * (minLogsToLearn - n) + learned * n) / minLogsToLearn).round();
  }

  /// Cuántos ciclos/reglas válidos lleva aprendidos (para enseñarlo).
  int get learnedCycles => learnFromLogs ? cycleLengths.length : 0;
  int get learnedPeriods => learnFromLogs ? _finishedPeriodLengths.length : 0;

  /// true si la duración del ciclo sale de los registros (y no del ajuste).
  bool get cycleFromLogs => manualCycle == 0 && learnFromLogs && cycleLengths.length >= minLogsToLearn;
  bool get periodFromLogs => manualPeriod == 0 && learnFromLogs && _finishedPeriodLengths.length >= minLogsToLearn;

  int get avgCycle {
    if (manualCycle > 0) return manualCycle;
    final c = cycleLengths;
    // Con pocos registros manda lo que la usuaria puso en "Mis duraciones
    // habituales" (un solo mes raro no debe cambiarle todo el calendario).
    if (!learnFromLogs) return defaultCycle;
    return _blend(defaultCycle, c, outlierDays: 10);
  }

  int get avgPeriod {
    if (manualPeriod > 0) return manualPeriod;
    final p = _finishedPeriodLengths;
    if (!learnFromLogs) return defaultPeriod;
    return _blend(defaultPeriod, p, outlierDays: 4);
  }

  /// Aprende de la propia usuaria: usa sus últimos 6 valores, da más peso a
  /// los más recientes (el cuerpo cambia) e ignora meses atípicos (enfermedad,
  /// estrés, viaje) cuando hay datos suficientes para saberlo.
  static int _learned(List<int> values, {required int outlierDays}) {
    var recent = values.length > 6 ? values.sublist(values.length - 6) : values;
    if (recent.length >= 4) {
      final sorted = [...recent]..sort();
      final median = sorted[sorted.length ~/ 2];
      final clean = recent.where((v) => (v - median).abs() <= outlierDays).toList();
      if (clean.length >= 3) recent = clean;
    }
    var sum = 0.0, weights = 0.0;
    for (var i = 0; i < recent.length; i++) {
      final w = (i + 1).toDouble(); // el más reciente pesa más
      sum += recent[i] * w;
      weights += w;
    }
    return (sum / weights).round();
  }

  /// null si aún no hay datos suficientes para saberlo.
  bool? get isRegular {
    final c = cycleLengths;
    if (c.length < 2) return null;
    final recent = c.length > 6 ? c.sublist(c.length - 6) : c;
    return recent.reduce(math.max) - recent.reduce(math.min) <= 7;
  }

  bool get hasData => _starts.isNotEmpty;

  DateTime? get lastStart {
    final today = dateOnly(DateTime.now());
    for (var i = _starts.length - 1; i >= 0; i--) {
      if (!_starts[i].isAfter(today)) return _starts[i];
    }
    return null;
  }

  /// Inicio previsto del próximo periodo (puede estar en el pasado si hay retraso).
  DateTime? get nextPeriod {
    final l = lastStart;
    if (l == null) return null;
    return addDays(l, avgCycle);
  }

  /// Días de retraso (>0) si el periodo previsto ya pasó.
  int get lateDays {
    final n = nextPeriod;
    if (n == null) return 0;
    final d = daysBetween(n, dateOnly(DateTime.now()));
    return d > 0 ? d : 0;
  }

  /// Inicios previstos futuros (el primero es [nextPeriod], o desde hoy si hay retraso).
  List<DateTime> predictedStarts([int count = 12]) {
    final n = nextPeriod;
    if (n == null) return [];
    final today = dateOnly(DateTime.now());
    var first = n;
    if (first.isBefore(today)) first = today;
    return [for (var i = 0; i < count; i++) addDays(first, avgCycle * i)];
  }

  /// Tests de ovulación positivos o con pico de LH (fecha del test).
  /// Se guardan en la pantalla "Test de ovulación" (SharedPreferences
  /// 'cicloplus_ovulation_tests'); [refreshLh] los vuelve a leer.
  List<DateTime> lhPositive = [];

  void refreshLh() {
    lhPositive = [];
    try {
      final raw = _prefs?.getString('cicloplus_ovulation_tests');
      if (raw != null && raw.isNotEmpty) {
        for (final e in jsonDecode(raw) as List) {
          final m = e as Map<String, dynamic>;
          if (m['result'] == 'negative') continue;
          final d = DateTime.tryParse(m['date'] as String? ?? '');
          if (d != null) lhPositive.add(dateOnly(d));
        }
        lhPositive.sort();
      }
    } catch (_) {}
    notifyListeners();
  }

  /// Ovulación según el test de LH del ciclo que empieza en [start]
  /// (el día siguiente al último test positivo de ese ciclo), o null.
  DateTime? lhOvulationFor(DateTime start) {
    DateTime? best;
    for (final t in lhPositive) {
      if (t.isBefore(start)) continue;
      if (daysBetween(start, t) > avgCycle + 10) continue;
      best = t;
    }
    return best == null ? null : addDays(best, 1);
  }

  /// Día de ovulación del ciclo que empieza en [start]: el del test de LH
  /// si lo hay, si no ciclo medio − 14.
  DateTime ovulationFor(DateTime start) => lhOvulationFor(start) ?? addDays(start, ovulationOffset);

  /// Días desde el inicio de la regla hasta la ovulación estimada: ciclo − 14
  /// (fase lútea típica), pero nunca dentro de la regla en ciclos muy cortos.
  int get ovulationOffset {
    final o = avgCycle - 14;
    final minO = avgPeriod + 1;
    final maxO = avgCycle - 3;
    if (maxO <= minO) return math.max(o, 0);
    return o.clamp(minO, maxO).toInt();
  }

  DateTime? get nextOvulation {
    final today = dateOnly(DateTime.now());
    final l = lastStart;
    if (l == null) return null;
    final cur = ovulationFor(l);
    if (!cur.isBefore(today)) return cur;
    final p = predictedStarts(2);
    for (final s in p) {
      final o = addDays(s, ovulationOffset);
      if (!o.isBefore(today)) return o;
    }
    return null;
  }

  /// Inicio del ciclo al que pertenece [d] (real o previsto).
  DateTime? cycleStartFor(DateTime d) {
    final day = dateOnly(d);
    DateTime? best;
    for (final s in _starts) {
      if (!s.isAfter(day)) best = s;
    }
    final today = dateOnly(DateTime.now());
    if (day.isAfter(today)) {
      for (final s in predictedStarts()) {
        if (!s.isAfter(day) && (best == null || s.isAfter(best))) best = s;
      }
    }
    return best;
  }

  int? cycleDayFor(DateTime d) {
    final s = cycleStartFor(d);
    if (s == null) return null;
    return daysBetween(s, d) + 1;
  }

  int? get cycleDayToday => cycleDayFor(DateTime.now());

  DayInfo infoFor(DateTime d) {
    final day = dateOnly(d);
    final today = dateOnly(DateTime.now());
    final period = isPeriodDay(day);
    // Embarazada: desde la última regla no hay predicciones, días fértiles
    // ni fases del ciclo.
    if (pregnant && (pregnancyStart == null || !day.isBefore(dateOnly(pregnancyStart!)))) {
      return DayInfo(period: period);
    }
    var predicted = false;
    // Días que faltan de la regla en curso (aún sin "Se me ha terminado").
    final ls = lastStart;
    if (!period && day.isAfter(today) && ls != null && !_endedStarts.contains(dayKey(ls)) && isPeriodDay(today)) {
      final diff = daysBetween(ls, day);
      if (diff >= 0 && diff < avgPeriod) predicted = true;
    }
    if (!predicted && !period && !day.isBefore(today)) {
      for (final s in predictedStarts()) {
        final diff = daysBetween(s, day);
        if (diff >= 0 && diff < avgPeriod) {
          predicted = true;
          break;
        }
      }
    }
    final start = cycleStartFor(day);
    int? cd;
    var fertile = false;
    var ovu = false;
    Phase? phase;
    if (start != null) {
      cd = daysBetween(start, day) + 1;
      final ovDay = daysBetween(start, ovulationFor(start)) + 1; // día del ciclo de la ovulación (test LH si lo hay)
      if (cd <= avgCycle + 10) {
        ovu = cd == ovDay;
        fertile = cd >= ovDay - 5 && cd <= ovDay + 1;
      }
      if (period || predicted || cd <= avgPeriod && (_periodLengths[start] ?? 0) >= cd) {
        phase = Phase.period;
      } else if (ovu) {
        phase = Phase.ovulation;
      } else if (fertile) {
        phase = Phase.fertile;
      } else if (cd < ovDay) {
        phase = Phase.follicular;
      } else {
        phase = Phase.luteal;
      }
      if (period || predicted) {
        fertile = false;
        ovu = false;
      }
    }
    return DayInfo(
      period: period,
      predictedPeriod: predicted,
      fertile: fertile,
      ovulation: ovu,
      cycleDay: cd,
      phase: phase,
    );
  }

  /// Días con algún registro, del más reciente al más antiguo.
  List<DateTime> get loggedDays {
    final l = logs.entries.where((e) => !e.value.isEmpty).map((e) => parseKey(e.key)).toList()
      ..sort((a, b) => b.compareTo(a));
    return l;
  }

  /// Variabilidad (± días) de los últimos ciclos, o null sin datos.
  int? get variability {
    final c = cycleLengths;
    if (c.length < 2) return null;
    final recent = c.length > 6 ? c.sublist(c.length - 6) : c;
    return ((recent.reduce(math.max) - recent.reduce(math.min)) / 2).ceil();
  }

  /// Semana de embarazo (1-42) o null.
  int? get pregnancyWeek {
    final st = pregnancyStart;
    if (st == null) return null;
    final d = daysBetween(st, dateOnly(DateTime.now()));
    if (d < 0) return 1;
    return (d ~/ 7 + 1).clamp(1, 42).toInt();
  }

  /// Semana de embarazo de un día concreto (o null si es antes de la última regla).
  int? pregnancyWeekOn(DateTime day) {
    final st = pregnancyStart;
    if (st == null) return null;
    final d = daysBetween(st, dateOnly(day));
    if (d < 0) return null;
    return (d ~/ 7 + 1).clamp(1, 42).toInt();
  }

  int get pregnancyDayOfWeek {
    final st = pregnancyStart;
    if (st == null) return 0;
    final d = daysBetween(st, dateOnly(DateTime.now()));
    return d < 0 ? 0 : d % 7;
  }

  /// Días con nota escrita, del más reciente al más antiguo.
  List<DateTime> get noteDays => logs.entries.where((e) => e.value.note.trim().isNotEmpty).map((e) => parseKey(e.key)).toList()
    ..sort((a, b) => b.compareTo(a));

  /// Cuántas veces se registró cada estado de ánimo (1-5).
  Map<int, int> get moodCounts {
    final m = <int, int>{};
    for (final l in logs.values) {
      if (l.mood > 0) m[l.mood] = (m[l.mood] ?? 0) + 1;
    }
    return m;
  }

  /// Media semanal (últimas [weeks] semanas, de la más antigua a la actual)
  /// de un valor por día; null si esa semana no tiene datos.
  List<double?> weekly(double? Function(DayLog l) value, {int weeks = 6}) {
    final today = dateOnly(DateTime.now());
    final out = <double?>[];
    for (var w = weeks - 1; w >= 0; w--) {
      var sum = 0.0;
      var n = 0;
      for (var i = 0; i < 7; i++) {
        final d = addDays(today, -(w * 7 + i));
        final l = logs[dayKey(d)];
        if (l == null) continue;
        final v = value(l);
        if (v != null) {
          sum += v;
          n++;
        }
      }
      out.add(n == 0 ? null : sum / n);
    }
    return out;
  }

  /// Cuántas veces se registró cada síntoma.
  Map<String, int> get symptomCounts {
    final m = <String, int>{};
    for (final l in logs.values) {
      for (final s in l.symptoms) {
        m[s] = (m[s] ?? 0) + 1;
      }
    }
    return m;
  }
}

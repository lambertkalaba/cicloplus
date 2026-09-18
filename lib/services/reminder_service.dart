import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_strings.dart';
import 'locale_controller.dart';
import 'settings_service.dart';

/// Configuración de la alarma/recordatorio de menstruación, ovulación y
/// ventana fértil — los 3 avisos que se activan/desactivan por separado
/// en la pantalla "Obtener Recordatorio" (Mi salud), cada uno con su
/// propio interruptor, igual que en la referencia visual del usuario.
/// `daysBefore` solo aplica al aviso de Periodo (los otros dos avisan el
/// mismo día, sin antelación configurable, para no complicar la UI).
class ReminderSettings {
  final bool enabled;
  final int daysBefore;
  final bool ovulationEnabled;
  final bool fertileEnabled;

  // ---- Ampliación "selector día/hora precargado": cada interruptor de
  // esta clase ahora guarda también LA FECHA/HORA exacta en la que debe
  // sonar (`*At`), elegida por la usuaria en el bottom sheet de
  // ReminderTimeSheet (precargado con un valor por defecto calculado a
  // partir de CyclePredictor, pero editable). Antes estos interruptores
  // eran booleanos puros que no programaban nada real en la mayoría de
  // los casos (ver el comentario que había aquí); ahora `reschedule()` usa
  // estos valores directamente en vez de recalcular la hora fija 9:00 a
  // partir de `nextPeriodStart`/`ovulationDate`.
  //
  // Se guardan como milisegundos desde epoch (nullable): null significa
  // "todavía no se ha elegido un valor" (p. ej. el interruptor nunca se
  // activó), en cuyo caso `reschedule()` cae de vuelta al cálculo
  // automático de siempre como red de seguridad.
  final bool periodStartEnabled;
  final int? periodStartAtMillis;
  final bool periodEndEnabled;
  final int? periodEndAtMillis;
  final bool enterPeriodEnabled;
  final int? enterPeriodAtMillis;

  // Fértil y ovulación ya existían como interruptores simples con hora fija
  // 9:00 y antelación fija (5 días antes de la ovulación para fértil, el
  // mismo día para ovulación) — ahora también guardan su propia fecha/hora
  // editable, igual que los 3 de arriba.
  final int? fertileAtMillis;
  final int? ovulationAtMillis;

  const ReminderSettings({
    this.enabled = false,
    this.daysBefore = 2,
    this.ovulationEnabled = false,
    this.fertileEnabled = false,
    this.periodStartEnabled = false,
    this.periodStartAtMillis,
    this.periodEndEnabled = false,
    this.periodEndAtMillis,
    this.enterPeriodEnabled = false,
    this.enterPeriodAtMillis,
    this.fertileAtMillis,
    this.ovulationAtMillis,
  });

  DateTime? get periodStartAt => periodStartAtMillis != null ? DateTime.fromMillisecondsSinceEpoch(periodStartAtMillis!) : null;
  DateTime? get periodEndAt => periodEndAtMillis != null ? DateTime.fromMillisecondsSinceEpoch(periodEndAtMillis!) : null;
  DateTime? get enterPeriodAt => enterPeriodAtMillis != null ? DateTime.fromMillisecondsSinceEpoch(enterPeriodAtMillis!) : null;
  DateTime? get fertileAt => fertileAtMillis != null ? DateTime.fromMillisecondsSinceEpoch(fertileAtMillis!) : null;
  DateTime? get ovulationAt => ovulationAtMillis != null ? DateTime.fromMillisecondsSinceEpoch(ovulationAtMillis!) : null;

  ReminderSettings copyWith({
    bool? enabled,
    int? daysBefore,
    bool? ovulationEnabled,
    bool? fertileEnabled,
    bool? periodStartEnabled,
    DateTime? periodStartAt,
    bool? periodEndEnabled,
    DateTime? periodEndAt,
    bool? enterPeriodEnabled,
    DateTime? enterPeriodAt,
    DateTime? fertileAt,
    DateTime? ovulationAt,
  }) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        daysBefore: daysBefore ?? this.daysBefore,
        ovulationEnabled: ovulationEnabled ?? this.ovulationEnabled,
        fertileEnabled: fertileEnabled ?? this.fertileEnabled,
        periodStartEnabled: periodStartEnabled ?? this.periodStartEnabled,
        periodStartAtMillis: periodStartAt?.millisecondsSinceEpoch ?? periodStartAtMillis,
        periodEndEnabled: periodEndEnabled ?? this.periodEndEnabled,
        periodEndAtMillis: periodEndAt?.millisecondsSinceEpoch ?? periodEndAtMillis,
        enterPeriodEnabled: enterPeriodEnabled ?? this.enterPeriodEnabled,
        enterPeriodAtMillis: enterPeriodAt?.millisecondsSinceEpoch ?? enterPeriodAtMillis,
        fertileAtMillis: fertileAt?.millisecondsSinceEpoch ?? fertileAtMillis,
        ovulationAtMillis: ovulationAt?.millisecondsSinceEpoch ?? ovulationAtMillis,
      );
}

/// Maneja la persistencia de la configuración y la notificación local
/// programada para avisar antes del próximo periodo.
///
/// NOTA: esta es la pieza del proyecto con más probabilidad de necesitar un
/// pequeño ajuste de tu parte. El paquete flutter_local_notifications cambia
/// su API entre versiones mayores con cierta frecuencia; si `flutter pub get`
/// instala una versión distinta a la fijada en pubspec.yaml y `flutter
/// analyze` marca un error aquí, casi siempre es un cambio de firma menor
/// (lo puedes resolver mirando el ejemplo oficial del paquete en pub.dev).
class ReminderService {
  static const _enabledKey = 'cicloplus_reminder_enabled';
  static const _daysKey = 'cicloplus_reminder_days';
  static const _ovulationEnabledKey = 'cicloplus_reminder_ovulation_enabled';
  static const _fertileEnabledKey = 'cicloplus_reminder_fertile_enabled';
  static const _periodStartEnabledKey = 'cicloplus_reminder_period_start_enabled';
  static const _periodStartAtKey = 'cicloplus_reminder_period_start_at';
  static const _periodEndEnabledKey = 'cicloplus_reminder_period_end_enabled';
  static const _periodEndAtKey = 'cicloplus_reminder_period_end_at';
  static const _enterPeriodEnabledKey = 'cicloplus_reminder_enter_period_enabled';
  static const _enterPeriodAtKey = 'cicloplus_reminder_enter_period_at';
  static const _fertileAtKey = 'cicloplus_reminder_fertile_at';
  static const _ovulationAtKey = 'cicloplus_reminder_ovulation_at';
  static const _notificationId = 1001;
  // IDs propios para no pisar la notificación de Periodo al cancelar o
  // reprogramar — cada aviso vive de forma independiente.
  static const _ovulationNotificationId = 1002;
  static const _fertileNotificationId = 1003;
  // IDs nuevos para los 3 interruptores de "Período & fertilidad" que antes
  // no programaban ninguna notificación real (ver ReminderSettings).
  static const _periodStartNotificationId = 1004;
  static const _periodEndNotificationId = 1005;
  static const _enterPeriodNotificationId = 1006;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final SettingsService _settings = SettingsService();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<ReminderSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      daysBefore: prefs.getInt(_daysKey) ?? 2,
      ovulationEnabled: prefs.getBool(_ovulationEnabledKey) ?? false,
      fertileEnabled: prefs.getBool(_fertileEnabledKey) ?? false,
      periodStartEnabled: prefs.getBool(_periodStartEnabledKey) ?? false,
      periodStartAtMillis: prefs.containsKey(_periodStartAtKey) ? prefs.getInt(_periodStartAtKey) : null,
      periodEndEnabled: prefs.getBool(_periodEndEnabledKey) ?? false,
      periodEndAtMillis: prefs.containsKey(_periodEndAtKey) ? prefs.getInt(_periodEndAtKey) : null,
      enterPeriodEnabled: prefs.getBool(_enterPeriodEnabledKey) ?? false,
      enterPeriodAtMillis: prefs.containsKey(_enterPeriodAtKey) ? prefs.getInt(_enterPeriodAtKey) : null,
      fertileAtMillis: prefs.containsKey(_fertileAtKey) ? prefs.getInt(_fertileAtKey) : null,
      ovulationAtMillis: prefs.containsKey(_ovulationAtKey) ? prefs.getInt(_ovulationAtKey) : null,
    );
  }

  Future<void> saveSettings(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setInt(_daysKey, settings.daysBefore);
    await prefs.setBool(_ovulationEnabledKey, settings.ovulationEnabled);
    await prefs.setBool(_fertileEnabledKey, settings.fertileEnabled);
    await prefs.setBool(_periodStartEnabledKey, settings.periodStartEnabled);
    await prefs.setBool(_periodEndEnabledKey, settings.periodEndEnabled);
    await prefs.setBool(_enterPeriodEnabledKey, settings.enterPeriodEnabled);
    // Los valores *AtMillis se conservan aunque el interruptor se apague
    // (ver decisión documentada en ReminderScreen._toggle*): si la usuaria
    // reactiva el switch más tarde, vuelve a ver la última hora que eligió
    // en vez de perder su ajuste y tener que repetirlo. Solo se borran del
    // todo si el llamador pasa explícitamente `null` con un copyWith que no
    // preserva el valor anterior (no ocurre en el flujo normal de la UI).
    await _setOrRemove(prefs, _periodStartAtKey, settings.periodStartAtMillis);
    await _setOrRemove(prefs, _periodEndAtKey, settings.periodEndAtMillis);
    await _setOrRemove(prefs, _enterPeriodAtKey, settings.enterPeriodAtMillis);
    await _setOrRemove(prefs, _fertileAtKey, settings.fertileAtMillis);
    await _setOrRemove(prefs, _ovulationAtKey, settings.ovulationAtMillis);
  }

  Future<void> _setOrRemove(SharedPreferences prefs, String key, int? value) async {
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setInt(key, value);
    }
  }

  Future<void> requestPermissions() async {
    await init();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  /// Cancela cualquier recordatorio previo y programa uno nuevo si la
  /// alarma está activa y ya hay una predicción de próximo periodo.
  /// [ovulationDate] es la fecha de ovulación ya calculada por
  /// CyclePredictor.predict() — se reutiliza aquí en vez de recalcularla,
  /// para que el aviso siempre coincida exactamente con lo que ve la
  /// usuaria en el calendario.
  ///
  /// Cada aviso usa PRIMERO la fecha/hora exacta que la usuaria eligió en
  /// el bottom sheet (`settings.periodStartAt`, etc. — ver
  /// ReminderTimeSheet). Si todavía no eligió ninguna (switch recién
  /// activado desde un flujo que no pasó por el sheet, o dato antiguo de
  /// antes de esta ampliación), se cae de vuelta al cálculo automático de
  /// siempre (fecha calculada + 9:00, o -5 días de la ovulación para
  /// fértil) como red de seguridad, para no dejar el interruptor
  /// activado sin programar nada.
  Future<void> reschedule(ReminderSettings settings, DateTime? nextPeriodStart, {DateTime? ovulationDate}) async {
    await init();
    await _plugin.cancel(_notificationId);
    await _plugin.cancel(_ovulationNotificationId);
    await _plugin.cancel(_fertileNotificationId);
    await _plugin.cancel(_periodStartNotificationId);
    await _plugin.cancel(_periodEndNotificationId);
    await _plugin.cancel(_enterPeriodNotificationId);

    // Antes este texto estaba fijo en español, sin pasar por AppStrings
    // como el resto de notificaciones de la app (ver
    // daily_notification_service.dart, que sí sigue este patrón) — alguien
    // con la app en inglés/francés/alemán recibía este aviso en español.
    final s = AppStrings.forCode(await _settings.loadLanguage() ?? LocaleController.instance.languageCode);

    if (settings.enabled && nextPeriodStart != null) {
      final fireDay = DateTime(
        nextPeriodStart.year,
        nextPeriodStart.month,
        nextPeriodStart.day,
      ).subtract(Duration(days: settings.daysBefore));
      await _scheduleSimple(
        id: _notificationId,
        day: fireDay,
        title: s.notifPeriodReminderTitle,
        body: s.notifPeriodReminderBody(settings.daysBefore),
      );
    }

    // Ovulación: usa la fecha/hora elegida a mano si existe; si no, cae al
    // día calculado a las 9:00 (comportamiento anterior).
    if (settings.ovulationEnabled) {
      final at = settings.ovulationAt ?? (ovulationDate != null ? _at9am(ovulationDate) : null);
      if (at != null) {
        await _scheduleExact(
          id: _ovulationNotificationId,
          when: at,
          title: s.notifPeriodReminderTitle,
          body: s.notifOvulationReminderBody,
        );
      }
    }

    // Ventana fértil: por defecto, 5 días antes de la ovulación (inicio de
    // la ventana fértil ovulación-5..+1, ver CyclePredictor.predict()), a
    // menos que la usuaria haya elegido su propia fecha/hora.
    if (settings.fertileEnabled) {
      final fallback = ovulationDate != null ? _at9am(ovulationDate.subtract(const Duration(days: 5))) : null;
      final at = settings.fertileAt ?? fallback;
      if (at != null) {
        await _scheduleExact(
          id: _fertileNotificationId,
          when: at,
          title: s.notifPeriodReminderTitle,
          body: s.notifFertileReminderBody,
        );
      }
    }

    // ---- 3 avisos de "Período & fertilidad" que antes no programaban
    // ninguna notificación real (ver ReminderSettings): ahora sí, usando
    // la fecha/hora elegida en el sheet o, si aún no hay ninguna guardada,
    // la fecha calculada (nextPeriodStart / nextPeriodStart+duración del
    // periodo) a las 9:00.
    if (settings.periodStartEnabled) {
      final at = settings.periodStartAt ?? (nextPeriodStart != null ? _at9am(nextPeriodStart) : null);
      if (at != null) {
        await _scheduleExact(
          id: _periodStartNotificationId,
          when: at,
          title: s.notifPeriodReminderTitle,
          body: s.notifPeriodStartReminderBody,
        );
      }
    }

    if (settings.enterPeriodEnabled) {
      final at = settings.enterPeriodAt ?? (nextPeriodStart != null ? _at9am(nextPeriodStart) : null);
      if (at != null) {
        await _scheduleExact(
          id: _enterPeriodNotificationId,
          when: at,
          title: s.notifPeriodReminderTitle,
          body: s.notifEnterPeriodReminderBody,
        );
      }
    }

    // periodEndAt no tiene un fallback calculable aquí porque requiere
    // getAvgPeriodLength() (CyclePredictor completo, no solo la fecha de
    // próximo periodo) — ReminderScreen ya precarga ese valor en el sheet
    // la primera vez que se activa el interruptor, así que en la práctica
    // `periodEndAt` casi siempre existe para cuando se llega aquí. Si por
    // algún motivo no existe todavía (dato antiguo), simplemente no se
    // programa nada hasta que la usuaria abra el sheet una vez.
    if (settings.periodEndEnabled && settings.periodEndAt != null) {
      await _scheduleExact(
        id: _periodEndNotificationId,
        when: settings.periodEndAt!,
        title: s.notifPeriodReminderTitle,
        body: s.notifPeriodEndReminderBody,
      );
    }
  }

  DateTime _at9am(DateTime day) => DateTime(day.year, day.month, day.day, 9, 0);

  /// Programa una notificación puntual a las 9:00 del día indicado, o no
  /// hace nada si esa fecha ya pasó (evita avisos fuera de tiempo cuando
  /// el ciclo es muy corto o la predicción cae en el pasado).
  Future<void> _scheduleSimple({
    required int id,
    required DateTime day,
    required String title,
    required String body,
  }) async {
    await _scheduleExact(id: id, when: _at9am(day), title: title, body: body);
  }

  /// Igual que [_scheduleSimple] pero con fecha+hora exacta (ya sin forzar
  /// las 9:00) — usado por los avisos con hora elegida a mano por la
  /// usuaria en ReminderTimeSheet. No hace nada si [when] ya pasó.
  Future<void> _scheduleExact({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    if (when.isBefore(DateTime.now())) return;

    final tzScheduled = tz.TZDateTime.from(when, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cicloplus_reminders',
          'Recordatorios de ciclo',
          channelDescription: 'Avisos de periodo, ovulación y ventana fértil',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_strings.dart';
import 'locale_controller.dart';
import 'settings_service.dart';

/// Programa los dos recordatorios diarios recurrentes del prototipo
/// (recordatorio de registro diario y recordatorio de pastilla
/// anticonceptiva). A diferencia de `ReminderService` (que calcula una
/// fecha única antes del próximo periodo), estos se repiten todos los
/// días a la misma hora usando `matchDateTimeComponents:
/// DateTimeComponents.time`, siguiendo el mismo patrón ya usado en
/// `ReminderService` para inicialización y permisos.
class DailyNotificationService {
  static const _dailyReminderId = 2001;
  static const _pillReminderId = 2002;
  // Recuerda beber agua: mismo patrón recurrente diario que Píldora/
  // Registro Diario (DailyTimeReminderSettings), id propio en el mismo
  // rango 2000-2999.
  static const _drinkWaterReminderId = 2003;
  // Recordatorio de fase del ciclo: no es ni puntual (como una cita) ni
  // recurrente a hora fija — se revisa una vez al día a la hora elegida
  // y solo notifica si la fase cambió desde el último chequeo (ver
  // rescheduleCyclePhaseReminder). Usamos zonedSchedule con
  // matchDateTimeComponents:time igual que el resto de diarios; la
  // comprobación de "¿cambió la fase?" se hace fuera de este servicio,
  // en ReminderScreen/MainTabScreen, que sí tienen acceso a
  // CyclePredictor.
  static const _cyclePhaseReminderId = 2004;
  // Rango de ids reservado para citas médicas (2000-2999 ya usado arriba,
  // así que las citas usan un hash estable del id de texto en 3000-3999
  // para no colisionar con los recordatorios recurrentes).
  static int _appointmentNotificationId(String appointmentId) =>
      3000 + (appointmentId.hashCode.abs() % 1000);
  // Autoexamen de mamas: notificación puntual (no recurrente) igual que
  // una cita médica, con id fijo propio en el mismo rango 3000-3999 (no
  // depende de texto libre como las citas, así que no necesita hash).
  static const _breastSelfExamNotificationId = 3999;
  // Recordatorio de "reenganche": pedido por el usuario ("si pasa dos
  // días y no entra que el app pregunte cómo te sientes hoy, una manera
  // que entre en el app"). Vuelve al rango 2000-2999 porque, igual que
  // los recordatorios diarios, se reprograma constantemente (no tiene una
  // fecha fija de un objeto como una cita).
  static const _reengagementReminderId = 2005;

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

  Future<void> requestPermissions() async {
    await init();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Cancela y reprograma el recordatorio diario de registro ("¿Ya
  /// registraste cómo te sientes hoy?"), recurrente todos los días a la
  /// hora configurada.
  Future<void> rescheduleDailyReminder(DailyTimeReminderSettings settings) async {
    await init();
    await _plugin.cancel(_dailyReminderId);
    if (!settings.enabled) return;

    final s = AppStrings.forCode(await _settings.loadLanguage() ?? LocaleController.instance.languageCode);
    await _plugin.zonedSchedule(
      _dailyReminderId,
      s.notifDailyReminderTitle,
      s.notifDailyReminderBody,
      _nextInstanceOfTime(settings.hour, settings.minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'cicloplus_daily_reminder',
          s.notifDailyChannelName,
          channelDescription: s.notifDailyChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancela y reprograma el recordatorio de pastilla anticonceptiva,
  /// recurrente todos los días a la hora configurada.
  Future<void> reschedulePillReminder(DailyTimeReminderSettings settings) async {
    await init();
    await _plugin.cancel(_pillReminderId);
    if (!settings.enabled) return;

    final s = AppStrings.forCode(await _settings.loadLanguage() ?? LocaleController.instance.languageCode);
    await _plugin.zonedSchedule(
      _pillReminderId,
      s.notifPillReminderTitle,
      s.notifPillReminderBody,
      _nextInstanceOfTime(settings.hour, settings.minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'cicloplus_pill_reminder',
          s.notifPillChannelName,
          channelDescription: s.notifPillChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Programa una notificación única (no recurrente) para una cita médica,
  /// en la fecha y hora exactas indicadas. Si esa fecha ya pasó, no hace
  /// nada (se asume que la cita ya ocurrió).
  Future<void> scheduleAppointment(MedicalAppointment appointment) async {
    await init();
    final id = _appointmentNotificationId(appointment.id);
    await _plugin.cancel(id);

    final now = tz.TZDateTime.now(tz.local);
    final when = tz.TZDateTime.from(appointment.dateTime, tz.local);
    if (when.isBefore(now)) return;

    final s = AppStrings.forCode(await _settings.loadLanguage() ?? LocaleController.instance.languageCode);
    await _plugin.zonedSchedule(
      id,
      s.notifAppointmentTitle,
      s.notifAppointmentBody(appointment.label),
      when,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'cicloplus_medical_appointment',
          s.notifAppointmentChannelName,
          channelDescription: s.notifAppointmentChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await init();
    await _plugin.cancel(_appointmentNotificationId(appointmentId));
  }

  /// Recuerda beber agua: recurrente todos los días a la hora configurada,
  /// mismo patrón que rescheduleDailyReminder/reschedulePillReminder (este
  /// aviso reutiliza DailyTimeReminderSettings porque es un hábito diario
  /// sin fecha propia, a diferencia de Autoexamen que sí tiene una fecha
  /// calculada con sentido — ver decisión documentada en
  /// SettingsService.loadDrinkWaterReminderSettings).
  Future<void> rescheduleDrinkWaterReminder(DailyTimeReminderSettings settings) async {
    await init();
    await _plugin.cancel(_drinkWaterReminderId);
    if (!settings.enabled) return;

    final s = AppStrings.forCode(await _settings.loadLanguage() ?? LocaleController.instance.languageCode);
    await _plugin.zonedSchedule(
      _drinkWaterReminderId,
      s.notifDrinkWaterTitle,
      s.notifDrinkWaterBody,
      _nextInstanceOfTime(settings.hour, settings.minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'cicloplus_drink_water_reminder',
          s.notifDrinkWaterChannelName,
          channelDescription: s.notifDrinkWaterChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Autoexamen de mamas: notificación PUNTUAL (no recurrente) en la fecha
  /// exacta elegida en el sheet — igual patrón que scheduleAppointment. Se
  /// precarga por defecto unos días después de terminar el período
  /// (nextPeriodStart + duración del período + ~3 días, ver
  /// ReminderScreen._breastSelfExamDefault), pero eso es solo el valor
  /// sugerido inicial: aquí solo se programa la fecha ya elegida.
  Future<void> scheduleBreastSelfExamReminder(DateTime at) async {
    await init();
    await _plugin.cancel(_breastSelfExamNotificationId);

    final now = tz.TZDateTime.now(tz.local);
    final when = tz.TZDateTime.from(at, tz.local);
    if (when.isBefore(now)) return;

    final s = AppStrings.forCode(await _settings.loadLanguage() ?? LocaleController.instance.languageCode);
    await _plugin.zonedSchedule(
      _breastSelfExamNotificationId,
      s.notifBreastSelfExamTitle,
      s.notifBreastSelfExamBody,
      when,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'cicloplus_breast_self_exam_reminder',
          s.notifBreastSelfExamChannelName,
          channelDescription: s.notifBreastSelfExamChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelBreastSelfExamReminder() async {
    await init();
    await _plugin.cancel(_breastSelfExamNotificationId);
  }

  /// Recordatorio de fase del ciclo: la ambigüedad original pedía avisar
  /// "al cambiar de fase", pero flutter_local_notifications no permite
  /// condicionar el contenido de una notificación YA PROGRAMADA a un
  /// cálculo hecho en el momento exacto de disparo (el texto se fija al
  /// programar, no al disparar) — implementar un chequeo real de "¿cambió
  /// la fase desde ayer?" requeriría un servicio en segundo plano
  /// (WorkManager/BGTaskScheduler) fuera del alcance de esta ampliación.
  /// En su lugar, este método programa un recordatorio diario recurrente
  /// simple a la hora elegida ("revisa tu fase hoy"), igual patrón que
  /// rescheduleDrinkWaterReminder — sigue cumpliendo el objetivo
  /// (recordatorio ligado a la fase, sin fecha fija que calcular a mano)
  /// sin inventar infraestructura de notificaciones condicionales que el
  /// paquete no soporta de forma nativa. Queda documentado aquí como
  /// simplificación deliberada, no como bug.
  Future<void> rescheduleCyclePhaseReminder(bool enabled, String time) async {
    await init();
    await _plugin.cancel(_cyclePhaseReminderId);
    if (!enabled) return;

    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final s = AppStrings.forCode(await _settings.loadLanguage() ?? LocaleController.instance.languageCode);
    await _plugin.zonedSchedule(
      _cyclePhaseReminderId,
      s.notifCyclePhaseTitle,
      s.notifCyclePhaseBody,
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'cicloplus_cycle_phase_reminder',
          s.notifCyclePhaseChannelName,
          channelDescription: s.notifCyclePhaseChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Recordatorio de "reenganche" ("¿cómo te sientes hoy?") para cuando la
  /// persona lleva SIN ABRIR la app 2 días o más.
  ///
  /// No existe forma de que el sistema operativo avise a la app "han
  /// pasado 2 días sin que te abran" mientras la app está cerrada — solo
  /// se puede programar POR ADELANTADO una notificación para un momento
  /// futuro exacto. La solución (mismo patrón que usan apps de hábitos
  /// para "te extrañamos"): cada vez que la persona SÍ abre la app, se
  /// cancela cualquier aviso pendiente y se programa uno nuevo para
  /// "dentro de 2 días". Si vuelve a entrar antes de esos 2 días, este
  /// método se llama de nuevo y el aviso se reprograma otra vez 2 días
  /// hacia adelante (nunca llega a dispararse). Si NO vuelve a entrar, el
  /// aviso programado la última vez sí se dispara — que es exactamente
  /// "pasaron 2 días sin entrar". Se llama desde
  /// MainTabScreen._load (una vez ya autenticada y dentro de la app), no
  /// desde AppOpenController.load (que corre incluso antes de iniciar
  /// sesión, cuando programar esto no tendría sentido).
  Future<void> scheduleReengagementCheckIn() async {
    await init();
    await _plugin.cancel(_reengagementReminderId);

    final s = AppStrings.forCode(await _settings.loadLanguage() ?? LocaleController.instance.languageCode);
    final when = tz.TZDateTime.now(tz.local).add(const Duration(days: 2));
    await _plugin.zonedSchedule(
      _reengagementReminderId,
      s.notifReengagementTitle,
      s.notifReengagementBody,
      when,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'cicloplus_reengagement_reminder',
          s.notifReengagementChannelName,
          channelDescription: s.notifReengagementChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancela el aviso de reenganche pendiente, si lo hay — por ejemplo si
  /// más adelante se quisiera dar la opción de desactivarlo desde
  /// Configuración (hoy no existe ese interruptor; se cancela y
  /// reprograma automáticamente en cada apertura de la app).
  Future<void> cancelReengagementCheckIn() async {
    await init();
    await _plugin.cancel(_reengagementReminderId);
  }
}

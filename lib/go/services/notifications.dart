import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/store.dart';
import 'pill.dart';
import '../strings.dart';
import '../widgets/cycle_plus.dart';
import '../widgets/michi_events.dart';
import '../widgets/michi_logic.dart';

/// Recordatorios locales (sin internet). Se reprograman todos cada vez que
/// cambian los datos o los ajustes.
class Notifier {
  Notifier._();
  static final Notifier instance = Notifier._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Busca una zona horaria con el mismo desfase que el teléfono ahora y
  /// dentro de medio año (así coincide también el horario de verano).
  tz.Location _guessLocal() {
    final now = DateTime.now();
    final later = now.add(const Duration(days: 182));
    final o1 = now.timeZoneOffset;
    final o2 = later.timeZoneOffset;
    bool matches(tz.Location l) =>
        tz.TZDateTime.from(now, l).timeZoneOffset == o1 && tz.TZDateTime.from(later, l).timeZoneOffset == o2;
    const preferred = [
      'Europe/Madrid',
      'Europe/London',
      'Atlantic/Canary',
      'America/Mexico_City',
      'America/Bogota',
      'America/Lima',
      'America/Argentina/Buenos_Aires',
      'America/Santiago',
      'America/Caracas',
      'America/New_York',
      'America/Chicago',
      'America/Denver',
      'America/Los_Angeles',
      'Africa/Kinshasa',
      'Africa/Lagos',
    ];
    for (final name in preferred) {
      try {
        final l = tz.getLocation(name);
        if (matches(l)) return l;
      } catch (_) {}
    }
    for (final l in tz.timeZoneDatabase.locations.values) {
      if (matches(l)) return l;
    }
    return tz.UTC;
  }

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(_guessLocal());
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings, onDidReceiveNotificationResponse: _onResponse);
      _ready = true;
      // Si la app se abrió pulsando un botón de la notificación.
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final resp = launch?.notificationResponse;
      if ((launch?.didNotificationLaunchApp ?? false) && resp != null) await _onResponse(resp);
    } catch (e) {
      debugPrint('Notifier init: $e');
    }
  }

  /// Aviso suelto que no se borra al reprogramar (p. ej. el temporizador de
  /// la compresa). Ids 4000+.
  Future<void> once(int id, String title, String body, DateTime when) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id);
      final t = tz.TZDateTime.from(when, tz.local);
      if (t.isBefore(tz.TZDateTime.now(tz.local))) return;
      await _plugin.zonedSchedule(id, DiscreetNotif.title(title), DiscreetNotif.body(body), t, _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
    } catch (e) {
      debugPrint('Notifier once: $e');
    }
  }

  Future<void> cancelOnce(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
      }
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
    } catch (e) {
      debugPrint('Notifier permission: $e');
    }
    return false;
  }

  /// Botones de las notificaciones: registro rápido sin entrar en pantallas.
  Future<void> _onResponse(NotificationResponse r) async {
    try {
      final today = dateOnly(DateTime.now());
      if (r.actionId == 'pill_taken') {
        await PillTracker.setTaken(today, true);
      } else if (r.actionId == 'period_started') {
        await AppStore.instance.addPeriod(today);
      }
    } catch (e) {
      debugPrint('Notifier action: $e');
    }
  }

  NotificationDetails _withAction(String id, String label) => NotificationDetails(
        android: AndroidNotificationDetails(
          'cicloplus_go_reminders',
          'Recordatorios',
          largeIcon: DiscreetNotif.largeIcon,
          channelDescription: 'Recordatorios de CicloPlus',
          importance: Importance.high,
          priority: Priority.high,
          actions: [AndroidNotificationAction(id, label, showsUserInterface: true, cancelNotification: true)],
        ),
        iOS: const DarwinNotificationDetails(),
      );

  NotificationDetails get _details => NotificationDetails(
        android: AndroidNotificationDetails(
          'cicloplus_go_reminders',
          'Recordatorios',
          largeIcon: DiscreetNotif.largeIcon,
          channelDescription: 'Recordatorios de CicloPlus',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  bool _firstRun = true;
  final Set<int> _scheduled = {};

  Future<void> _at(int id, String title, String body, DateTime when, {DateTimeComponents? repeat, NotificationDetails? details}) async {
    _scheduled.add(id);
    final t = tz.TZDateTime(tz.local, when.year, when.month, when.day, when.hour, when.minute);
    if (repeat == null && t.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id,
      DiscreetNotif.title(title),
      DiscreetNotif.body(body),
      t,
      details ?? _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: repeat,
    );
  }

  DateTime _nextTime(int minutes) {
    final now = DateTime.now();
    var d = DateTime(now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
    if (d.isBefore(now)) d = d.add(const Duration(days: 1));
    return d;
  }

  Future<void> reschedule() async {
    if (!_ready) return;
    final s = AppStore.instance;
    final r = s.reminders;
    try {
      // Solo se borran los avisos de esta parte (ids 1-299) y los antiguos de
      // periodo/ovulación (1001-1006). Los de Configuración (2001+, citas
      // 3000+) los gestiona la pantalla de Configuración de CicloPlus.
      final toCancel = _firstRun ? [for (var i = 1; i < 300; i++) i, for (var i = 1001; i <= 1006; i++) i] : _scheduled.toList();
      _firstRun = false;
      _scheduled.clear();
      for (final i in toCancel) {
        await _plugin.cancel(i);
      }
      var id = 1;
      // Con Michi activado, el aviso diario lo manda él ("tengo hambre") y
      // no llega los días que ya has registrado.
      if (s.showMichi) {
        final today = dateOnly(DateTime.now());
        final mins = r.daily ? r.dailyMinutes : 20 * 60;
        final streak = MichiLogic.streak;
        for (var i = 0; i < 7; i++) {
          final d = addDays(today, i);
          if (MichiLogic.logged(d)) continue;
          final body = streak > 0
              ? (i == 0
                  ? tr('Llevas {} días seguidos 🔥 Registra tu día para no perder la racha.',
                          '{} days in a row 🔥 Log your day to keep your streak.')
                      .replaceFirst('{}', '$streak')
                  : tr('¡No pierdas tu racha! 🔥 Registra tu día y dame de comer.', "Don't lose your streak! 🔥 Log your day and feed me."))
              : tr('Registra tu día y dame de comer 🐾', 'Log your day and feed me 🐾');
          await _at(220 + i, tr('Tengo hambre 🍽️', "I'm hungry 🍽️"), body, DateTime(d.year, d.month, d.day, mins ~/ 60, mins % 60));
        }
      } else if (r.daily) {
        await _at(id++, tr('¿Cómo ha ido tu día? 🌸', 'How was your day? 🌸'),
            tr('Registra tus síntomas y tu ánimo en 10 segundos.', 'Log your symptoms and mood in 10 seconds.'), _nextTime(r.dailyMinutes),
            repeat: DateTimeComponents.time);
      }
      id = 10;
      if (r.pill) {
        await _at(id++, tr('Hora de tu píldora 💊', 'Pill time 💊'), tr('No olvides tomar tu píldora de hoy.', "Don't forget today's pill."),
            _nextTime(r.pillMinutes),
            repeat: DateTimeComponents.time,
            details: _withAction('pill_taken', '✅ ${tr('Tomada', 'Taken')}'));
      }
      id = 20;
      if (r.water) {
        for (final h in [9, 11, 13, 15, 17, 19, 21]) {
          await _at(id++, tr('Bebe agua 💧', 'Drink water 💧'), tr('Un vaso de agua ahora te sentará genial.', 'A glass of water now will feel great.'),
              _nextTime(h * 60),
              repeat: DateTimeComponents.time);
        }
      }
      id = 40;
      if (r.activity) {
        await _at(id++, tr('Hora de moverte 🏃‍♀️', 'Time to move 🏃‍♀️'),
            tr('Un paseo o unos estiramientos te sentarán genial.', 'A walk or some stretching will feel great.'), _nextTime(r.activityMinutes),
            repeat: DateTimeComponents.time);
      }
      if (r.bedtime) {
        await _at(id++, tr('Hora de dormir 🌙', 'Bedtime 🌙'),
            tr('Desconecta y descansa: tu cuerpo lo agradecerá.', 'Unplug and rest: your body will thank you.'), _nextTime(r.bedtimeMinutes),
            repeat: DateTimeComponents.time);
      }
      if (r.weight) {
        final now = DateTime.now();
        var d = DateTime(now.year, now.month, now.day + ((DateTime.monday - now.weekday + 7) % 7), 9);
        if (d.isBefore(now)) d = d.add(const Duration(days: 7));
        await _at(id++, tr('Registro de peso ⚖️', 'Weight check ⚖️'),
            tr('Apunta tu peso de esta semana.', "Log this week's weight."), d,
            repeat: DateTimeComponents.dayOfWeekAndTime);
      }
      id = 30;
      if (r.breastExam) {
        final now = DateTime.now();
        var d = DateTime(now.year, now.month, r.breastExamDay.clamp(1, 28).toInt(), 10);
        if (d.isBefore(now)) d = DateTime(now.year, now.month + 1, r.breastExamDay.clamp(1, 28).toInt(), 10);
        await _at(id++, tr('Autoexamen de mamas 🎀', 'Breast self-exam 🎀'),
            tr('Dedica 5 minutos a tu autoexamen mensual.', 'Take 5 minutes for your monthly self-exam.'), d,
            repeat: DateTimeComponents.dayOfMonthAndTime);
      }
      id = 100;
      final starts = s.predictedStarts(4);
      for (final st in starts) {
        if (r.period) {
          final d = addDays(st, -r.periodDaysBefore);
          await _at(
              id++,
              tr('Tu periodo se acerca 🩸', 'Your period is coming 🩸'),
              tr('Previsto en ${r.periodDaysBefore} ${daysWord(r.periodDaysBefore)}. ¡Ten todo a mano!',
                  'Expected in ${r.periodDaysBefore} ${daysWord(r.periodDaysBefore)}. Be prepared!'),
              DateTime(d.year, d.month, d.day, 9),
              details: _withAction('period_started', '🩸 ${tr('Me vino la regla', 'My period started')}'));
        }
        final ovu = addDays(st, -14);
        if (r.fertile) {
          final f = addDays(ovu, -5);
          await _at(id++, tr('Empieza tu ventana fértil 🌱', 'Your fertile window starts 🌱'),
              tr('Hoy empiezan tus días fértiles estimados.', 'Your estimated fertile days start today.'), DateTime(f.year, f.month, f.day, 9));
          final e = addDays(ovu, 1);
          await _at(id++, tr('Termina tu ventana fértil 🌿', 'Your fertile window ends 🌿'),
              tr('Hoy es el último día fértil estimado.', 'Today is your last estimated fertile day.'), DateTime(e.year, e.month, e.day, 9));
        }
        if (r.ovulation) {
          await _at(id++, tr('Día de ovulación estimado 🥚', 'Estimated ovulation day 🥚'),
              tr('Hoy es tu día de ovulación estimado.', 'Today is your estimated ovulation day.'), DateTime(ovu.year, ovu.month, ovu.day, 9));
        }
      }
      // Michi: fiestas del país, santo y aniversarios de los próximos 60 días.
      id = 200;
      if (s.showMichi) {
        final today = dateOnly(DateTime.now());
        for (var i = 1; i <= 60 && id < 215; i++) {
          final d = addDays(today, i);
          final e = MichiEvents.nameDay(d) ?? MichiEvents.anniversary(d) ?? MichiEvents.holiday(d);
          if (e == null) continue;
          await _at(id++, '${e.emoji} ${tr('Mensaje de Michi', 'A message from Michi')}', e.text, DateTime(d.year, d.month, d.day, 10));
        }
      }
    } catch (e) {
      debugPrint('Notifier reschedule: $e');
    }
  }
}

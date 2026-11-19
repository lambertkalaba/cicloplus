import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/home_widget_service.dart';
import '../services/photo_service.dart';
import '../services/reminder_service.dart';
import '../services/settings_service.dart';
import '../services/theme_controller.dart';
import 'data/store.dart';
import 'strings.dart';

/// Pasos para que la actualización a este diseño sea invisible para quien
/// ya usaba CicloPlus: conserva sus recordatorios, su nombre y mantiene el
/// widget al día.
class Upgrade {
  Upgrade._();

  static const _doneKey = 'go_upgrade_reminders_v1';

  static const _sceneKey = 'go_upgrade_scene_v1';

  /// Una sola vez: quien ya usaba CicloPlus antes de esta versión sigue
  /// viendo su flor del jardín (no aparece Michi de golpe). Las cuentas
  /// nuevas empiezan con la casa de Michi. Si ya había elegido algo en este
  /// diseño, se respeta.
  static Future<void> migrateScene() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_sceneKey) == true) return;
    await prefs.setBool(_sceneKey, true);
    if (prefs.containsKey('showMichi')) return;
    try {
      final dates = await SettingsService().loadAppOpenDates();
      final limit = DateTime.now().subtract(const Duration(days: 5));
      final old = dates.any((d) {
        final t = DateTime.tryParse(d);
        return t != null && t.isBefore(limit);
      });
      if (!old) return;
      final s = AppStore.instance;
      s.showMichi = false;
      s.showGarden = true;
      await s.commit();
    } catch (_) {}
  }

  static const _photoKey = 'go_upgrade_photo_v1';

  /// Una sola vez: si en la versión anterior tenía una foto de perfil en
  /// "Mi cuenta", pasa a ser la foto de Yo (así hay una sola foto).
  static Future<void> migratePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_photoKey) == true) return;
    await prefs.setBool(_photoKey, true);
    try {
      final s = AppStore.instance;
      if (s.photoPath != null || s.docsPath.isEmpty) return;
      final bytes = PhotoService.decodeDataUrl(await SettingsService().loadProfilePhoto());
      if (bytes == null || bytes.isEmpty) return;
      final name = 'perfil_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File('${s.docsPath}/$name').writeAsBytes(bytes);
      s.photoName = name;
      await s.commit();
    } catch (_) {}
  }

  static int _minutes(String hhmm, int fallback) {
    final p = hhmm.split(':');
    if (p.length != 2) return fallback;
    final h = int.tryParse(p[0]), m = int.tryParse(p[1]);
    if (h == null || m == null) return fallback;
    return h * 60 + m;
  }

  /// Una sola vez: copia los recordatorios que tenía activados en la
  /// versión anterior y quita los avisos antiguos para que no lleguen
  /// repetidos.
  static Future<void> migrateReminders() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_doneKey) == true) return;
    final s = AppStore.instance;
    final r = s.reminders;
    try {
      final old = await ReminderService().loadSettings();
      if (old.enabled) {
        r.period = true;
        r.periodDaysBefore = old.daysBefore;
      }
      if (old.ovulationEnabled) r.ovulation = true;
      if (old.fertileEnabled) r.fertile = true;
    } catch (_) {}
    final settings = SettingsService();
    try {
      final daily = await settings.loadDailyReminderSettings();
      if (daily.enabled) {
        r.daily = true;
        r.dailyMinutes = _minutes(daily.time, r.dailyMinutes);
      }
      final pill = await settings.loadPillReminderSettings();
      if (pill.enabled) {
        r.pill = true;
        r.pillMinutes = _minutes(pill.time, r.pillMinutes);
      }
      final water = await settings.loadDrinkWaterReminderSettings();
      if (water.enabled) r.water = true;
      if (await settings.loadBreastSelfExamReminderEnabled()) r.breastExam = true;
    } catch (_) {}
    // Avisos de la versión anterior que ahora gestiona la pestaña Recordatorios.
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      for (final id in [1001, 1002, 1003, 1004, 1005, 1006, 2001, 2002, 2003, 2004, 3999]) {
        await plugin.cancel(id);
      }
    } catch (_) {}
    await s.commit();
    await prefs.setBool(_doneKey, true);
  }

  /// El diseño nuevo tiene un solo color (rosa): las pantallas que vienen
  /// de la versión anterior también se ven en rosa.
  static Future<void> fixTheme() async {
    try {
      if (ThemeController.instance.themeId != 'pink') await ThemeController.instance.setThemeId('pink');
    } catch (_) {}
  }

  /// Nombre: el mismo en "Yo" y en la cuenta de CicloPlus.
  static String? _lastName;
  static void syncProfileName() {
    final n = AppStore.instance.name.trim();
    if (n == _lastName) return;
    _lastName = n;
    if (n.isNotEmpty) SettingsService().saveProfileName(n);
  }

  /// Widget de la pantalla de inicio (día del ciclo y días hasta la regla).
  static String? _lastWidget;
  static void updateWidget() {
    final s = AppStore.instance;
    final day = s.cycleDayToday;
    final next = s.nextPeriod;
    final cycleLine = day == null ? tr('Registra tu periodo', 'Log your period') : tr('Día $day del ciclo', 'Cycle day $day');
    var periodLine = '';
    if (next != null) {
      final d = daysBetween(dateOnly(DateTime.now()), next);
      if (d > 0) {
        periodLine = tr('Periodo en $d ${d == 1 ? 'día' : 'días'}', 'Period in $d ${d == 1 ? 'day' : 'days'}');
      } else if (d == 0) {
        periodLine = tr('El periodo llega hoy', 'Period due today');
      }
    }
    final key = '$cycleLine|$periodLine|${s.logs[dayKey(DateTime.now())]?.isEmpty ?? true}|${s.showMichi}|${dayKey(DateTime.now())}';
    if (key == _lastWidget) return;
    _lastWidget = key;
    try {
      HomeWidgetService().update(cycleDayLine: cycleLine, periodLine: periodLine);
    } catch (_) {}
  }
}

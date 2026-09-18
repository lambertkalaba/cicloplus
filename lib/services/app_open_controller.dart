import 'package:flutter/foundation.dart';

import 'settings_service.dart';

/// Mantiene en memoria, como un `ChangeNotifier` global (mismo patrón que
/// `ThemeController`/`LocaleController`), el conjunto de días en que se
/// abrió la app — usado por [gardenStageIndex] (garden_stage.dart) para
/// que la tarjeta "Tu jardín" de Hoy se marchite según los días SIN
/// ENTRAR a la app, no según los días sin registrar síntomas.
///
/// `load()` se llama una única vez al arrancar la app (ver main.dart),
/// ANTES de construir ninguna pantalla: marca automáticamente hoy como
/// "abierto" (vía `SettingsService.recordAppOpenToday`) y deja el
/// conjunto completo cacheado en memoria en [openDates], para que
/// today_screen.dart/register_screen.dart puedan leerlo de forma
/// síncrona al construir la tarjeta del jardín.
class AppOpenController extends ChangeNotifier {
  AppOpenController._();
  static final AppOpenController instance = AppOpenController._();

  final SettingsService _settings = SettingsService();

  Set<String> _openDates = <String>{};
  Set<String> get openDates => _openDates;

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    await _settings.recordAppOpenToday();
    _openDates = await _settings.loadAppOpenDates();
    _loaded = true;
    notifyListeners();
  }

  /// Ver [SettingsService.seedGardenBloomOnAccountCreation] — se llama justo
  /// después de crear una cuenta nueva. A diferencia de [load], esto puede
  /// pasar en cualquier momento de la sesión (justo tras el registro, con la
  /// app ya corriendo y [load] ya ejecutado antes), así que hace falta
  /// releer el conjunto completo desde SharedPreferences y avisar a los
  /// listeners (today_screen.dart) para que la tarjeta del jardín se
  /// redibuje ya en floración máxima sin esperar a un reinicio de la app.
  Future<void> seedBloomForNewAccount() async {
    await _settings.seedGardenBloomOnAccountCreation();
    _openDates = await _settings.loadAppOpenDates();
    notifyListeners();
  }
}

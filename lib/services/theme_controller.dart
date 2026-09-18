import 'package:flutter/foundation.dart';

import 'settings_service.dart';

/// Controla el "Color de app" actual (kAppThemes) como un ChangeNotifier
/// global, igual que LocaleController hace con el idioma — para que
/// MaterialApp reconstruya su ThemeData al instante cuando la persona
/// cambia de color en Configuración, sin tener que reiniciar la app.
///
/// Esto es necesario porque `AppColors.primary/primaryDark/...` son
/// constantes fijas (rosa) que sirven de valor por defecto, pero el
/// `ThemeData` real de MaterialApp (AppBar, status bar del sistema,
/// colorScheme) se construye a partir del tema elegido, no de esas
/// constantes — la mayoría de pantallas ya reciben el color correcto vía
/// `themeId`/`themeById()` pasado explícitamente, pero el AppBar y la
/// barra de estado del sistema los pinta Flutter automáticamente a partir
/// del `ThemeData` global, así que ese sí necesita reconstruirse aquí.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  final SettingsService _settings = SettingsService();

  String _themeId = 'pink';
  String get themeId => _themeId;

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _themeId = await _settings.loadThemeId();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeId(String id) async {
    if (_themeId == id) return;
    _themeId = id;
    notifyListeners();
    await _settings.saveThemeId(id);
  }
}

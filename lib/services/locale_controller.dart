import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'settings_service.dart';

/// Idiomas disponibles en la app. El código ('es', 'en', 'fr', 'de') es
/// el mismo que se usa como clave en AppStrings y se guarda tal cual en
/// el dispositivo.
class AppLanguage {
  final String code;
  final String nativeName;
  final String flag;

  const AppLanguage({required this.code, required this.nativeName, required this.flag});
}

const List<AppLanguage> kAppLanguages = [
  AppLanguage(code: 'es', nativeName: 'Español', flag: '🇪🇸'),
  AppLanguage(code: 'en', nativeName: 'English', flag: '🇬🇧'),
  AppLanguage(code: 'fr', nativeName: 'Français', flag: '🇫🇷'),
  AppLanguage(code: 'de', nativeName: 'Deutsch', flag: '🇩🇪'),
  AppLanguage(code: 'ru', nativeName: 'Русский', flag: '🇷🇺'),
  AppLanguage(code: 'ar', nativeName: 'العربية', flag: '🇸🇦'),
  AppLanguage(code: 'hi', nativeName: 'हिन्दी', flag: '🇮🇳'),
  AppLanguage(code: 'bn', nativeName: 'বাংলা', flag: '🇧🇩'),
  AppLanguage(code: 'pt', nativeName: 'Português', flag: '🇧🇷'),
];

/// Controla el idioma actual de la app como un ChangeNotifier global,
/// para que cualquier pantalla se reconstruya al instante cuando la
/// persona cambia de idioma en Configuración — sin tener que reiniciar
/// la app. El valor elegido se persiste en el dispositivo.
class LocaleController extends ChangeNotifier {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  final SettingsService _settings = SettingsService();

  String _languageCode = 'es';
  String get languageCode => _languageCode;

  bool _loaded = false;

  /// Idiomas soportados por la app — cualquier otro código de sistema cae
  /// a español por defecto.
  static const _supportedCodes = {'es', 'en', 'fr', 'de', 'ru', 'ar', 'hi', 'bn', 'pt'};

  /// Si la persona nunca eligió un idioma a mano, usamos el idioma del
  /// dispositivo (si es uno de los soportados); si no, español.
  String _detectSystemLanguage() {
    final deviceCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return _supportedCodes.contains(deviceCode) ? deviceCode : 'es';
  }

  Future<void> load() async {
    if (_loaded) return;
    final saved = await _settings.loadLanguage();
    _languageCode = saved ?? _detectSystemLanguage();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    notifyListeners();
    await _settings.saveLanguage(code);
  }
}

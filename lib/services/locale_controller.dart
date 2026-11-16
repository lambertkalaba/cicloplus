import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../l10n/extra_i18n.dart';
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
  AppLanguage(code: 'zh', nativeName: '中文 (简体)', flag: '🇨🇳'),
  AppLanguage(code: 'zh-TW', nativeName: '中文 (繁體)', flag: '🇹🇼'),
  AppLanguage(code: 'ja', nativeName: '日本語', flag: '🇯🇵'),
  AppLanguage(code: 'ko', nativeName: '한국어', flag: '🇰🇷'),
  AppLanguage(code: 'id', nativeName: 'Bahasa Indonesia', flag: '🇮🇩'),
  AppLanguage(code: 'tr', nativeName: 'Türkçe', flag: '🇹🇷'),
  AppLanguage(code: 'vi', nativeName: 'Tiếng Việt', flag: '🇻🇳'),
  AppLanguage(code: 'it', nativeName: 'Italiano', flag: '🇮🇹'),
  AppLanguage(code: 'ur', nativeName: 'اردو', flag: '🇵🇰'),
  AppLanguage(code: 'fa', nativeName: 'فارسی', flag: '🇮🇷'),
  AppLanguage(code: 'ta', nativeName: 'தமிழ்', flag: '🇮🇳'),
  AppLanguage(code: 'te', nativeName: 'తెలుగు', flag: '🇮🇳'),
  AppLanguage(code: 'mr', nativeName: 'मराठी', flag: '🇮🇳'),
  AppLanguage(code: 'pa', nativeName: 'ਪੰਜਾਬੀ', flag: '🇮🇳'),
  AppLanguage(code: 'gu', nativeName: 'ગુજરાતી', flag: '🇮🇳'),
  AppLanguage(code: 'kn', nativeName: 'ಕನ್ನಡ', flag: '🇮🇳'),
  AppLanguage(code: 'ml', nativeName: 'മലയാളം', flag: '🇮🇳'),
  AppLanguage(code: 'th', nativeName: 'ไทย', flag: '🇹🇭'),
  AppLanguage(code: 'pl', nativeName: 'Polski', flag: '🇵🇱'),
  AppLanguage(code: 'uk', nativeName: 'Українська', flag: '🇺🇦'),
  AppLanguage(code: 'nl', nativeName: 'Nederlands', flag: '🇳🇱'),
  AppLanguage(code: 'ro', nativeName: 'Română', flag: '🇷🇴'),
  AppLanguage(code: 'el', nativeName: 'Ελληνικά', flag: '🇬🇷'),
  AppLanguage(code: 'cs', nativeName: 'Čeština', flag: '🇨🇿'),
  AppLanguage(code: 'hu', nativeName: 'Magyar', flag: '🇭🇺'),
  AppLanguage(code: 'sv', nativeName: 'Svenska', flag: '🇸🇪'),
  AppLanguage(code: 'da', nativeName: 'Dansk', flag: '🇩🇰'),
  AppLanguage(code: 'fi', nativeName: 'Suomi', flag: '🇫🇮'),
  AppLanguage(code: 'sk', nativeName: 'Slovenčina', flag: '🇸🇰'),
  AppLanguage(code: 'he', nativeName: 'עברית', flag: '🇮🇱'),
  AppLanguage(code: 'sw', nativeName: 'Kiswahili', flag: '🇰🇪'),
  AppLanguage(code: 'ms', nativeName: 'Bahasa Melayu', flag: '🇲🇾'),
  AppLanguage(code: 'fil', nativeName: 'Filipino', flag: '🇵🇭'),
  AppLanguage(code: 'am', nativeName: 'አማርኛ', flag: '🇪🇹'),
  AppLanguage(code: 'my', nativeName: 'မြန်မာ', flag: '🇲🇲'),
  AppLanguage(code: 'az', nativeName: 'Azərbaycan', flag: '🇦🇿'),
  AppLanguage(code: 'uz', nativeName: "O'zbek", flag: '🇺🇿'),
  AppLanguage(code: 'kk', nativeName: 'Қазақ', flag: '🇰🇿'),
  AppLanguage(code: 'ne', nativeName: 'नेपाली', flag: '🇳🇵'),
  AppLanguage(code: 'si', nativeName: 'සිංහල', flag: '🇱🇰'),
  AppLanguage(code: 'zu', nativeName: 'isiZulu', flag: '🇿🇦'),
];

/// '<idioma>' o '<idioma>-<PAÍS>' (p. ej. 'zh-TW') como Locale de Flutter.
Locale localeFromCode(String code) {
  final p = code.split('-');
  return p.length > 1 ? Locale(p[0], p[1]) : Locale(p[0]);
}

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
  static final _supportedCodes = {for (final l in kAppLanguages) l.code};

  /// Si la persona nunca eligió un idioma a mano, usamos el idioma del
  /// dispositivo (si es uno de los soportados); si no, español.
  String _detectSystemLanguage() {
    final loc = WidgetsBinding.instance.platformDispatcher.locale;
    final deviceCode = loc.languageCode;
    if (deviceCode == 'zh' && (loc.countryCode == 'TW' || loc.countryCode == 'HK' || loc.scriptCode == 'Hant')) {
      return 'zh-TW';
    }
    return _supportedCodes.contains(deviceCode) ? deviceCode : 'es';
  }

  Future<void> load() async {
    if (_loaded) return;
    final saved = await _settings.loadLanguage();
    _languageCode = saved ?? _detectSystemLanguage();
    if (!_supportedCodes.contains(_languageCode)) _languageCode = 'es';
    await ExtraI18n.load(_languageCode);
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    await ExtraI18n.load(code);
    _languageCode = code;
    notifyListeners();
    await _settings.saveLanguage(code);
  }
}

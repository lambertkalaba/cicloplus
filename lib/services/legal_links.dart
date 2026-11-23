/// Enlaces públicos a la política de privacidad y los términos de uso
/// (antes vivían en settings_screen.dart).
const String kPrivacyPolicyUrl = 'https://cicloplus-9a957.web.app/privacidad.html';

/// URL pública de los términos de uso, publicada vía Firebase Hosting
/// junto a la política de privacidad (mismo hosting, mismo estilo).
/// Igual que arriba, es la versión en inglés y sirve de último recurso.
const String kTermsOfUseUrl = 'https://cicloplus-9a957.web.app/terminos.html';

/// Idiomas de la app para los que existe una traducción publicada de la
/// política de privacidad y los términos de uso (además del inglés, que
/// es ahora el idioma por defecto del sitio). Debe reflejar los archivos
/// realmente subidos a Firebase Hosting (privacidad-XX.html / terminos-XX.html).
const Set<String> _kLegalDocLanguages = {'es', 'fr', 'de', 'ru', 'ar', 'hi', 'bn', 'pt'};

/// Devuelve la URL de la política de privacidad en el idioma indicado.
/// Si ese idioma es inglés o no tiene traducción publicada, cae a la
/// versión en inglés (idioma por defecto del sitio).
/// Idiomas con política de privacidad publicada (privacidad-XX.html).
const Set<String> _kPrivacyLanguages = {
  'am', 'ar', 'az', 'bn', 'cs', 'da', 'de', 'el', 'es', 'fa', 'fi', 'fil', 'fr', 'gu', 'ha', 'he', 'hi', 'hu',
  'id', 'it', 'ja', 'kk', 'kn', 'ko', 'ln', 'ml', 'mr', 'ms', 'my', 'ne', 'nl', 'om', 'pa', 'pl', 'pt', 'ro',
  'ru', 'si', 'sk', 'sv', 'sw', 'ta', 'te', 'th', 'tr', 'uk', 'ur', 'uz', 'vi', 'wo', 'yo', 'zh', 'zh-TW', 'zu',
};

String privacyPolicyUrlFor(String languageCode) {
  final c = languageCode.replaceAll('_', '-');
  if (_kPrivacyLanguages.contains(c)) {
    return 'https://cicloplus-9a957.web.app/privacidad-$c.html';
  }
  if (c.startsWith('zh-') && (c.contains('TW') || c.contains('HK') || c.contains('Hant'))) {
    return 'https://cicloplus-9a957.web.app/privacidad-zh-TW.html';
  }
  final base = c.split('-').first;
  if (_kPrivacyLanguages.contains(base)) {
    return 'https://cicloplus-9a957.web.app/privacidad-$base.html';
  }
  return kPrivacyPolicyUrl;
}


/// Igual que [privacyPolicyUrlFor] pero para los términos de uso.
String termsOfUseUrlFor(String languageCode) {
  if (_kLegalDocLanguages.contains(languageCode)) {
    return 'https://cicloplus-9a957.web.app/terminos-$languageCode.html';
  }
  return kTermsOfUseUrl;
}

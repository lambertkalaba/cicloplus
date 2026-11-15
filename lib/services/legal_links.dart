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
String privacyPolicyUrlFor(String languageCode) {
  if (_kLegalDocLanguages.contains(languageCode)) {
    return 'https://cicloplus-9a957.web.app/privacidad-$languageCode.html';
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

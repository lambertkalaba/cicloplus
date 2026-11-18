import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';

import '../data/store.dart';
import '../strings.dart';

/// La voz de Michi: lee en voz alta sus frases y chistes en el idioma de la
/// app, con un tono agudo de gatito. Solo habla cuando la usuaria toca a
/// Michi o pide algo (nunca sola), y se puede apagar en Configuración.
class MichiVoice {
  MichiVoice._();

  static final FlutterTts _tts = FlutterTts();
  static bool _ready = false;
  static String? _lang;

  static const _locales = {
    'es': 'es-ES',
    'en': 'en-US',
    'pt': 'pt-BR',
    'fr': 'fr-FR',
    'de': 'de-DE',
    'it': 'it-IT',
    'zh': 'zh-CN',
    'zh-TW': 'zh-TW',
    'ln': 'fr-FR',
    'wo': 'fr-FR',
  };

  static bool get enabled => AppStore.instance.showMichi && AppStore.instance.michiVoice;

  static Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    try {
      await _tts.setPitch(1.75);
      await _tts.setSpeechRate(0.47);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(false);
    } catch (_) {}
    if (Platform.isIOS) {
      try {
        await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.ambient, [IosTextToSpeechAudioCategoryOptions.mixWithOthers]);
      } catch (_) {}
    }
  }

  static String _clean(String t) => t
      .replaceAll(RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}\u{200D}\u{20E3}]', unicode: true), '')
      .replaceAll('…', '. ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Michi dice [text] (si la voz está activada).
  static Future<void> say(String text) async {
    if (!enabled) return;
    final t = _clean(text);
    if (t.isEmpty) return;
    try {
      await _init();
      final code = L.lang;
      if (_lang != code) {
        _lang = code;
        final loc = _locales[code] ?? code;
        try {
          await _tts.setLanguage(loc);
        } catch (_) {}
      }
      await _tts.stop();
      await _tts.speak(t);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

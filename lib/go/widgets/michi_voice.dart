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
      // Antes 1.75: tan agudo sonaba a robot. Un poco más agudo que una voz
      // normal queda simpático sin distorsionarse.
      await _tts.setPitch(1.25);
      await _tts.setSpeechRate(0.5);
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
        await _pickBestVoice(loc);
      }
      await _tts.stop();
      await _tts.speak(t);
    } catch (_) {}
  }

  /// Elige la voz más natural instalada para ese idioma (las "network" y de
  /// calidad alta de Google suenan mucho menos robóticas que la básica).
  static Future<void> _pickBestVoice(String loc) async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return;
      final want = loc.toLowerCase().replaceAll('_', '-');
      final lang = want.split('-').first;
      Map<String, String>? best;
      var bestScore = -1;
      for (final v in raw) {
        if (v is! Map) continue;
        final name = '${v['name'] ?? ''}';
        final locale = '${v['locale'] ?? ''}'.toLowerCase().replaceAll('_', '-');
        if (name.isEmpty || !locale.startsWith(lang)) continue;
        var score = 0;
        if (locale == want) score += 100;
        final q = int.tryParse('${v['quality'] ?? ''}') ?? 300;
        score += q ~/ 10; // 500 = muy alta
        final n = name.toLowerCase();
        if (n.contains('network')) score += 20;
        if (n.contains('enhanced') || n.contains('premium') || n.contains('neural')) score += 30;
        if (n.contains('female') || n.contains('mujer')) score += 10;
        if (n.contains('male') && !n.contains('female')) score -= 10;
        if ('${v['network_required']}' == '1' || '${v['network_required']}' == 'true') score -= 5;
        if (score > bestScore) {
          bestScore = score;
          best = {'name': name, 'locale': '${v['locale']}'};
        }
      }
      if (best != null) await _tts.setVoice(best);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

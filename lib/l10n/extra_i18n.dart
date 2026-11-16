import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Idiomas extra (más allá de los 9 que viven dentro del código).
///
/// Las traducciones están en `assets/l10n/<código>.json` como una lista
/// alineada con `assets/l10n/_keys.json` (cada clave es "español␟inglés").
/// Si una frase no está traducida en el idioma elegido, se muestra en inglés.
class ExtraI18n {
  ExtraI18n._();

  static const sep = '␟';

  static String? _lang;
  static List<String>? _keys;
  static Map<String, int>? _index;
  static List<dynamic>? _values;
  static List<_Tpl>? _templates;
  static final Map<String, String?> _cache = {};

  /// Idioma cargado ahora mismo (null si es uno de los 9 internos).
  static String? get lang => _lang;

  static Future<void> load(String code) async {
    if (_lang == code && _values != null) return;
    _cache.clear();
    try {
      if (_keys == null) {
        final raw = await rootBundle.loadString('assets/l10n/_keys.json');
        _keys = (jsonDecode(raw) as List).cast<String>();
        _index = {for (var i = 0; i < _keys!.length; i++) _keys![i]: i};
        _templates = [
          for (var i = 0; i < _keys!.length; i++)
            if (_keys![i].contains('{}')) _Tpl(i, _keys![i]),
        ];
      }
      final raw = await rootBundle.loadString('assets/l10n/$code.json');
      _values = jsonDecode(raw) as List;
      _lang = code;
    } catch (_) {
      // Sin archivo para ese idioma: se verá en inglés.
      _values = null;
      _lang = code;
    }
  }

  /// Traducción de la frase (es, en) al idioma cargado, o null si no la hay.
  static String? t(String es, String? en) {
    final values = _values;
    if (values == null) return null;
    final key = '$es$sep${en ?? ''}';
    if (_cache.containsKey(key)) return _cache[key];
    String? out;
    final i = _index![key];
    if (i != null && i < values.length) {
      final v = values[i];
      if (v is String && v.isNotEmpty) out = v;
    } else {
      // Frases con datos ("Día 12 del ciclo"): plantilla con huecos {}.
      for (final tpl in _templates!) {
        final m = tpl.re.firstMatch(key);
        if (m == null) continue;
        if (tpl.index >= values.length) break;
        final v = values[tpl.index];
        if (v is! String || v.isEmpty) break;
        // Los valores salen de la parte en español (los primeros huecos).
        final groups = [for (var g = 1; g <= tpl.esHoles; g++) m.group(g) ?? ''];
        var k = 0;
        out = v.replaceAllMapped('{}', (_) => k < groups.length ? groups[k++] : '');
        break;
      }
    }
    _cache[key] = out;
    return out;
  }
}

class _Tpl {
  _Tpl(this.index, String key)
      : esHoles = '{}'.allMatches(key.split(ExtraI18n.sep).first).length,
        re = RegExp('^${key.split('{}').map(RegExp.escape).join('(.*?)')}\$', dotAll: true);
  final int index;
  final int esHoles;
  final RegExp re;
}

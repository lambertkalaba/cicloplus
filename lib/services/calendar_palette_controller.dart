import 'package:flutter/foundation.dart';

import 'settings_service.dart';

/// Controla la paleta de colores del calendario (Periodo/Previsto/Fértil/
/// Hoy/Ovulación) elegida en Configuración, como un ChangeNotifier global —
/// mismo patrón que ThemeController con el "Color de app", pero
/// independiente de él: el "Color de app" solo pinta el AppBar y acentos
/// del resto de pantallas, esto pinta específicamente el grid del
/// calendario y su leyenda (ver `CalendarGrid`, `CalendarScreen`).
class CalendarPaletteController extends ChangeNotifier {
  CalendarPaletteController._();
  static final CalendarPaletteController instance = CalendarPaletteController._();

  final SettingsService _settings = SettingsService();

  String _paletteId = 'pastel';
  String get paletteId => _paletteId;

  // ---- Paleta 'custom': a diferencia de las paletas predefinidas
  // (const, en kCalendarPalettes), esta se construye en tiempo de
  // ejecución a partir de lo que la usuaria eligió en la hoja
  // "Personalizar colores" — se mantiene en memoria aquí (cargada una
  // vez en `load()`) para que `palette` pueda devolverla sin await. ----
  CalendarPaletteOption? _customPalette;
  CalendarPaletteOption get customPalette => _customPalette ?? calendarPaletteById('pastel');

  CalendarPaletteOption get palette =>
      _paletteId == 'custom' ? customPalette : calendarPaletteById(_paletteId);

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _paletteId = await _settings.loadCalendarPaletteId();
    _customPalette = await _settings.loadCustomCalendarPalette();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setPaletteId(String id) async {
    if (_paletteId == id) return;
    _paletteId = id;
    notifyListeners();
    await _settings.saveCalendarPaletteId(id);
  }

  /// Guarda una paleta personalizada completa (los 7 colores elegidos a
  /// mano) y la deja activa de inmediato — usado por la hoja
  /// "Personalizar colores" en Configuración al pulsar "Guardar".
  Future<void> setCustomPalette(CalendarPaletteOption custom) async {
    _customPalette = custom;
    _paletteId = 'custom';
    notifyListeners();
    await _settings.saveCustomCalendarPalette(custom);
    await _settings.saveCalendarPaletteId('custom');
  }
}

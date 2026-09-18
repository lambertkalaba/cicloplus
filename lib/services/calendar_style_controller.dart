import 'package:flutter/foundation.dart';

import 'settings_service.dart';

/// Controla qué DISEÑO de calendario se usa en la pestaña "Calendario"
/// ('clasico' = `CalendarGrid` de siempre, 'elegante' = el nuevo
/// `CalendarGridElegant`), como un ChangeNotifier global — mismo patrón
/// que `CalendarPaletteController` (que elige los COLORES), pero
/// independiente de él: se puede combinar cualquier paleta de colores con
/// cualquiera de los dos estilos.
class CalendarStyleController extends ChangeNotifier {
  CalendarStyleController._();
  static final CalendarStyleController instance = CalendarStyleController._();

  final SettingsService _settings = SettingsService();

  String _styleId = 'elegante';
  String get styleId => _styleId;

  // Forma ('square' | 'circle' | 'raya') y relleno ('filled' | 'outline')
  // de las marcas de día — se aplican en los 3 estilos (Clásico/Elegante/
  // iOS). Independientes entre sí y de `styleId`/`CalendarPaletteController`:
  // la usuaria puede combinar cualquier forma con cualquier relleno,
  // cualquier estilo y cualquier paleta de color, a su gusto.
  String _markerShape = 'raya';
  String get markerShape => _markerShape;

  String _markerFill = 'outline';
  String get markerFill => _markerFill;

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _styleId = await _settings.loadCalendarStyleId();
    _markerShape = await _settings.loadCalendarMarkerShape();
    _markerFill = await _settings.loadCalendarMarkerFill();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setStyleId(String id) async {
    if (_styleId == id) return;
    _styleId = id;
    notifyListeners();
    await _settings.saveCalendarStyleId(id);
  }

  Future<void> setMarkerShape(String shape) async {
    if (_markerShape == shape) return;
    _markerShape = shape;
    notifyListeners();
    await _settings.saveCalendarMarkerShape(shape);
  }

  Future<void> setMarkerFill(String fill) async {
    if (_markerFill == fill) return;
    _markerFill = fill;
    notifyListeners();
    await _settings.saveCalendarMarkerFill(fill);
  }
}

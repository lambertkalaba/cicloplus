import 'package:flutter/foundation.dart';

import 'settings_service.dart';

/// Controla qué imagen se usa para la ilustración de la pareja en la
/// tarjeta "Sincroniza tu ritmo y tus momentos con tu pareja" (pantalla
/// Hoy), como un ChangeNotifier global — mismo patrón que
/// CalendarPaletteController, pero para la apariencia (tono de piel) de
/// la pareja dibujada. Puramente visual/local del dispositivo.
class CoupleIllustrationController extends ChangeNotifier {
  CoupleIllustrationController._();
  static final CoupleIllustrationController instance = CoupleIllustrationController._();

  final SettingsService _settings = SettingsService();

  String _illustrationId = 'mixta';
  String get illustrationId => _illustrationId;
  CoupleIllustrationOption get illustration => coupleIllustrationById(_illustrationId);

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _illustrationId = await _settings.loadCoupleIllustrationId();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setIllustrationId(String id) async {
    if (_illustrationId == id) return;
    _illustrationId = id;
    notifyListeners();
    await _settings.saveCoupleIllustrationId(id);
  }
}

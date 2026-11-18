import 'package:home_widget/home_widget.dart';

import '../go/data/store.dart';
import '../go/strings.dart' show tr;
import '../go/widgets/michi_events.dart';
import '../go/widgets/michi_logic.dart';

/// Actualiza el widget real de pantalla de inicio (Android, vía el
/// paquete `home_widget` y `CicloPlusWidgetProvider` en el lado nativo)
/// con dos líneas de texto ya traducidas desde Dart (día de ciclo y
/// cuenta atrás al próximo periodo) — el lado nativo (Kotlin) solo pinta
/// lo que se le manda, así toda la lógica de idioma sigue viviendo en
/// AppStrings como en el resto de la app, sin duplicar traducciones en
/// strings.xml.
///
/// Todo el acceso es best-effort y silencioso, igual que
/// `HealthSyncService`: si el plugin no está disponible en la
/// plataforma actual (iOS sin extensión de widget configurada, o
/// cualquier error de canal), la app sigue funcionando con normalidad
/// sin que el widget se actualice.
class HomeWidgetService {
  /// Debe coincidir exactamente con el nombre de la clase Kotlin en
  /// android/app/src/main/kotlin/.../CicloPlusWidgetProvider.kt.
  static const _androidProviderName = 'CicloPlusWidgetProvider';

  static const _keyCycleDayLine = 'cicloplus_widget_cycle_day_line';
  static const _keyPeriodLine = 'cicloplus_widget_period_line';
  static const _keyMichi = 'cicloplus_widget_michi';
  static const _keyMichiLine = 'cicloplus_widget_michi_line';

  static const _poses = {
    'michi_happy', 'cat_wave', 'michi_period', 'michi_bed', 'michi_flowers', 'michi_snack', 'michi_party', 'michi_scarf',
    'michi_crown', 'michi_collar', 'michi_calm', 'michi_tired', 'michi_pain', 'michi_motivated', 'michi_letter', 'michi_heart',
    'cat_house', 'michi_return', 'michi_flower',
  };

  /// Postura y frase de Michi para el widget ('' si Michi está oculto).
  (String, String) _michi() {
    try {
      if (!AppStore.instance.showMichi) return ('', '');
      final fed = MichiLogic.logged(DateTime.now());
      final event = MichiEvents.today();
      var pose = fed ? (event?.pose ?? MichiLogic.pose(fedToday: true)) : 'cat_wave';
      if (!_poses.contains(pose)) pose = 'michi_happy';
      final line = !fed
          ? tr('Michi tiene hambre: registra tu día 🐟', 'Michi is hungry: log your day 🐟')
          : (event?.text ?? MichiLogic.cheer(fedToday: true) ?? tr('¡Michi está feliz! 🐟', 'Michi is happy! 🐟'));
      return (pose, line);
    } catch (_) {
      return ('', '');
    }
  }

  Future<void> update({
    required String cycleDayLine,
    required String periodLine,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>(_keyCycleDayLine, cycleDayLine);
      await HomeWidget.saveWidgetData<String>(_keyPeriodLine, periodLine);
      final michi = _michi();
      await HomeWidget.saveWidgetData<String>(_keyMichi, michi.$1);
      await HomeWidget.saveWidgetData<String>(_keyMichiLine, michi.$2);
      await HomeWidget.updateWidget(androidName: _androidProviderName);
    } catch (_) {
      // Silencioso a propósito: el widget de pantalla de inicio es un
      // "extra" opcional que nunca debe interrumpir el resto de la app.
    }
  }
}

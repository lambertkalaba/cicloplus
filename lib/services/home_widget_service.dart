import 'package:home_widget/home_widget.dart';

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

  Future<void> update({
    required String cycleDayLine,
    required String periodLine,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>(_keyCycleDayLine, cycleDayLine);
      await HomeWidget.saveWidgetData<String>(_keyPeriodLine, periodLine);
      await HomeWidget.updateWidget(androidName: _androidProviderName);
    } catch (_) {
      // Silencioso a propósito: el widget de pantalla de inicio es un
      // "extra" opcional que nunca debe interrumpir el resto de la app.
    }
  }
}

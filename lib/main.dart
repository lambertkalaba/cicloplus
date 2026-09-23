import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'services/app_open_controller.dart';
import 'services/calendar_palette_controller.dart';
import 'services/calendar_style_controller.dart';
import 'services/couple_illustration_controller.dart';
import 'services/deep_link_service.dart';
import 'services/locale_controller.dart';
import 'services/settings_service.dart';
import 'services/theme_controller.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Todo el arranque va dentro de un try/catch a propósito: si algo aquí
  // falla (por ejemplo una configuración de Firebase mal hecha para una
  // plataforma, como pasó con iOS antes de registrar la app en Firebase
  // Console), antes la app se quedaba con la pantalla en blanco para
  // siempre porque el error ocurría ANTES de runApp() y nunca se veía en
  // pantalla. Ahora, si algo falla aquí, se muestra un mensaje de error en
  // vez de una pantalla en blanco — mucho más fácil de diagnosticar.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await LocaleController.instance.load();
    await ThemeController.instance.load();
    await CalendarPaletteController.instance.load();
    await CalendarStyleController.instance.load();
    await CoupleIllustrationController.instance.load();
    // Marca hoy como "día en que se abrió la app" y carga en memoria el
    // historial de días abiertos — usado por la tarjeta "Tu jardín" de Hoy
    // (ver garden_stage.dart). Va antes de construir ninguna pantalla para
    // que el primer frame ya tenga el dato de hoy incluido.
    await AppOpenController.instance.load();
    // Enlace de invitación al vincular con un socio/pareja (ver
    // DeepLinkService): si la app se abrió porque alguien escaneó el QR de
    // "Invitar a un socio" con la cámara del móvil, esto guarda el código
    // pendiente ANTES de mostrar cualquier pantalla, para que la primera
    // pantalla de "pega tu código" que se construya ya lo tenga listo.
    await DeepLinkService.instance.init();
    runApp(const CicloPlusApp());
  } catch (error, stackTrace) {
    debugPrint('Error de arranque en main(): $error\n$stackTrace');
    runApp(_StartupErrorApp(error: error));
  }
}

/// Pantalla mínima mostrada solo si algo falla ANTES de poder construir la
/// app normal (por ejemplo un error de configuración de Firebase). Sin
/// esto, ese tipo de error dejaba el teléfono con la pantalla en blanco sin
/// ninguna pista de qué pasó.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'CicloPlus no pudo iniciar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CicloPlusApp extends StatelessWidget {
  const CicloPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha LocaleController (idioma), ThemeController (color de app) y
    // CalendarPaletteController (colores del calendario) para reconstruir
    // toda la app al instante cuando la persona cambia cualquiera de los
    // tres en Configuración, sin tener que reiniciar. Esto es lo que hace
    // que el AppBar, la barra de estado del sistema, y ahora también el
    // grid del calendario, cambien en vivo.
    return ListenableBuilder(
      listenable: Listenable.merge([
        LocaleController.instance,
        ThemeController.instance,
        CalendarPaletteController.instance,
        CalendarStyleController.instance,
        CoupleIllustrationController.instance,
      ]),
      builder: (context, _) {
        return MaterialApp(
          title: 'CicloPlus',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(themeById(ThemeController.instance.themeId)),
          // Idioma de los widgets nativos (selector de fecha iOS, diálogos
          // del sistema, etc.) — sigue el mismo idioma elegido en
          // Configuración (LocaleController), no el del dispositivo.
          locale: Locale(LocaleController.instance.languageCode),
          supportedLocales: kAppLanguages.map((l) => Locale(l.code)),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AuthGate(),
        );
      },
    );
  }
}

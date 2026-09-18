import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'email_verification_screen.dart';
import 'lock_screen.dart';
import 'main_tab_screen.dart';
import 'partner_viewer_home_screen.dart';

/// Punto de entrada de la app: revisa si ya hay una sesión activa y decide
/// qué mostrar. Así MainTabScreen no necesita saber nada de autenticación —
/// solo se muestra cuando ya sabemos quién es el usuario.
///
/// Si la persona activó la protección con PIN en Configuración, se le
/// pide el PIN cada vez que se abre la app (antes de mostrar el
/// calendario), sin temporizador de bloqueo adicional por ahora.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();
  final _settingsService = SettingsService();
  AppUser? _user;
  bool _isAnonymous = false;
  bool _checkingSession = true;
  bool _locked = false;
  bool _emailVerified = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    // Red de seguridad: si algo falla al restaurar la sesión (antes podía
    // pasar sin red al abrir la app — ver el arreglo en
    // AuthService._loadAppUser), no queremos que la app se quede colgada
    // para siempre en el círculo de carga. En el peor de los casos, se
    // trata como si no hubiera sesión y se manda a la pantalla de inicio
    // de sesión, en vez de dejar a la persona sin poder hacer nada.
    AppUser? user;
    bool isAnonymous = false;
    bool hasPin = false;
    try {
      user = await _authService.currentUser();
      isAnonymous = _authService.isCurrentUserAnonymous;
      hasPin = await _settingsService.hasPin();
    } catch (_) {
      user = null;
    }
    if (!mounted) return;
    setState(() {
      _user = user;
      _isAnonymous = isAnonymous;
      _locked = hasPin;
      _emailVerified = _authService.isCurrentUserEmailVerified;
      _checkingSession = false;
    });
  }

  void _onAuthenticated(AppUser user) {
    setState(() {
      _user = user;
      _isAnonymous = _authService.isCurrentUserAnonymous;
      _emailVerified = _authService.isCurrentUserEmailVerified;
    });
  }

  void _onEmailVerified() {
    setState(() => _emailVerified = true);
  }

  Future<void> _onSignOut() async {
    await _authService.signOut();
    if (!mounted) return;
    setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_locked) {
      return LockScreen(
        mode: LockScreenMode.unlock,
        onSuccess: () => setState(() => _locked = false),
      );
    }

    if (_user == null) {
      return AuthScreen(onAuthenticated: _onAuthenticated);
    }

    // Cuenta anónima (ver AuthScreen > "¿Solo quieres ver el embarazo de tu
    // pareja?" y AuthService.signInAnonymously): no tiene ciclo propio ni
    // datos que mostrar en MainTabScreen, así que va a su propia pantalla
    // de solo lectura en vez de a la app completa.
    if (_isAnonymous) {
      return PartnerViewerHomeScreen(user: _user!, onSignOut: _onSignOut);
    }

    // Bloqueo de correo (reactivado 2026-09 tras comprar y verificar el
    // dominio cicloplus.com): hasta ahora el envío por Resend fallaba en
    // modo sandbox y confirmar el enlace era casi imposible, así que se
    // dejaba entrar sin comprobar. Con el dominio verificado el correo
    // llega bien, así que se vuelve a exigir el clic en el enlace antes de
    // dar acceso — evita cuentas con correos falsos o robados.
    if (!_emailVerified) {
      return EmailVerificationScreen(
        email: _user!.email,
        onVerified: _onEmailVerified,
        onSignOut: _onSignOut,
      );
    }

    return MainTabScreen(user: _user!, onSignOut: _onSignOut);
  }
}

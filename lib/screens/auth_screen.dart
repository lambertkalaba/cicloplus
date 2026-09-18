import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/locale_controller.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/reminder_time_sheet.dart' show ReminderDatePickerSheet;
import 'settings_screen.dart' show privacyPolicyUrlFor, termsOfUseUrlFor;

/// Paleta específica de esta pantalla — propuesta de rediseño pedida por la
/// usuaria y generada con ChatGPT ("arregla ese diseño con chatgpt"), no la
/// paleta genérica de AppColors, para poder aplicar los tonos exactos que
/// dio la propuesta (fondo degradado, textos en granate en vez de gris
/// neutro, líneas/sombras más suaves) sin tocar el resto de la app.
class _AuthPalette {
  static const bgTop = Color(0xFFFFF8FA);
  static const bgBottom = Color(0xFFFCECF2);
  // Fondo azul-lila-rosa pedido por el usuario ("ponlo un fondo azul lila
  // rosa"): degradado suave de tres tonos pastel en línea con la paleta
  // rosa/magenta de la app.
  static const bgBlue = Color(0xFFE3EEFC);
  static const bgLila = Color(0xFFEDE3F7);
  static const bgPink = Color(0xFFFBE4EE);
  static const magenta = Color(0xFFD6336C);
  static const magentaDark = Color(0xFFA61E4D);
  static const textMain = Color(0xFF351F29);
  static const textSecondary = Color(0xFF765965);
  static const textTertiary = Color(0xFF9A7A86);
  static const borderSoft = Color(0xFFF0DDE4);
  static const dividerLine = Color(0xFFE8CBD5);
  static const shieldIcon = Color(0xFFC58A9E);
}

/// Pantalla única de "Crear cuenta" / "Iniciar sesión", con un botón para
/// cambiar entre los dos modos. Diseño simple a propósito: pocos campos,
/// texto claro, sin jerga — pensado para que lo entienda cualquier persona
/// entre 13 y 70 años.
class AuthScreen extends StatefulWidget {
  final ValueChanged<AppUser> onAuthenticated;

  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  final _settingsService = SettingsService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // La pantalla se abre en modo "Iniciar sesión" (no en "Crear cuenta"),
  // pero los botones de Google/Facebook aparecen primero en ambos modos
  // (ver build()) — así quien ya tiene cuenta social entra con un toque,
  // y quien no, ve el correo/contraseña como alternativa debajo.
  bool _isRegisterMode = false;
  // El formulario de correo/contraseña empieza oculto — solo se despliega
  // cuando la persona toca "Iniciar sesión con correo" / "Crear cuenta con
  // correo", debajo de los botones de Google/Facebook (patrón tipo
  // STEEZY: social primero, correo como opción secundaria a un toque).
  bool _showEmailForm = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  DateTime? _birthDate;
  String? _errorMessage;

  // Recognizers de los enlaces "Términos de uso" / "Política de Privacidad"
  // dentro del RichText de aceptación — se guardan como campos (en vez de
  // crearse inline en cada build) para poder liberarlos explícitamente en
  // dispose(), como recomienda Flutter para TapGestureRecognizer.
  final _termsRecognizer = TapGestureRecognizer();
  final _privacyRecognizer = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    // Se calcula el idioma en el momento del toque (no aquí en initState)
    // para que, si la persona cambia de idioma antes de tocar el enlace,
    // se abra siempre la versión correcta.
    _termsRecognizer.onTap = () => _openUrl(termsOfUseUrlFor(LocaleController.instance.languageCode));
    _privacyRecognizer.onTap = () => _openUrl(privacyPolicyUrlFor(LocaleController.instance.languageCode));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  Future<void> _showForgotPasswordDialog() async {
    final s = AppStrings.of(context);
    final emailController = TextEditingController(text: _emailController.text);
    bool sending = false;
    // Error a mostrar DENTRO del diálogo (correo con formato inválido, sin
    // conexión, demasiados intentos...) — antes cualquier error se tragaba
    // en silencio y se mostraba igualmente "correo enviado", así que un
    // correo mal escrito no se podía corregir. AuthService.sendPasswordResetEmail
    // ya se encarga de que el caso "esa cuenta no existe" NUNCA llegue aquí
    // como error (ver su propio comentario) — cualquier excepción que sí
    // llegue es un error real que vale la pena mostrar.
    String? dialogError;

    // Resultado final (éxito o "esa cuenta no existe"), pedido por el
    // usuario (2026-09): en vez de cerrar el diálogo y mostrar el aviso en
    // un snackbar aparte, el mensaje sustituye el formulario DENTRO de la
    // misma tarjeta, y la tarjeta se cierra sola a los 8 segundos (antes se
    // probó con 20 y con 15-20, pero la usuaria pidió al final 8).
    String? resultMessage;
    bool resultIsSuccess = false;
    Timer? autoCloseTimer;

    // Rediseño visual pedido por el usuario ("que haya un diseño para
    // recuperar cicloplus bonito para recuperar tu contraseña"): mismo
    // Dialog de siempre pero con la estética de _AuthPalette (esquinas muy
    // redondeadas, insignia circular con ícono, botón CTA sólido magenta en
    // vez del ElevatedButton por defecto) — la lógica de envío no cambió
    // en absoluto respecto a la versión anterior.
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void startAutoCloseTimer() {
            autoCloseTimer?.cancel();
            autoCloseTimer = Timer(const Duration(seconds: 8), () {
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            });
          }

          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: resultMessage != null
                    ? [
                        // Vista de resultado (éxito o cuenta no encontrada):
                        // sustituye el formulario dentro de la misma
                        // tarjeta, en vez de cerrar el diálogo y mostrar un
                        // snackbar aparte. Se cierra sola a los 8 segundos
                        // (startAutoCloseTimer), o antes si tocan "Cerrar".
                        Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: resultIsSuccess ? _AuthPalette.bgBottom : const Color(0xFFFDECEA),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              resultIsSuccess ? Icons.mark_email_read_rounded : Icons.error_outline_rounded,
                              color: resultIsSuccess ? _AuthPalette.magenta : const Color(0xFFB42318),
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          resultMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            color: resultIsSuccess ? _AuthPalette.textMain : const Color(0xFFB42318),
                          ),
                        ),
                        const SizedBox(height: 22),
                        TextButton(
                          onPressed: () {
                            autoCloseTimer?.cancel();
                            Navigator.of(dialogContext).pop();
                          },
                          child: Text(s.close, style: const TextStyle(color: _AuthPalette.textTertiary, fontSize: 14)),
                        ),
                      ]
                    : [
                        Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: _AuthPalette.bgBottom,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock_reset_rounded, color: _AuthPalette.magenta, size: 28),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          s.authResetPasswordTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _AuthPalette.textMain),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.authResetPasswordBody,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: _AuthPalette.textSecondary, height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: _inputDecoration(s.authEmailHint),
                          onChanged: (_) {
                            if (dialogError != null) setDialogState(() => dialogError = null);
                          },
                        ),
                        if (dialogError != null) ...[
                          const SizedBox(height: 10),
                          Text(dialogError!, style: const TextStyle(color: Color(0xFFB42318), fontSize: 12.5)),
                        ],
                        const SizedBox(height: 22),
                        SizedBox(
                          height: 50,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(color: _AuthPalette.magenta.withOpacity(0.20), blurRadius: 14, offset: const Offset(0, 5)),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: sending
                                  ? null
                                  : () async {
                                      final email = emailController.text.trim();
                                      if (email.isEmpty) return;
                                      setDialogState(() {
                                        sending = true;
                                        dialogError = null;
                                      });
                                      bool exists;
                                      try {
                                        exists = await _authService.sendPasswordResetEmail(email);
                                      } catch (e) {
                                        // Error real (formato inválido, sin red,
                                        // demasiados intentos...) — se muestra
                                        // dentro del propio diálogo para que la
                                        // persona pueda corregirlo, en vez de
                                        // cerrarlo y fingir que se envió.
                                        setDialogState(() {
                                          sending = false;
                                          dialogError = e.toString();
                                        });
                                        return;
                                      }
                                      // Decisión explícita del usuario (2026-09):
                                      // si la cuenta no existe, se avisa claro en
                                      // vez del mensaje genérico de antes — y el
                                      // aviso (exista o no la cuenta) se muestra
                                      // dentro de esta misma tarjeta (en vez de un
                                      // snackbar aparte) durante 8 segundos.
                                      setDialogState(() {
                                        sending = false;
                                        resultIsSuccess = exists;
                                        resultMessage = exists ? s.authResetPasswordSent : s.authResetPasswordNotFound;
                                      });
                                      startAutoCloseTimer();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _AuthPalette.magenta,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                              ),
                              child: sending
                                  ? const SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(s.authResetPasswordSend, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: sending ? null : () => Navigator.of(dialogContext).pop(),
                          child: Text(s.authResetPasswordCancel, style: const TextStyle(color: _AuthPalette.textTertiary, fontSize: 14)),
                        ),
                      ],
              ),
            ),
          );
        },
      ),
    );
    autoCloseTimer?.cancel();
  }

  /// Abre una URL externa (Términos o Privacidad) en el navegador del
  /// dispositivo. Si por algún motivo no se puede abrir (sin navegador,
  /// sin conexión, etc.), se avisa con un snackbar en vez de fallar en
  /// silencio — mismo patrón que _openPrivacyPolicy en settings_screen.dart.
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).authGenericError)),
      );
    }
  }

  /// Entra con una sesión anónima (sin correo ni contraseña) para quien
  /// solo quiere ver el embarazo de su pareja, sin crear una cuenta
  /// completa — ver AuthService.signInAnonymously y PartnerViewerHomeScreen
  /// (AuthGate manda ahí, en vez de a la app completa, cuando la sesión es
  /// anónima).
  Future<void> _continueAsPartnerViewer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await _authService.signInAnonymously();
      if (!mounted) return;
      widget.onAuthenticated(user);
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = AppStrings.of(context).authGenericError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickBirthDate() async {
    // Selector rediseñado a pedido del usuario ("cambialo por otro mas
    // bonito"): antes era el showDatePicker genérico de Material (el
    // calendario cuadriculado de siempre); ahora se reutiliza la misma
    // hoja con ruedas de día/mes/año que ya usa el resto de la app (ver
    // ReminderDatePickerSheet en reminder_time_sheet.dart), con el color
    // magenta de esta pantalla. La lógica de guardado no cambia.
    final now = DateTime.now();
    final picked = await ReminderDatePickerSheet.show(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      primary: _AuthPalette.magenta,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validaciones extra del modo registro que no son campos de texto
    // (así que no pasan por el Form/validator de TextFormField): fecha de
    // nacimiento elegida y casilla de términos aceptada.
    if (_isRegisterMode) {
      final s = AppStrings.of(context);
      if (_birthDate == null) {
        setState(() => _errorMessage = s.authBirthDateRequired);
        return;
      }
      if (!_acceptedTerms) {
        setState(() => _errorMessage = s.authAcceptTermsRequired);
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text;
      final password = _passwordController.text;

      final user = _isRegisterMode
          ? await _authService.signUp(
              email: email,
              password: password,
              name: _nameController.text.trim(),
            )
          : await _authService.signIn(email: email, password: password);

      // Estos datos de perfil se fijan al crear la cuenta y quedan
      // guardados para siempre; solo se pueden cambiar después desde
      // Configuración > Datos, nunca desde "Mi salud".
      if (_isRegisterMode) {
        await _settingsService.saveProfileName(_nameController.text);
        await _settingsService.saveProfileLastName(_lastNameController.text);
        await _settingsService.saveProfileBirthDate(_birthDate);
      }

      if (!mounted) return;
      widget.onAuthenticated(user);
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = AppStrings.of(context).authGenericError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Maneja tanto Google como Facebook: ambos abren su propio selector de
  /// cuenta nativo (no piden correo/contraseña aquí), así que solo hace
  /// falta invocar el método correspondiente de AuthService y manejar el
  /// resultado igual que _submit.
  Future<void> _handleSocialSignIn(Future<AppUser> Function() signInMethod) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await signInMethod();
      if (!mounted) return;
      widget.onAuthenticated(user);
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = AppStrings.of(context).authGenericError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      // Degradado azul → lila → rosa pedido por el usuario, en diagonal
      // de arriba-izquierda a abajo-derecha, en tonos pastel suaves.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_AuthPalette.bgBlue, _AuthPalette.bgLila, _AuthPalette.bgPink],
          ),
        ),
        child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_showEmailForm) ...[
                    // Flecha para volver a las opciones de Google/Facebook
                    // — solo tiene sentido mientras el formulario de correo
                    // está desplegado (si está oculto, no hay "atrás" al
                    // que volver).
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: _isLoading ? null : () => setState(() => _showEmailForm = false),
                        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Logo — "debe sentirse como una marca, no como un título
                  // de formulario" (propuesta ChatGPT): solo emoji + texto,
                  // sin insignia ni sombra detrás (se probó una insignia
                  // circular con sombra en el intento anterior, pero la
                  // propuesta pide explícitamente no ponerle sombra al
                  // logo).
                  const Text('🌸', style: TextStyle(fontSize: 36), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text(
                    'CicloPlus',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _AuthPalette.magentaDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _isRegisterMode ? s.authCreateAccount : s.authSignIn,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, color: _AuthPalette.textMain, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 30),

                  if (!_showEmailForm) ...[
                    // Botones de acceso social — visibles solo mientras el
                    // formulario de correo está oculto, tanto en "Iniciar
                    // sesión" como en "Crear cuenta" (Google/Facebook
                    // funcionan igual para ambos casos: si la cuenta ya
                    // existe, entra; si no existe, la crea). Al desplegar
                    // el correo (ver más abajo) desaparecen para no
                    // competir visualmente; la flecha de "volver" arriba
                    // los trae de vuelta.
                    _SocialButton(
                      label: s.authContinueWithGoogle,
                      icon: 'G',
                      iconColor: const Color(0xFF4285F4),
                      onPressed: _isLoading ? null : () => _handleSocialSignIn(_authService.signInWithGoogle),
                    ),
                    // Boton de Facebook retirado temporalmente: para
                    // publicar la app con login de Facebook, Meta exige
                    // verificar la empresa con un documento fiscal/de
                    // registro, y la usuaria no tiene empresa ni es
                    // autonoma. Se deja solo Google (ya funciona en el
                    // build publicado) hasta que se decida retomarlo.
                    // Separador "o" — medidas de la propuesta ChatGPT: 22px
                    // de margen vertical, línea #E8CBD5, texto 13px/w500 en
                    // #9B7885, cada línea ~42% del ancho disponible.
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 22),
                      child: Row(
                        children: [
                          Expanded(flex: 42, child: Divider(color: _AuthPalette.dividerLine, thickness: 1)),
                          Expanded(
                            flex: 16,
                            child: Center(
                              child: Text('o', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF9B7885))),
                            ),
                          ),
                          Expanded(flex: 42, child: Divider(color: _AuthPalette.dividerLine, thickness: 1)),
                        ],
                      ),
                    ),

                    // Botón que despliega el formulario de correo — CTA
                    // visual principal según la propuesta ChatGPT (rosa
                    // sólido #D6336C, sin degradado, radio 27, sombra propia
                    // del magenta) en vez del botón blanco secundario que
                    // tenía antes; Google/Facebook quedan como alternativas
                    // más discretas encima.
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: [
                          BoxShadow(color: _AuthPalette.magenta.withOpacity(0.20), blurRadius: 14, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => setState(() => _showEmailForm = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _AuthPalette.magenta,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                        ),
                        child: Text(
                          _isRegisterMode ? s.authSignUpWithEmail : s.authSignInWithEmail,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Entrada alternativa para quien no quiere una cuenta
                    // propia, solo ver el embarazo de su pareja (ver
                    // _continueAsPartnerViewer). Sesión anónima por detrás,
                    // sin formulario de registro.
                    Center(
                      child: TextButton(
                        onPressed: _isLoading ? null : _continueAsPartnerViewer,
                        child: const Text(
                          '¿Solo quieres ver el embarazo de tu pareja?',
                          textAlign: TextAlign.center,
                          // Sin subrayado y en magenta oscuro (propuesta
                          // ChatGPT: "no ponerlo dentro de una tarjeta, debe
                          // sentirse como una alternativa secundaria") en
                          // vez del gris con subrayado que tenía antes.
                          style: TextStyle(color: _AuthPalette.magentaDark, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],

                  if (_showEmailForm) ...[
                  if (_isRegisterMode) ...[
                    Text(s.profileNameLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(fontSize: 16),
                      decoration: _inputDecoration(s.profileNameHint),
                      validator: (v) => (v == null || v.trim().isEmpty) ? s.authNameRequired : null,
                    ),
                    const SizedBox(height: 18),

                    Text(s.authLastNameLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(fontSize: 16),
                      decoration: _inputDecoration(s.authLastNameHint),
                      validator: (v) => (v == null || v.trim().isEmpty) ? s.authLastNameRequired : null,
                    ),
                    const SizedBox(height: 18),

                    Text(s.authBirthDateLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickBirthDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: _inputDecoration(s.authBirthDateHint),
                        child: Text(
                          _birthDate == null
                              ? s.authBirthDateHint
                              : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
                          style: TextStyle(
                            fontSize: 16,
                            color: _birthDate == null ? AppColors.textMuted : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  Text(s.authEmailLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    style: const TextStyle(fontSize: 16),
                    decoration: _inputDecoration(s.authEmailHint),
                    validator: (v) => (v == null || v.trim().isEmpty) ? s.authEmailRequired : null,
                  ),
                  const SizedBox(height: 18),

                  Text(s.authPasswordLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(fontSize: 16),
                    decoration: _inputDecoration(s.authPasswordHint).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? s.authPasswordRequired : null,
                    onFieldSubmitted: _isRegisterMode ? null : (_) => _submit(),
                  ),

                  if (!_isRegisterMode) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _showForgotPasswordDialog,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          s.authForgotPassword,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],

                  if (_isRegisterMode) ...[
                    const SizedBox(height: 18),
                    Text(s.authConfirmPasswordLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(fontSize: 16),
                      decoration: _inputDecoration(s.authConfirmPasswordHint).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return s.authPasswordRequired;
                        if (v != _passwordController.text) return s.authConfirmPasswordMismatch;
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ],
                  ], // fin if (_showEmailForm)

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF3B8B8)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFB42318), fontSize: 13),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  if (_isRegisterMode && _showEmailForm) ...[
                    InkWell(
                      onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _acceptedTerms,
                              activeColor: AppColors.primary,
                              onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
                                    children: [
                                      TextSpan(text: s.authAcceptTermsLabelPrefix),
                                      TextSpan(
                                        text: s.authTermsLink,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: _termsRecognizer,
                                      ),
                                      TextSpan(text: s.authAcceptTermsAnd),
                                      TextSpan(
                                        text: s.authPrivacyLink,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: _privacyRecognizer,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (_showEmailForm) ...[
                    // Mismo tratamiento de CTA que el botón "Iniciar sesión
                    // con correo" de la pantalla anterior (alto 54, radio
                    // 27, rosa sólido #D6336C sin degradado, sombra propia
                    // del magenta) para que ambos botones principales se
                    // sientan como el mismo lenguaje visual.
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: [
                          BoxShadow(color: _AuthPalette.magenta.withOpacity(0.20), blurRadius: 14, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _AuthPalette.magenta,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                              )
                            : Text(
                                _isRegisterMode ? s.authCreateAccountButton : s.authEnterButton,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // La propuesta ChatGPT pide dos colores dentro de este
                  // enlace ("¿No tienes cuenta?" en gris, "Regístrate
                  // gratis" en magenta) — no se puede partir así de forma
                  // segura porque el texto viene como UNA sola cadena ya
                  // traducida a 9 idiomas (s.authNoAccount/authHaveAccount),
                  // con distinto orden de palabras/puntuación en cada uno.
                  // Se deja en magenta oscuro completo, más cercano al
                  // espíritu del pedido que partir la traducción a ciegas.
                  SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                                _isRegisterMode = !_isRegisterMode;
                                _errorMessage = null;
                              }),
                      child: Text(
                        _isRegisterMode ? s.authHaveAccount : s.authNoAccount,
                        style: const TextStyle(color: _AuthPalette.magenta, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  // Nota de privacidad: ancho máximo 300px, texto pequeño en
                  // tono granate suave, con un icono de escudo delante —
                  // "debe ser un elemento tranquilo y discreto" (propuesta
                  // ChatGPT), en vez del texto suelto de antes.
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.shield_outlined, size: 13, color: _AuthPalette.shieldIcon),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              s.authPrivacyNote,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11.5, color: _AuthPalette.textTertiary, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
            Positioned(
              top: 4,
              right: 4,
              child: _LanguagePickerButton(),
            ),
          ],
        ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    // Radio 18px ("familia de radios" de la propuesta ChatGPT: inputs
    // 18-20px) y borde en reposo transparente — el relleno blanco ya
    // distingue el campo del fondo degradado, así que el borde solo hace
    // falta al enfocar o si hay error.
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _AuthPalette.textTertiary, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.transparent, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.transparent, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _AuthPalette.magenta, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.5),
      ),
    );
  }
}

/// Botón pequeño (bandera del idioma actual) en la esquina superior derecha
/// de la pantalla de inicio de sesión / crear cuenta. El auto-detect del
/// idioma del dispositivo (ver LocaleController._detectSystemLanguage) ya
/// cubre la mayoría de los casos, pero esto da una salida explícita para
/// quien: (a) tiene el idioma del sistema en uno no soportado y por eso cae
/// a español, o (b) simplemente prefiere ver la app en otro idioma antes de
/// registrarse, sin tener que crear la cuenta primero para llegar a
/// Configuración > Idioma.
class _LanguagePickerButton extends StatelessWidget {
  const _LanguagePickerButton();

  void _openPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        // Arreglo del desborde "RenderFlex overflowed" que aparecía con los
        // 9 idiomas: antes era un Column sin límite de altura ni forma de
        // desplazarse, así que si no entraban todos en la pantalla se
        // salían por abajo. Ahora la hoja tiene una altura máxima y la
        // lista es desplazable (ListView) dentro de ese límite.
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.7;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: kAppLanguages.map((lang) {
                        final selected = lang.code == LocaleController.instance.languageCode;
                        return ListTile(
                          leading: Text(lang.flag, style: const TextStyle(fontSize: 22)),
                          title: Text(lang.nativeName, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                          trailing: selected ? const Icon(Icons.check, color: AppColors.primary) : null,
                          onTap: () {
                            LocaleController.instance.setLanguage(lang.code);
                            Navigator.of(sheetContext).pop();
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = kAppLanguages.firstWhere(
      (l) => l.code == LocaleController.instance.languageCode,
      orElse: () => kAppLanguages.first,
    );
    // Medidas de la propuesta ChatGPT: contenedor 44x40, radio 20, sombra
    // #A61E4D 8%/blur10/offsetY3, bandera 19-20px — antes un pill ajustado
    // al contenido con padding 10/6 y sombra genérica de textPrimary.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openPicker(context),
        child: Container(
          width: 44,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: _AuthPalette.magentaDark.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(current.flag, style: const TextStyle(fontSize: 19)),
              const SizedBox(width: 2),
              const Icon(Icons.expand_more, size: 14, color: _AuthPalette.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón de acceso social (Google/Facebook), con la letra inicial del
/// proveedor como ícono simple en vez de un logo con licencia — visualmente
/// consistente con el resto de botones de la app (fondo blanco, texto
/// oscuro). Antes llevaba un borde gris plano (OutlinedButton); ahora usa
/// una sombra suave en su lugar — mismo pedido de "que se vea más moderna"
/// aplicado igual que en el botón de correo y el botón principal.
class _SocialButton extends StatelessWidget {
  final String label;
  final String icon;
  final Color iconColor;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Medidas de la propuesta ChatGPT: alto 52, radio 26, borde 1px
    // #F0DDE4, sombra #7D5362 8%/blur12/offset(0,3), icono 20px, texto
    // 15px/w600 en #34242B — antes 48/14/sin borde/#textPrimary.
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _AuthPalette.borderSoft, width: 1),
          boxShadow: [
            BoxShadow(color: const Color(0xFF7D5362).withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 3)),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: iconColor.withOpacity(0.12)),
                  child: Text(icon, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: iconColor)),
                ),
                const SizedBox(width: 10),
                Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF34242B))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

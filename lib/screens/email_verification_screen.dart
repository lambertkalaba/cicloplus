import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Pantalla de espera que AuthGate muestra en vez de MainTabScreen cuando
/// la sesión activa se registró con correo/contraseña y todavía no confirmó
/// su correo (ver AuthService.isCurrentUserEmailVerified) — evita que
/// alguien entre a la app con un correo inventado o robado a otra persona,
/// ya que solo confirmando el enlace que Firebase envía se puede continuar.
///
/// No aplica a Google/Facebook (ya confirman el correo ellos) ni a la
/// sesión anónima de socio/pareja (no tiene correo) — AuthGate ya filtra
/// eso antes de mostrar esta pantalla.
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;
  final VoidCallback onSignOut;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.onVerified,
    required this.onSignOut,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _authService = AuthService();
  bool _busy = false;
  String? _message;

  Future<void> _checkNow() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final verified = await _authService.reloadAndCheckEmailVerified();
    if (!mounted) return;
    if (verified) {
      widget.onVerified();
      return;
    }
    setState(() {
      _busy = false;
      _message = AppStrings.of(context).emailVerifyNotYet;
    });
  }

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _authService.resendVerificationEmail();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = AppStrings.of(context).emailVerifyResendSent;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = AppStrings.of(context).authGenericError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_unread_rounded, size: 72, color: AppColors.primary),
                const SizedBox(height: 24),
                Text(
                  s.emailVerifyTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  s.emailVerifyBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 28),
                if (_message != null) ...[
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _checkNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(s.emailVerifyCheck),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : _resend,
                  child: Text(s.emailVerifyResend),
                ),
                TextButton(
                  onPressed: _busy ? null : widget.onSignOut,
                  child: Text(s.signOut, style: const TextStyle(color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Pantalla mostrada por AuthGate cuando la sesión que se acaba de iniciar
/// pertenece a una cuenta marcada como pendiente de borrado (ver
/// AuthService.requestAccountDeletion) y todavía está dentro del plazo de
/// gracia de 30 días. Dos caminos: "Recuperar mi cuenta" (cancela el
/// borrado y entra a la app normal) o "Cerrar sesión" (no cambia nada —
/// la cuenta sigue pendiente de borrarse el día indicado).
class AccountPendingDeletionScreen extends StatefulWidget {
  final PendingAccountDeletion info;
  final VoidCallback onRecovered;
  final VoidCallback onSignOut;

  const AccountPendingDeletionScreen({
    super.key,
    required this.info,
    required this.onRecovered,
    required this.onSignOut,
  });

  @override
  State<AccountPendingDeletionScreen> createState() => _AccountPendingDeletionScreenState();
}

class _AccountPendingDeletionScreenState extends State<AccountPendingDeletionScreen> {
  final _authService = AuthService();
  bool _recovering = false;
  String? _error;

  Future<void> _recover() async {
    setState(() {
      _recovering = true;
      _error = null;
    });
    try {
      await _authService.cancelAccountDeletion();
      widget.onRecovered();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _recovering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final daysLeft = widget.info.daysRemaining.clamp(0, 30);
    final deletionDate = widget.info.requestedAt.add(const Duration(days: 30));
    final dateLabel = '${deletionDate.day.toString().padLeft(2, '0')}/${deletionDate.month.toString().padLeft(2, '0')}/${deletionDate.year}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(color: Color(0xFFFDECEA), shape: BoxShape.circle),
                  child: const Icon(Icons.hourglass_bottom_rounded, color: Color(0xFFB42318), size: 30),
                ),
                const SizedBox(height: 20),
                Text(
                  s.accountPendingDeletionTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Text(
                  s.accountPendingDeletionBody(dateLabel, daysLeft),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.5),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: const TextStyle(color: Color(0xFFB42318), fontSize: 13), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _recovering ? null : _recover,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    child: _recovering
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                        : Text(s.accountPendingDeletionRecover, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _recovering ? null : widget.onSignOut,
                  child: Text(s.accountPendingDeletionSignOut, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

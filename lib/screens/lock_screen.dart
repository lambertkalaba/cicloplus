import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

/// Modo de uso de la pantalla de bloqueo, equivalente a `pinStage` en el
/// prototipo web.
enum LockScreenMode { unlock, create, confirm }

/// Teclado numérico de 4 dígitos para crear/confirmar/desbloquear con PIN.
///
/// Uso:
/// - `LockScreenMode.unlock`: se muestra antes de `AuthGate` si el PIN está
///   activo (una vez por apertura de la app, versión simple sin
///   temporizador de bloqueo — igual que `checkLockOnLoad` en el prototipo).
/// - `LockScreenMode.create` / `.confirm`: se usa desde SettingsScreen al
///   activar la protección con PIN por primera vez.
///
/// Al desbloquear o crear el PIN con éxito, llama a `onSuccess`. Si el
/// usuario puede cancelar (por ejemplo, al crear un PIN desde ajustes),
/// pasa `onCancel`; si es la pantalla de bloqueo obligatoria al abrir la
/// app, no pases `onCancel` (no se mostrará botón de salir).
class LockScreen extends StatefulWidget {
  final LockScreenMode mode;
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;

  const LockScreen({
    super.key,
    required this.mode,
    required this.onSuccess,
    this.onCancel,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final SettingsService _settings = SettingsService();
  late LockScreenMode _stage;
  String _buffer = '';
  String _pendingPin = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _stage = widget.mode;
  }

  String get _subtitle {
    if (_error != null) return _error!;
    final s = AppStrings.of(context);
    switch (_stage) {
      case LockScreenMode.create:
        return s.lockCreatePin;
      case LockScreenMode.confirm:
        return s.lockConfirmPin;
      case LockScreenMode.unlock:
        return s.lockEnterPin;
    }
  }

  void _onKey(String key) {
    if (key == 'del') {
      setState(() {
        if (_buffer.isNotEmpty) _buffer = _buffer.substring(0, _buffer.length - 1);
        _error = null;
      });
      return;
    }
    if (_buffer.length >= 4) return;
    setState(() {
      _buffer += key;
      _error = null;
    });
    if (_buffer.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _handleComplete);
    }
  }

  Future<void> _handleComplete() async {
    if (_stage == LockScreenMode.create) {
      setState(() {
        _pendingPin = _buffer;
        _buffer = '';
        _stage = LockScreenMode.confirm;
      });
      return;
    }
    if (_stage == LockScreenMode.confirm) {
      if (_buffer == _pendingPin) {
        await _settings.savePin(_buffer);
        widget.onSuccess();
      } else {
        if (!mounted) return;
        setState(() {
          _error = AppStrings.of(context).lockPinMismatch;
          _buffer = '';
          _pendingPin = '';
          _stage = LockScreenMode.create;
        });
      }
      return;
    }
    // unlock
    final savedPin = await _settings.loadPin();
    if (_buffer == savedPin) {
      widget.onSuccess();
    } else {
      if (!mounted) return;
      setState(() {
        _error = AppStrings.of(context).lockPinIncorrect;
        _buffer = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nota: se usa un Scaffold simple (sin PopScope/WillPopScope) para no
    // depender de una versión mínima de Flutter en particular. Cuando la
    // pantalla es cancelable (creación de PIN desde Configuración), el
    // botón "Cancelar" de abajo es la única salida; cuando es el
    // desbloqueo obligatorio al abrir la app, no se puede cancelar de
    // ninguna forma, que es el comportamiento esperado.
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌸', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 12),
              Text(
                s.lockAppLocked,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                _subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: _error != null ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _buffer.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 7),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.primary : Colors.transparent,
                      border: Border.all(color: AppColors.primaryLight, width: 1.5),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                      _PinKey(label: k, onTap: () => _onKey(k)),
                    const SizedBox.shrink(),
                    _PinKey(label: '0', onTap: () => _onKey('0')),
                    _PinKey(label: '⌫', onTap: () => _onKey('del')),
                  ],
                ),
              ),
              if (widget.onCancel != null) ...[
                const SizedBox(height: 18),
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text(s.cancel, style: const TextStyle(color: AppColors.textMuted)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PinKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PinKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border, width: 1.5)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Center(
          child: Text(label, style: const TextStyle(fontSize: 18, color: AppColors.textPrimary)),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/settings_service.dart' show themeById;
import '../theme/app_theme.dart';

/// Pantalla de Apple Watch con funcionalidad real (fase 8): en vez del
/// aviso genérico "próximamente", explica cómo CicloPlus sí llega a un
/// Apple Watch hoy (sincronizando con Apple Salud / Health Connect, ver
/// `HealthSyncService`) y ofrece el mismo interruptor real de
/// Configuración para activarlo sin tener que salir de esta pantalla.
///
/// El estado activado/ocupado y el callback de activación se reciben
/// desde `SettingsScreen` (misma fuente de verdad que la fila "Apple
/// Salud" más abajo en Configuración) para no duplicar lógica ni
/// almacenamiento: esta pantalla solo mantiene una copia local para
/// pintar el `Switch` mientras la operación está en curso.
class AppleWatchScreen extends StatefulWidget {
  final String themeId;
  final bool healthSyncEnabled;
  final bool healthSyncBusy;
  final Future<bool> Function(bool) onToggleHealthSync;

  const AppleWatchScreen({
    super.key,
    this.themeId = 'pink',
    required this.healthSyncEnabled,
    required this.healthSyncBusy,
    required this.onToggleHealthSync,
  });

  @override
  State<AppleWatchScreen> createState() => _AppleWatchScreenState();
}

class _AppleWatchScreenState extends State<AppleWatchScreen> {
  late bool _enabled = widget.healthSyncEnabled;
  late bool _busy = widget.healthSyncBusy;

  Future<void> _handleToggle(bool value) async {
    setState(() => _busy = true);
    final granted = await widget.onToggleHealthSync(value);
    if (!mounted) return;
    setState(() {
      _enabled = granted;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = themeById(widget.themeId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: Color(theme.primary),
            foregroundColor: Colors.white,
            title: Text(s.settingsAppleWatch),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(theme.primaryDark), Color(theme.primary)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.watch_outlined, size: 84, color: Colors.white),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  s.appleWatchScreenExplanation,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted, height: 1.45),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      s.settingsHealthSyncToggle,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    subtitle: Text(_enabled ? s.on_ : s.off_),
                    value: _enabled,
                    activeColor: Color(theme.primary),
                    onChanged: _busy ? null : _handleToggle,
                  ),
                ),
                const SizedBox(height: 16),
                if (_busy)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
                    ),
                  )
                else
                  Text(
                    _enabled ? s.appleWatchScreenEnabledHint : s.appleWatchScreenDisabledHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
                  ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(theme.primary),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(s.comingSoonGotIt, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

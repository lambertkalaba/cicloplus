import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/settings_service.dart' show themeById;
import '../theme/app_theme.dart';

/// Pantalla real del widget de pantalla de inicio (fase 8): en vez del
/// aviso "próximamente", explica cómo añadirlo (Android no permite a una
/// app colocarlo por sí sola en la pantalla de inicio del usuario, solo
/// guiar hasta el paso "mantener pulsado > Widgets") y muestra una vista
/// previa con el contenido REAL que el widget está mostrando ahora mismo
/// — [cycleDayLine]/[periodLine] ya vienen calculados y traducidos desde
/// SettingsScreen._openWidgetPlaceholder con el mismo CyclePredictor que
/// usa el widget de verdad (ver HomeWidgetService, actualizado desde
/// MainTabScreen._syncHomeWidget cada vez que cambian los datos).
class WidgetPlaceholderScreen extends StatelessWidget {
  final String themeId;
  final String cycleDayLine;
  final String periodLine;

  const WidgetPlaceholderScreen({
    super.key,
    this.themeId = 'pink',
    required this.cycleDayLine,
    required this.periodLine,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = themeById(themeId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: Color(theme.primary),
            foregroundColor: Colors.white,
            title: Text(s.settingsWidget),
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
                  child: Icon(Icons.widgets_outlined, size: 84, color: Colors.white),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  s.widgetScreenRealExplanation,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted, height: 1.45),
                ),
                const SizedBox(height: 24),
                Text(
                  s.widgetScreenPreviewLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                // Réplica visual aproximada del widget nativo real (mismo
                // layout de 2 líneas que pinta CicloPlusWidgetProvider.kt
                // a partir de estos mismos textos), no una maqueta
                // decorativa distinta.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: Color(theme.primary),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cycleDayLine,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      if (periodLine.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          periodLine,
                          style: const TextStyle(fontSize: 12.5, color: Colors.white),
                        ),
                      ],
                    ],
                  ),
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

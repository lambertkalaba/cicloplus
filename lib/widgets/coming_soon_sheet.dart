import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Diálogo reutilizable "próximamente" para cualquier fila/botón de la app
/// que todavía no tiene función real detrás (placeholder). Antes cada
/// pantalla (MeScreen, InvitePartnerScreen...) tenía su propio AlertDialog
/// ad-hoc con el mismo contenido (`s.comingSoonFeature` + `s.comingSoonNotify`)
/// copiado y pegado; este helper centraliza ese patrón para que todas las
/// filas nuevas de Configuración (fase "Ajustes: reorganizar como en
/// capturas") lo compartan, con un estilo un poco más rico (icono +
/// título específico opcional) sin dejar de ser el mismo diálogo simple
/// de siempre en su forma mínima.
///
/// [title] reemplaza el título genérico "Esta función estará disponible
/// próximamente" cuando se quiere nombrar la función concreta (ej.
/// "Apple Watch"); si se omite, se usa `s.comingSoonFeature` como título,
/// igual que el diálogo original de MeScreen.
Future<void> showComingSoonSheet(
  BuildContext context, {
  String? title,
  String? subtitle,
  IconData icon = Icons.hourglass_top_rounded,
}) async {
  final s = AppStrings.of(context);
  final resolvedTitle = title ?? s.comingSoonFeature;
  final resolvedSubtitle = subtitle ?? s.comingSoonNotify;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return SafeArea(
        child: Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.primary, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                resolvedTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                resolvedSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primaryLight),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(s.close, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

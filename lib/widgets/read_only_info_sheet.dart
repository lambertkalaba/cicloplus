import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Hoja inferior (bottom sheet) estilo iOS que explica que un vínculo de
/// socio/pareja es de SOLO LECTURA. Se usa en dos sitios: el ícono (i)
/// junto a "¿Te compartieron un código?" en InvitePartnerScreen, y el
/// mismo ícono en PartnerViewerHomeScreen (cuenta anónima). Antes esto era
/// un AlertDialog plano; esta versión imita el patrón de hoja inferior
/// redondeada con tirador, ícono circular y botón de ancho completo típico
/// de iOS, para que se sienta más pulido que un diálogo genérico.
///
/// [primaryColor]/[primaryLightColor] permiten que el círculo del ícono y
/// el botón "Entendido" usen el mismo color que la persona eligió en esa
/// pantalla (ver PartnerViewerHomeScreen > selector Azul/Rosa/Violeta) en
/// vez de quedarse fijos en rosa — si no se pasan, usan el rosa por
/// defecto de AppColors (caso de InvitePartnerScreen, que no tiene
/// selector de color propio).
Future<void> showReadOnlyInfoSheet(
  BuildContext context, {
  Color? primaryColor,
  Color? primaryLightColor,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _ReadOnlyInfoSheet(
      primaryColor: primaryColor ?? AppColors.primary,
      primaryLightColor: primaryLightColor ?? AppColors.primaryLight,
    ),
  );
}

class _ReadOnlyInfoSheet extends StatelessWidget {
  final Color primaryColor;
  final Color primaryLightColor;

  const _ReadOnlyInfoSheet({required this.primaryColor, required this.primaryLightColor});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tirador — puramente decorativo (no arrastra nada), pero es
            // la señal visual que hace que esto se lea como una hoja
            // inferior nativa en vez de un diálogo genérico.
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: primaryLightColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.visibility_outlined, color: primaryColor, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Solo lectura',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            const Text(
              'Con este código solo podrás ver el seguimiento de embarazo de la '
              'persona que te invitó (y las fotos del bebé, si ella lo permite).\n\n'
              'Nunca podrás editar sus datos ni ver su calendario, síntomas u otra '
              'información personal.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.45),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Entendido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

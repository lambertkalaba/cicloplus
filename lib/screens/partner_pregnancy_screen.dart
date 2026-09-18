import 'package:flutter/material.dart';

import '../services/partner_service.dart';
import 'pregnancy_tracking_screen.dart';

/// Vista de solo lectura del embarazo de la persona que me vinculó como
/// socio/pareja (ver InvitePartnerScreen > "Embarazos que sigues"). No
/// tiene ningún botón de editar ni de guardar — toda la protección real de
/// que esto es "solo lectura" vive en firestore.rules (ver
/// PartnerService/firestore.rules), esta pantalla simplemente no ofrece
/// ninguna acción de escritura.
///
/// Reutiliza PregnancyTrackingScreen tal cual (esa pantalla ya era 100%
/// de visualización, sin controles de edición propios), pasándole el LMP
/// leído en vivo desde Firestore en vez de la configuración local del
/// dispositivo. Si la dueña no activó "Compartir fotos del bebé", se pide
/// a esa misma pantalla que oculte la foto real (hideBabyPhoto).
class PartnerPregnancyScreen extends StatelessWidget {
  final String ownerUid;
  final String ownerEmail;

  /// Nombre registrado de la dueña (o su correo, si todavía no puso
  /// nombre) — mismo criterio ya usado en PartnerHubScreen/
  /// InvitePartnerScreen (ver tarea "mostrar nombre en vez de correo").
  /// Se usa solo en el placeholder de "todavía no activó su seguimiento";
  /// si viene vacío, se cae de vuelta a [ownerEmail] (mismo comportamiento
  /// que antes de que existiera este campo).
  final String? ownerLabel;
  final String themeId;

  /// Ver comentario en PregnancyTrackingScreen.onClose — solo lo usa
  /// PartnerViewerHomeScreen (cuenta anónima sin ninguna pantalla debajo
  /// en la pila de navegación).
  final VoidCallback? onClose;

  /// false cuando se usa como la pestaña "Seguimiento" dentro de
  /// PartnerHubScreen: ahí el Hub ya pone su propio AppBar (con nombre y
  /// botón de salir/atrás) y su propio fondo, así que aquí no se envuelve
  /// nada en un Scaffold propio — se devuelve solo el contenido. El valor
  /// por defecto (true) mantiene el comportamiento de pantalla completa
  /// para cualquier otro uso.
  final bool standalone;

  const PartnerPregnancyScreen({
    super.key,
    required this.ownerUid,
    required this.ownerEmail,
    this.ownerLabel,
    required this.themeId,
    this.onClose,
    this.standalone = true,
  });

  static const _bgColor = Color(0xFF0F0F14);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PartnerPregnancyData?>(
      stream: PartnerService().watchPregnancyData(ownerUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _bgColor,
            body: Center(child: CircularProgressIndicator(color: Colors.white70)),
          );
        }

        final data = snapshot.data;
        if (data == null || !data.enabled || data.lmp == null) {
          final placeholder = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🤰', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    '${(ownerLabel != null && ownerLabel!.trim().isNotEmpty) ? ownerLabel : ownerEmail} todavía no ha activado o compartido su seguimiento de embarazo.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
          if (!standalone) {
            return Container(color: _bgColor, child: placeholder);
          }
          return Scaffold(
            backgroundColor: _bgColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: onClose == null,
              leading: onClose != null
                  ? IconButton(icon: const Icon(Icons.close), onPressed: onClose)
                  : null,
            ),
            body: placeholder,
          );
        }

        return PregnancyTrackingScreen(
          lmp: data.lmp!,
          themeId: themeId,
          isTwins: data.isTwins,
          hideBabyPhoto: !data.shareBabyPhotos,
          onClose: onClose,
          showCloseButton: standalone,
        );
      },
    );
  }
}

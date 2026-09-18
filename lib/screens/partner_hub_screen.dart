import 'package:flutter/material.dart';

import '../services/partner_service.dart';
import '../services/settings_service.dart' show themeById;
import '../theme/app_theme.dart';
import 'partner_chat_screen.dart';
import 'partner_cycle_screen.dart';
import 'partner_pregnancy_screen.dart';
import 'partner_tips_screen.dart';
import 'partner_wishes_screen.dart';

/// Pantalla principal para quien SIGUE el embarazo de otra persona (su
/// pareja/socia ya vinculada) — reemplaza el antiguo acceso directo a
/// PartnerPregnancyScreen con 4 pestañas: Chat, Seguimiento, Consejos y
/// Deseos. Se usa desde los dos puntos donde alguien ve un embarazo ajeno:
///
/// - PartnerViewerHomeScreen (cuenta anónima "solo ver el embarazo de mi
///   pareja"), pasando [onClose] para cerrar esa sesión.
/// - InvitePartnerScreen > "Embarazos que sigues" (cuenta normal que
///   además sigue el embarazo de alguien más), sin [onClose]: el botón de
///   la cabecera hace Navigator.pop normal.
///
/// Cada pestaña reutiliza una pantalla que ya existía por separado
/// (PartnerPregnancyScreen, PartnerChatScreen) en modo "embebido" (sin su
/// propio AppBar) para no duplicar cabeceras — ver los flags
/// standalone/showAppBar en esas clases.
class PartnerHubScreen extends StatefulWidget {
  final String ownerUid;
  final String ownerEmail;
  final String ownerLabel;
  final String myUid;
  final String themeId;
  final VoidCallback? onClose;

  const PartnerHubScreen({
    super.key,
    required this.ownerUid,
    required this.ownerEmail,
    required this.ownerLabel,
    required this.myUid,
    required this.themeId,
    this.onClose,
  });

  @override
  State<PartnerHubScreen> createState() => _PartnerHubScreenState();
}

class _PartnerHubScreenState extends State<PartnerHubScreen> {
  // Empieza en "Seguimiento" (índice 1): es la razón principal por la que
  // alguien entra aquí, las otras 3 pestañas son complementarias.
  int _tabIndex = 1;

  @override
  Widget build(BuildContext context) {
    final theme = themeById(widget.themeId);
    final primary = Color(theme.primary);
    final primaryDark = Color(theme.primaryDark);

    // Qué se ve en "Seguimiento" depende de qué esté compartiendo la
    // dueña AHORA MISMO — puede cambiar de objetivo en cualquier momento
    // (ver invite_partner_screen.dart, que sincroniza uno u otro según su
    // modo actual): con el embarazo activo se reutiliza
    // PartnerPregnancyScreen tal cual ya existía; en los otros dos
    // objetivos se muestra el calendario de ciclo de solo lectura nuevo
    // (PartnerCycleScreen). "Consejos" no necesita este mismo chequeo:
    // PartnerTipsScreen ya muestra su propio mensaje de "todavía no
    // comparte su embarazo" cuando no aplica.
    return StreamBuilder<PartnerPregnancyData?>(
      stream: PartnerService().watchPregnancyData(widget.ownerUid),
      builder: (context, pregnancySnap) {
        final pregnancyData = pregnancySnap.data;
        final pregnancyActive = pregnancyData != null && pregnancyData.enabled && pregnancyData.lmp != null;

        final tabs = <Widget>[
          PartnerChatScreen(
            myUid: widget.myUid,
            otherUid: widget.ownerUid,
            otherLabel: widget.ownerLabel,
            themeId: widget.themeId,
            showAppBar: false,
          ),
          pregnancyActive
              ? PartnerPregnancyScreen(
                  ownerUid: widget.ownerUid,
                  ownerEmail: widget.ownerEmail,
                  ownerLabel: widget.ownerLabel,
                  themeId: widget.themeId,
                  standalone: false,
                )
              : PartnerCycleScreen(
                  ownerUid: widget.ownerUid,
                  ownerEmail: widget.ownerEmail,
                  ownerLabel: widget.ownerLabel,
                  themeId: widget.themeId,
                  standalone: false,
                ),
          PartnerTipsScreen(ownerUid: widget.ownerUid, themeId: widget.themeId),
          PartnerWishesScreen(
            ownerUid: widget.ownerUid,
            myUid: widget.myUid,
            themeId: widget.themeId,
            isOwner: false,
          ),
        ];

        return _buildScaffold(context, primary, primaryDark, tabs, pregnancyActive);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, Color primary, Color primaryDark, List<Widget> tabs, bool pregnancyActive) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.ownerLabel),
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(widget.onClose != null ? Icons.link_off : Icons.arrow_back),
          tooltip: widget.onClose != null ? 'Dejar de seguir este seguimiento' : 'Atrás',
          onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: IndexedStack(index: _tabIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primary,
        unselectedItemColor: AppColors.textMuted,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(
            icon: Icon(pregnancyActive ? Icons.pregnant_woman_outlined : Icons.calendar_month_outlined),
            label: 'Seguimiento',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.lightbulb_outline), label: 'Consejos'),
          const BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Deseos'),
        ],
      ),
    );
  }
}

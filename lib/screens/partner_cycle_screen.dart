import 'package:flutter/material.dart';

import '../services/partner_service.dart';
import '../services/settings_service.dart' show themeById;
import '../theme/app_theme.dart';

/// Vista de solo lectura del calendario de ciclo de la persona que me
/// vinculó como socio/pareja, para cuando NO está en modo embarazo (ver
/// PartnerPregnancyScreen para ese caso, y PartnerService.syncCycleData/
/// watchCycleData de dónde sale este resumen). Igual que esa pantalla, no
/// ofrece ningún control de edición — toda la protección real de "solo
/// lectura" vive en firestore.rules, esta pantalla simplemente no ofrece
/// ninguna acción de escritura.
///
/// A propósito muestra solo un RESUMEN ya calculado (día del ciclo,
/// previsto del próximo periodo, ventana fértil/ovulación) — nunca el
/// Map<String, DayEntry> crudo con los síntomas y notas que la dueña
/// registra día a día, que siguen siendo privados (ver
/// PartnerService.syncCycleData). Mismo criterio que usa Flo para
/// compartir en modo "Seguir mi periodo"/"Intentar concebir": calendario
/// de solo lectura, sin los síntomas registrados personalmente.
class PartnerCycleScreen extends StatelessWidget {
  final String ownerUid;
  final String ownerEmail;
  final String? ownerLabel;
  final String themeId;

  /// Ver comentario en PartnerPregnancyScreen.onClose — solo lo usa
  /// PartnerViewerHomeScreen (cuenta anónima sin ninguna pantalla debajo
  /// en la pila de navegación).
  final VoidCallback? onClose;

  /// false cuando se usa como la pestaña "Seguimiento" dentro de
  /// PartnerHubScreen — igual que en PartnerPregnancyScreen.standalone.
  final bool standalone;

  const PartnerCycleScreen({
    super.key,
    required this.ownerUid,
    required this.ownerEmail,
    this.ownerLabel,
    required this.themeId,
    this.onClose,
    this.standalone = true,
  });

  String get _displayName =>
      (ownerLabel != null && ownerLabel!.trim().isNotEmpty) ? ownerLabel! : ownerEmail;

  // Mismo formato manual 'd/m/aaaa' usado en el resto de la app (ver
  // today_screen.dart, pregnancy_tracking_screen.dart) — sin depender de
  // intl.DateFormat, que esta pantalla no necesita para nada más.
  static String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = themeById(themeId);
    final primary = Color(theme.primary);
    final primaryDark = Color(theme.primaryDark);

    return StreamBuilder<PartnerCycleData?>(
      stream: PartnerService().watchCycleData(ownerUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _scaffoldIfStandalone(
            primaryDark,
            const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          final placeholder = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🩷', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    '$_displayName todavía no ha activado o compartido su seguimiento.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
          return _scaffoldIfStandalone(primaryDark, placeholder);
        }

        final content = ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (data.userGoal == 'conceive') ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: primary.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, size: 14, color: primary),
                      const SizedBox(width: 6),
                      Text('Intentando concebir', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (data.currentDayInCycle != null) ...[
              _statCard(icon: Icons.today_outlined, label: 'Día del ciclo', value: 'Día ${data.currentDayInCycle! + 1}', primary: primary),
              const SizedBox(height: 12),
            ],
            if (data.nextPeriodStart != null) ...[
              _statCard(
                icon: Icons.water_drop_outlined,
                label: data.isIrregular ? 'Próximo periodo (aproximado)' : 'Próximo periodo previsto',
                value: _fmtDate(data.nextPeriodStart!),
                primary: primary,
              ),
              const SizedBox(height: 12),
            ],
            if (data.fertileRangeStart != null && data.fertileRangeEnd != null) ...[
              _statCard(
                icon: Icons.eco_outlined,
                label: 'Ventana fértil',
                value: '${_fmtDate(data.fertileRangeStart!)} – ${_fmtDate(data.fertileRangeEnd!)}',
                primary: primary,
              ),
              const SizedBox(height: 12),
            ],
            if (data.ovulationDate != null) ...[
              _statCard(icon: Icons.circle_outlined, label: 'Ovulación estimada', value: _fmtDate(data.ovulationDate!), primary: primary),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            Text(
              'Solo se comparte este resumen calculado — nunca los síntomas ni notas que $_displayName registra día a día.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
            ),
          ],
        );

        if (!standalone) return content;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: primaryDark,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: onClose == null,
            leading: onClose != null ? IconButton(icon: const Icon(Icons.close), onPressed: onClose) : null,
            title: Text(_displayName),
          ),
          body: content,
        );
      },
    );
  }

  Widget _scaffoldIfStandalone(Color primaryDark, Widget child) {
    if (!standalone) return child;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: onClose == null,
        leading: onClose != null ? IconButton(icon: const Icon(Icons.close), onPressed: onClose) : null,
      ),
      body: child,
    );
  }

  Widget _statCard({required IconData icon, required String label, required String value, required Color primary}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: primary.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

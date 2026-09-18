import 'package:flutter/material.dart';

import '../data/partner_week_tips.dart';
import '../services/partner_service.dart';
import '../services/settings_service.dart' show themeById;
import '../theme/app_theme.dart';

/// Pestaña "Consejos" de PartnerHubScreen: qué puede estar sintiendo la
/// dueña del embarazo esta semana y cómo su pareja/socia puede ayudarla —
/// contenido en partner_week_tips.dart (distinto del que ve la propia
/// dueña en pregnancy_week_info.dart, que está escrito desde su punto de
/// vista, no el del acompañante).
///
/// Calcula la semana actual con la MISMA fórmula que PregnancyTrackingScreen
/// (a partir del LMP compartido por la dueña, ver PartnerService
/// .watchPregnancyData) para que el consejo mostrado siempre corresponda a
/// la semana real, no a una por defecto.
class PartnerTipsScreen extends StatelessWidget {
  final String ownerUid;
  final String themeId;

  const PartnerTipsScreen({super.key, required this.ownerUid, required this.themeId});

  @override
  Widget build(BuildContext context) {
    final primary = Color(themeById(themeId).primary);
    final primaryLight = Color(themeById(themeId).primaryLight);

    return StreamBuilder<PartnerPregnancyData?>(
      stream: PartnerService().watchPregnancyData(ownerUid),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null || !data.enabled || data.lmp == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Cuando tu pareja active y comparta su seguimiento de embarazo, aquí verás consejos para acompañarla en cada semana.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: AppColors.textMuted, height: 1.4),
              ),
            ),
          );
        }

        final today = DateTime.now();
        final todayMidnight = DateTime(today.year, today.month, today.day);
        final lmp = data.lmp!;
        final rawDaysSince = todayMidnight.difference(DateTime(lmp.year, lmp.month, lmp.day)).inDays;
        final daysSince = rawDaysSince < 0 ? 0 : rawDaysSince;
        // +1: misma corrección que en PregnancyTrackingScreen — "semana"
        // 1-indexada (el día 0 desde la FUM es "semana 1", no "semana 0").
        // Antes de esta corrección esta pantalla mostraba una semana por
        // detrás de la que realmente ve la dueña del embarazo, salvo en el
        // primerísimo día (donde el `.clamp(1, ...)` lo tapaba). Bug
        // encontrado en la auditoría previa a publicación.
        final currentWeek = ((daysSince / 7).floor() + 1).clamp(1, data.isTwins ? 37 : 40);
        final currentTip = partnerWeekTipFor(currentWeek);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primary.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite, color: primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Semana $currentWeek — ahora mismo',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Qué puede estar sintiendo', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text(currentTip.whatSheMayFeel, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4)),
                  const SizedBox(height: 14),
                  const Text('Cómo puedes ayudar', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text(currentTip.howToHelp, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Todas las semanas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
            ...partnerWeekTipList.map((t) => _weekRow(t, isCurrent: t.week == currentWeek, primary: primary)),
          ],
        );
      },
    );
  }

  Widget _weekRow(PartnerWeekTip t, {required bool isCurrent, required Color primary}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent ? primary.withOpacity(0.08) : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isCurrent ? primary : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Semana ${t.week}',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: isCurrent ? primary : AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(t.whatSheMayFeel, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.3)),
          const SizedBox(height: 4),
          Text(t.howToHelp, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.3, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

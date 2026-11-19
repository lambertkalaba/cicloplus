import 'package:flutter/material.dart';

import '../cicloplus_host.dart';
import '../cicloplus_links.dart';
import '../data/store.dart';
import '../strings.dart';
import '../widgets/ui.dart';
import '../../services/settings_service.dart';

/// Fertilidad: usa exactamente el mismo cálculo que Hoy y el Calendario
/// (ovulación = ciclo medio − 14; ventana = 5 días antes hasta 1 después).
class FertilityScreen extends StatelessWidget {
  const FertilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final s = AppStore.instance;
        final today = dateOnly(DateTime.now());
        final ov = s.nextOvulation;
        final inWindow = s.infoFor(today).fertile;
        String dm(DateTime d) => '${d.day} ${L.monthShort(d.month).toLowerCase()}';
        return SubPage(
          title: tr('Fertilidad', 'Fertility'),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              if (ov == null)
                _box(tr('Registra tu regla para calcular tu ovulación.', 'Log your period to work out your ovulation.'))
              else ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: card(),
                  child: Column(
                    children: [
                      Text(tr('Próxima ovulación', 'Next ovulation'), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: C.muted)),
                      const SizedBox(height: 4),
                      Text(L.dateLong(ov), textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: C.pinkDark)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(color: C.pinkSoft, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          ov == today
                              ? tr('Hoy', 'Today')
                              : tr('Faltan {} días', '{} days to go').replaceFirst('{}', '${daysBetween(today, ov)}'),
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: C.pinkDark),
                        ),
                      ),
                      const Divider(height: 28),
                      Text(tr('Ventana fértil estimada', 'Estimated fertile window'),
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: C.muted)),
                      const SizedBox(height: 4),
                      Text('${dm(addDays(ov, -5))} – ${dm(addDays(ov, 1))}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF3E9B4F))),
                    ],
                  ),
                ),
                if (inWindow) ...[
                  const SizedBox(height: 12),
                  _box(tr('Hoy estás en tu ventana fértil 🌱', "You're in your fertile window today 🌱")),
                ],
              ],
              const _LhCard(),
              const SizedBox(height: 12),
              _box(tr(
                  'Tus días más fértiles son los 5 días antes de la ovulación y el día siguiente. Son estimaciones según tus registros, no un método anticonceptivo.',
                  'Your most fertile days are the 5 days before ovulation and the day after. These are estimates based on your logs, not a method of contraception.')),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: card(),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.science_rounded, color: C.pink),
                      title: Text(tr('Test de ovulación', 'Ovulation test'), style: const TextStyle(fontWeight: FontWeight.w800)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        await CP.openOvulationTest(context);
                        if (context.mounted) (context as Element).markNeedsBuild();
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.thermostat_rounded, color: C.pink),
                      title: Text(tr('Temperatura basal', 'Basal temperature'), style: const TextStyle(fontWeight: FontWeight.w800)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => CicloYo.field(context, 'temperature'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _box(String text) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(color: C.pinkBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.pinkLine)),
        child: Text(text, style: const TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w600, color: C.text)),
      );
}


/// Si hay un test de ovulación positivo o con pico de LH de los últimos
/// 2 días, avisa de que la ovulación es inminente (24–36 h).
class _LhCard extends StatelessWidget {
  const _LhCard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OvulationTestEntry>>(
      future: SettingsService().loadOvulationTests(),
      builder: (context, snap) {
        final today = dateOnly(DateTime.now());
        final recent = (snap.data ?? const <OvulationTestEntry>[]).where((t) {
          final d = dateOnly(t.date);
          return t.result != 'negative' && !d.isAfter(today) && daysBetween(d, today) <= 2;
        }).toList();
        if (recent.isEmpty) return const SizedBox.shrink();
        final t = recent.first;
        final peak = t.result == 'peak';
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBFE3CB)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🧪', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  (peak
                          ? tr('Pico de LH el {}: lo más probable es que ovules en las próximas 24–36 horas. ¡Son tus días más fértiles! 🌱',
                              'LH peak on {}: you will most likely ovulate in the next 24–36 hours. These are your most fertile days! 🌱')
                          : tr('Test positivo el {}: tu ovulación está muy cerca. Tus días más fértiles son hoy y mañana 🌱',
                              'Positive test on {}: your ovulation is very close. Your most fertile days are today and tomorrow 🌱'))
                      .replaceFirst('{}', L.dateShort(dateOnly(t.date))),
                  style: const TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w700, color: Color(0xFF235C37)),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

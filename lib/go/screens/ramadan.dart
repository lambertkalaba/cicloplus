import 'package:flutter/material.dart';

import '../data/store.dart';
import '../services/ramadan.dart';
import '../services/traditions.dart';
import '../strings.dart';
import '../widgets/ui.dart';

/// Modo Ramadán: fechas, días de regla en Ramadán y días por recuperar.
class RamadanScreen extends StatelessWidget {
  const RamadanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rm = Ramadan.instance..ensureLoaded();
    return SubPage(
      title: tr('Ramadán', 'Ramadan'),
      child: ListenableBuilder(
        listenable: Listenable.merge([rm, AppStore.instance]),
        builder: (context, _) {
          final today = dateOnly(DateTime.now());
          final r = rm.currentOrNext(today);
          final active = r != null && r.contains(today);
          final last = rm.debtRamadan;
          final pending = rm.pending;
          final madeToday = Ramadan.madeUpOn(today);
          final predicted = r != null && !active ? rm.predictedPeriodDays(r) : const <DateTime>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              // ── Fechas ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: card(),
                child: Row(
                  children: [
                    const Text('🌙', style: TextStyle(fontSize: 44)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r == null ? tr('Ramadán', 'Ramadan') : '${tr('Ramadán', 'Ramadan')} ${r.start.year}',
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: C.text)),
                          if (r != null) ...[
                            const SizedBox(height: 2),
                            Text(Ramadan.range(r), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: C.muted)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: C.pinkSoft, borderRadius: BorderRadius.circular(12)),
                              child: Text(rm.status(today), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: C.pinkDark)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (predicted.isNotEmpty) ...[
                const SizedBox(height: 12),
                _note(
                  '🩸',
                  tr('Según tu ciclo, tu regla podría coincidir con el Ramadán: {}.', 'Based on your cycle, your period may fall during Ramadan: {}.')
                      .replaceFirst('{}', '${predicted.first.day} ${L.monthShort(predicted.first.month).toLowerCase()} – ${predicted.last.day} ${L.monthShort(predicted.last.month).toLowerCase()}'),
                ),
              ],
              if (active) ...[
                const SizedBox(height: 12),
                _note('🩸', tr('Días de regla en este Ramadán: {}', 'Period days this Ramadan: {}').replaceFirst('{}', '${rm.periodDays(r)}')),
              ],
              // ── Días por recuperar ──
              if (last != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: card(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('Días por recuperar', 'Days to make up'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.text)),
                      const SizedBox(height: 2),
                      Text('${tr('Ramadán', 'Ramadan')} ${last.start.year}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.muted)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _num('$pending', tr('por recuperar', 'to make up'), C.pinkDark),
                          _num('${rm.periodDays(last)}', tr('días de regla', 'period days'), C.text),
                          _num('${rm.madeUpAfter(last)}', tr('recuperados', 'made up'), const Color(0xFF3E9B4F)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (!active)
                        PinkButton(
                          label: madeToday ? tr('Hoy ya lo has recuperado ✓', 'Made up today ✓') : tr('Hoy he recuperado un día', 'I made up a day today'),
                          icon: madeToday ? Icons.undo_rounded : Icons.check_rounded,
                          outlined: madeToday,
                          onTap: () => Ramadan.setMadeUp(today, !madeToday),
                        ),
                    ],
                  ),
                ),
              ],
              // ── Ajustes ──
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 6, 12, 10),
                decoration: card(),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr('Mostrar en Hoy', 'Show on Today'), style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(tr('Una tarjeta en Hoy durante el Ramadán y mientras te queden días por recuperar.',
                          'A card on Today during Ramadan and while you have days to make up.')),
                      value: rm.enabled,
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF2FB45A),
                      onChanged: rm.setEnabled,
                    ),
                    const Divider(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr('Ajustar el primer día', 'Adjust the first day'), style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text(tr('Puede cambiar un día según tu país.', 'It can change by a day depending on your country.'),
                                  style: const TextStyle(fontSize: 12, color: C.muted)),
                            ],
                          ),
                        ),
                        Stepper2(value: rm.offset, min: -2, max: 2, onChanged: rm.setOffset),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: Text(tr('Días del Ramadán', 'Days of Ramadan'), style: const TextStyle(fontWeight: FontWeight.w800))),
                        Stepper2(value: rm.days, min: 29, max: 30, suffix: ' d', onChanged: rm.setDays),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _note(
                'ℹ️',
                tr('Los días de regla no se ayunan y se recuperan después. CicloPlus los cuenta con los días de regla que registras.',
                    'Period days are not fasted and are made up later. CicloPlus counts them from the period days you log.'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _num(String v, String label, Color color) => Expanded(
        child: Column(
          children: [
            Text(v, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: C.muted)),
          ],
        ),
      );

  Widget _note(String emoji, String text) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(color: C.pinkBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.pinkLine)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w600, color: C.text))),
          ],
        ),
      );
}

/// Tarjeta de Hoy: estado del Ramadán y días por recuperar.
class RamadanCard extends StatelessWidget {
  const RamadanCard({super.key});

  @override
  Widget build(BuildContext context) {
    final rm = Ramadan.instance..ensureLoaded();
    Traditions.instance.ensureLoaded();
    return ListenableBuilder(
      listenable: Listenable.merge([rm, Traditions.instance]),
      builder: (context, _) {
        if (!rm.showOnToday) return const SizedBox.shrink();
        final today = dateOnly(DateTime.now());
        final r = rm.currentOrNext(today);
        final active = r != null && r.contains(today);
        final soon = r != null && !active && r.start.difference(today).inDays <= 14;
        final pending = rm.pending;
        final sub = active || soon
            ? rm.status(today)
            : tr('Te quedan {} días por recuperar', 'You have {} days to make up').replaceFirst('{}', '$pending');
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RamadanScreen())),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              decoration: card(),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(color: Color(0xFFEDE7FF), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Text('🌙', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r == null ? tr('Ramadán', 'Ramadan') : '${tr('Ramadán', 'Ramadan')} ${r.start.year}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: C.text)),
                        const SizedBox(height: 2),
                        Text(sub, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.pinkDark)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: C.muted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

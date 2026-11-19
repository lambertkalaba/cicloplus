import 'package:flutter/material.dart';

import '../data/store.dart';
import '../services/traditions.dart';
import '../strings.dart';
import '../widgets/ui.dart';
import 'ramadan.dart';
import '../services/ramadan.dart';

/// Tradiciones: opcional y discreto. Se guarda solo en el móvil.
class TraditionsScreen extends StatelessWidget {
  const TraditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Traditions.instance..ensureLoaded();
    return SubPage(
      title: tr('Tradiciones', 'Traditions'),
      child: ListenableBuilder(
        listenable: Listenable.merge([t, AppStore.instance]),
        builder: (context, _) {
          Widget option(String id, String emoji, String title, String sub) {
            final sel = t.id == id;
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final before = t.id;
                await t.setId(id);
                if (id == 'muslim' && before != 'muslim' && context.mounted) _michiHello(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: C.text)),
                          Text(sub, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: C.muted)),
                        ],
                      ),
                    ),
                    Icon(sel ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        color: sel ? C.pink : C.muted),
                  ],
                ),
              ),
            );
          }

          final santo = t.santo;
          final next = t.nextSanto();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _note('🔒', tr('Elige una opción para ver fechas especiales. Se guarda solo en tu móvil y no la recibimos.',
                  'Pick an option to see special dates. It is saved only on your phone and we never receive it.')),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: card(),
                child: Column(
                  children: [
                    option('none', '⚪', tr('Ninguna', 'None'), tr('Sin fechas especiales', 'No special dates')),
                    const Divider(height: 1),
                    option('muslim', '🌙', tr('Musulmana', 'Muslim'),
                        tr('Ramadán: días de regla y días por recuperar', 'Ramadan: period days and days to make up')),
                    const Divider(height: 1),
                    option('christian', '🎉', tr('Cristiana', 'Christian'),
                        tr('Te felicitamos el día de tu santo', 'We wish you a happy name day')),
                  ],
                ),
              ),
              if (t.muslim) ...[
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RamadanScreen())),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                    decoration: card(),
                    child: Row(
                      children: [
                        const Text('🌙', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr('Ramadán', 'Ramadan'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.text)),
                              Text(tr('Días de regla y días por recuperar', 'Period days and days to make up'),
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: C.muted)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: C.muted),
                      ],
                    ),
                  ),
                ),
              ],
              if (t.christian) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: card(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 30)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tr('Tu santo', 'Your name day'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.text)),
                                const SizedBox(height: 2),
                                Text(
                                  santo == null
                                      ? tr('No encontramos tu santo. Elige el día.', 'We could not find your name day. Choose the day.')
                                      : '${santo.$2} ${L.monthShort(santo.$1).toLowerCase()}'
                                          '${next != null && next == dateOnly(DateTime.now()) ? ' · ${tr('¡Feliz santo! 🎉', 'Happy name day! 🎉')}' : ''}',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: santo == null ? C.muted : C.pinkDark),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      PinkButton(
                        label: tr('Elegir día', 'Choose day'),
                        icon: Icons.event_rounded,
                        outlined: santo != null,
                        onTap: () async {
                          final now = DateTime.now();
                          final init = santo == null ? now : DateTime(now.year, santo.$1, santo.$2);
                          final d = await showDatePicker(
                            context: context,
                            initialDate: init,
                            firstDate: DateTime(now.year, 1, 1),
                            lastDate: DateTime(now.year, 12, 31),
                          );
                          if (d != null) await t.setSanto(d.month, d.day);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static void _michiHello(BuildContext context) {
    Ramadan.instance.ensureLoaded();
    Ramadan.instance.scheduleMichi();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Img('michi_happy', size: 110, fallback: Icons.pets_rounded),
              const SizedBox(height: 10),
              Text(tr('Seré tu ayudante personal en el Ramadán 🌙', "I'll be your personal Ramadan helper 🌙"),
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: C.text)),
              const SizedBox(height: 8),
              Text(
                  tr('Te avisaré unos días antes, contaré tus días de regla y te recordaré los días que te queden por recuperar.',
                      "I'll let you know a few days before, count your period days and remind you of the days you have left to make up."),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w600, color: C.muted)),
              const SizedBox(height: 16),
              PinkButton(label: tr('¡Gracias, Michi!', 'Thanks, Michi!'), onTap: () => Navigator.pop(ctx)),
            ],
          ),
        ),
      ),
    );
  }

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

/// Tarjeta de Hoy el día de su santo.
class SantoCard extends StatelessWidget {
  const SantoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Traditions.instance..ensureLoaded();
    return ListenableBuilder(
      listenable: t,
      builder: (context, _) {
        if (!t.isSantoDay(DateTime.now()) || AppStore.instance.showMichi) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: card(),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: C.pinkSoft, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Text('🎉', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.greeting, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: C.text)),
                      const SizedBox(height: 2),
                      Text(tr('Hoy es tu día. Que lo disfrutes mucho 💗', 'Today is your day. Enjoy it 💗'),
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.pinkDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

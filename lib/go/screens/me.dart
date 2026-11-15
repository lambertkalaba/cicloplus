import 'package:flutter/material.dart';

import '../data/store.dart';
import '../strings.dart';
import '../widgets/ui.dart';
import 'extras.dart';
import 'more.dart';

/// Pestaña Yo (igual que la maqueta).
class MeScreen extends StatelessWidget {
  final void Function([DateTime? day]) onRegister;
  const MeScreen({super.key, required this.onRegister});

  void _push(BuildContext context, Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final s = AppStore.instance;
        final v = s.variability;
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
          children: [
            // ── Perfil ──
            GestureDetector(
              onTap: () => _editProfile(context),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                decoration: card(),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: C.pinkSoft,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: C.pink.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: const ClipOval(child: Avatar(size: 80)),
                        ),
                        Positioned(
                          right: -4,
                          bottom: -2,
                          child: GestureDetector(
                            onTap: () => pickPhoto(context),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(gradient: pinkGradient, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                              child: const Icon(Icons.photo_camera_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name.isEmpty ? tr('Tu nombre', 'Your name') : s.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: C.text)),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFFFF1C9), borderRadius: BorderRadius.circular(10)),
                            child: Text('👑 ${tr('Cuenta Premium', 'Premium account')}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFB7791F))),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: C.text, size: 28),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ── Mi objetivo ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(Icons.track_changes_rounded, tr('Mi objetivo', 'My goal')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final g in const [
                        ['track', 'drop'],
                        ['conceive', 'g_sprout'],
                        ['pregnancy', 'g_feet'],
                      ])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _goalTile(g[0], g[1], s.goal == g[0], () => _setGoal(context, g[0])),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Mi ciclo en números ──
            GestureDetector(
              onTap: () => _push(context, const AnalysisScreen()),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(Icons.bar_chart_rounded, tr('Mi ciclo en números', 'My cycle in numbers'),
                        trailing: const Icon(Icons.chevron_right_rounded, color: C.text)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _num(const Img('n_calendar', size: 30), '${s.avgCycle} ${daysWord(s.avgCycle)}', tr('Duración media', 'Avg. length')),
                        const SizedBox(width: 8),
                        _num(const Img('n_drop', size: 30), '${s.avgPeriod} ${daysWord(s.avgPeriod)}', tr('Periodo medio', 'Avg. period')),
                        const SizedBox(width: 8),
                        _num(const Icon(Icons.waves_rounded, color: C.purple, size: 30), v == null ? '—' : '±$v ${daysWord(v)}',
                            tr('Variabilidad', 'Variability'),
                            bg: const Color(0xFFEFE7FC)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ── Enlaces ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: card(),
              child: Column(
                children: [
                  LinkRow(
                    icon: const Icon(Icons.favorite_border_rounded, color: C.pink),
                    title: tr('Mi salud', 'My health'),
                    onTap: () => _push(context, const MyHealthScreen()),
                  ),
                  LinkRow(
                    icon: const Icon(Icons.bar_chart_rounded, color: C.pink),
                    title: tr('Informes y tendencias', 'Reports & trends'),
                    onTap: () => _push(context, const ReportsHubScreen()),
                  ),
                  if (s.goal == 'pregnancy')
                    LinkRow(
                      icon: const Img('g_feet', size: 24),
                      title: tr('Mi embarazo', 'My pregnancy'),
                      onTap: () => _push(context, const PregnancyScreen()),
                    ),
                  LinkRow(
                    icon: const Icon(Icons.people_alt_rounded, color: C.pink),
                    title: tr('Mi pareja', 'My partner'),
                    onTap: () => _push(context, const PartnerScreen()),
                  ),
                  LinkRow(
                    icon: const Icon(Icons.settings_rounded, color: C.pink),
                    title: tr('Preferencias y privacidad', 'Preferences & privacy'),
                    divider: false,
                    onTap: () => _push(context, const SettingsScreen()),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setGoal(BuildContext context, String g) async {
    final s = AppStore.instance;
    if (g == 'pregnancy') {
      if (s.pregnancyStart == null) {
        final ok = await PregnancyScreen.setup(context);
        if (!ok || !context.mounted) return;
      } else {
        s.goal = g;
        await s.commit();
        if (!context.mounted) return;
      }
      _push(context, const PregnancyScreen());
      return;
    }
    s.goal = g;
    await s.commit();
  }

  Future<void> _editProfile(BuildContext context) async {
    final c = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.badge_rounded, color: C.pink),
              title: Text(tr('Cambiar mi nombre', 'Change my name'), style: const TextStyle(fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(ctx, 'name'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: C.pink),
              title: Text(tr('Cambiar mi foto', 'Change my photo'), style: const TextStyle(fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(ctx, 'photo'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (c == 'name') await editName(context);
    if (c == 'photo') await pickPhoto(context);
  }

  Widget _num(Widget icon, String value, String label, {Color? bg}) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: bg == null ? tile() : tile().copyWith(color: bg),
          child: Column(
            children: [
              SizedBox(height: 30, child: Center(child: icon)),
              const SizedBox(height: 4),
              FittedBox(child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: C.text))),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: C.text, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _goalTile(String g, String img, bool sel, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: tile(selected: sel),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (sel && g == 'track')
                const Icon(Icons.water_drop_rounded, color: Colors.white, size: 26)
              else
                Img(img, size: 26, fallback: g == 'conceive' ? Icons.spa_rounded : Icons.child_friendly_rounded),
              const SizedBox(height: 4),
              Text(goalName(g),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: sel ? Colors.white : C.text, height: 1.1)),
            ],
          ),
        ),
      );
}

import 'package:flutter/material.dart';

import '../data/store.dart';
import '../strings.dart';
import '../cicloplus_links.dart';
import '../widgets/ui.dart';
import 'calendar.dart';
import 'extras.dart';
import 'me.dart';
import 'more.dart';
import 'register.dart';
import 'reminders.dart';
import 'today.dart';

/// Estructura principal: cabecera verde, pestañas y botón + central.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => ShellState();
}

class ShellState extends State<Shell> {
  int _tab = 0;
  final _scaffold = GlobalKey<ScaffoldState>();

  void go(int tab) => setState(() => _tab = tab);

  void openRegister([DateTime? day]) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegisterScreen(day: day ?? DateTime.now())));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayScreen(onRegister: openRegister, onCalendar: () => go(1)),
      CalendarScreen(onRegister: openRegister),
      const RemindersScreen(),
      MeScreen(onRegister: openRegister),
    ];
    return Scaffold(
      key: _scaffold,
      drawer: AppDrawer(onTab: (t) {
        Navigator.of(context).pop();
        go(t);
      }),
      body: PinkBackground(
        child: Column(
          children: [
            GreenHeader(
              title: _tab == 3 ? tr('Yo', 'Me') : null,
              flowers: _tab == 3,
              onMenu: () => _scaffold.currentState?.openDrawer(),
              onBell: () => go(2),
            ),
            Expanded(child: IndexedStack(index: _tab, children: pages)),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(
        index: _tab,
        onTap: go,
        onPlus: () => openRegister(),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onPlus;
  const _BottomBar({required this.index, required this.onTap, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    final items = [
      [Icons.home_outlined, Icons.home_rounded, tr('Hoy', 'Today')],
      [Icons.calendar_month_outlined, Icons.calendar_month_rounded, tr('Calendario', 'Calendar')],
      [Icons.notifications_none_rounded, Icons.notifications_rounded, tr('Recordatorios', 'Reminders')],
      [Icons.person_outline_rounded, Icons.person_rounded, tr('Yo', 'Me')],
    ];
    Widget tab(int i) {
      final sel = i == index;
      final it = items[i];
      return Expanded(
        child: InkWell(
          onTap: () => onTap(i),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon((sel ? it[1] : it[0]) as IconData, color: sel ? C.pink : C.muted, size: 25),
              const SizedBox(height: 2),
              Text(it[2] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.w800 : FontWeight.w600, color: sel ? C.pink : C.muted)),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: sel ? 18 : 0,
                height: 3,
                decoration: BoxDecoration(color: C.pink, borderRadius: BorderRadius.circular(2)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: const Color(0xFFB0306A).withOpacity(0.12), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              tab(0),
              tab(1),
              SizedBox(
                width: 76,
                child: Center(
                  child: GestureDetector(
                    onTap: onPlus,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: pinkGradient,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: C.pink.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 5))],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 34),
                    ),
                  ),
                ),
              ),
              tab(2),
              tab(3),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menú lateral.
class AppDrawer extends StatelessWidget {
  final ValueChanged<int> onTab;
  const AppDrawer({super.key, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    void push(Widget w) {
      Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    }

    return Drawer(
      backgroundColor: C.pinkBg,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 18, 18, 18),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.emerald, C.emeraldDark])),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: C.pinkSoft,
                  child: const ClipOval(child: Avatar(size: 60)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Logo(),
                      const SizedBox(height: 4),
                      Text(s.name.isEmpty ? tr('¡Hola!', 'Hi!') : s.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _item(Icons.home_rounded, tr('Hoy', 'Today'), () => onTab(0)),
          _item(Icons.calendar_month_rounded, tr('Calendario', 'Calendar'), () => onTab(1)),
          _item(Icons.edit_note_rounded, tr('Registrar mi día', 'Log my day'), () {
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegisterScreen(day: DateTime.now())));
          }),
          _item(Icons.notifications_rounded, tr('Recordatorios', 'Reminders'), () => onTab(2)),
          _item(Icons.person_rounded, tr('Yo', 'Me'), () => onTab(3)),
          const Divider(indent: 16, endIndent: 16),
          _item(Icons.water_drop_rounded, tr('Periodo y ciclo', 'Period & cycle'), () => push(const PeriodCycleScreen())),
          _item(Icons.favorite_rounded, tr('Mi salud', 'My health'), () => push(const MyHealthScreen())),
          _item(Icons.bar_chart_rounded, tr('Análisis del ciclo', 'Cycle analysis'), () => push(const AnalysisScreen())),
          _item(Icons.show_chart_rounded, tr('Tendencias', 'Trends'), () => push(const TrendsScreen())),
          _item(Icons.menu_book_rounded, tr('Mi diario', 'My diary'), () => push(const DiaryScreen())),
          _item(Icons.people_alt_rounded, tr('Mi pareja', 'My partner'), () { Navigator.of(context).pop(); CP.openPartner(context); }),
          _item(Icons.child_friendly_rounded, tr('Embarazo', 'Pregnancy'), () { Navigator.of(context).pop(); CP.openPregnancy(context); }),
          _item(Icons.insights_rounded, tr('Informe del ciclo', 'Cycle report'), () => push(const ReportScreen())),
          _item(Icons.history_rounded, tr('Cronología', 'Timeline'), () => push(const TimelineScreen())),
          _item(Icons.science_rounded, tr('Test de ovulación', 'Ovulation test'), () { Navigator.of(context).pop(); CP.openOvulationTest(context); }),
          _item(Icons.forum_rounded, tr('Comunidad', 'Community'), () { Navigator.of(context).pop(); CP.openForum(context); }),
          _item(Icons.workspace_premium_rounded, tr('CicloPlus Premium', 'CicloPlus Premium'), () { Navigator.of(context).pop(); CP.openPremium(context); }),
          _item(Icons.settings_rounded, tr('Ajustes y privacidad', 'Settings & privacy'), () => push(const SettingsScreen())),
        ],
      ),
    );
  }

  Widget _item(IconData i, String t, VoidCallback f) => ListTile(
        leading: Icon(i, color: C.pink),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, color: C.text)),
        onTap: f,
      );
}

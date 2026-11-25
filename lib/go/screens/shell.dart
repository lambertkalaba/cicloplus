import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/store.dart';
import '../strings.dart';
import '../cicloplus_host.dart';
import '../widgets/avatar_maker.dart';
import '../widgets/ui.dart';
import 'calendar.dart';
import 'extras.dart';
import 'me.dart';
import 'register.dart';
import 'michi_search.dart';
import 'reminders.dart';

/// Estructura principal: cabecera verde, pestañas y botón + central.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => ShellState();
}

class ShellState extends State<Shell> {
  /// Para que el buscador pueda cambiar de pestaña.
  static ShellState? current;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    current = this;
  }

  @override
  void dispose() {
    if (current == this) current = null;
    super.dispose();
  }

  final _scaffold = GlobalKey<ScaffoldState>();

  void go(int tab) => setState(() => _tab = tab);

  void openRegister([DateTime? day]) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegisterScreen(day: day ?? DateTime.now())));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CicloToday(onRegister: openRegister),
      CalendarScreen(onRegister: openRegister),
      const RemindersScreen(),
      MeScreen(onRegister: openRegister),
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _back(),
      child: Scaffold(
      key: _scaffold,
      body: PinkBackground(
        child: Column(
          children: [
            GreenHeader(
              title: _tab == 3 ? tr('Yo', 'Me') : null,
              flowers: _tab == 3,
              onMenu: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MichiSearchScreen())),
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
    ),
    );
  }

  bool _leaving = false;

  /// Atrás: desde otra pestaña vuelve a Hoy; en Hoy el avatar dice adiós.
  void _back() {
    if (_tab != 0) {
      go(0);
      return;
    }
    if (_leaving) return;
    _leaving = true;
    AvatarBus.bye.value++;
    Future.delayed(const Duration(milliseconds: 1700), () {
      _leaving = false;
      SystemNavigator.pop();
    });
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
        boxShadow: [BoxShadow(color: C.t(0xFFB0306A).withOpacity(0.12), blurRadius: 16, offset: const Offset(0, -4))],
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
    final goal = s.goal;
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
          if (goal != 'pregnancy') _item(Icons.water_drop_rounded, tr('Periodo y ciclo', 'Period & cycle'), () => push(const PeriodCycleScreen())),
          _item(Icons.history_rounded, tr('Cronología', 'Timeline'), () => push(const TimelineScreen())),
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

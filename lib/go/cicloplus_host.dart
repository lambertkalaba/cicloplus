import 'package:flutter/material.dart';

import '../models/day_entry.dart';
import '../screens/field_detail_screen.dart';
import '../screens/quick_summary_screen.dart';
import '../screens/review_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/today_screen.dart';
import '../services/settings_service.dart';
import 'cicloplus_links.dart';
import 'data/store.dart';
import 'go_root.dart';
import 'screens/shell.dart' show ShellState;
import 'screens/today.dart' as go;
import 'widgets/cat_card.dart';

/// Datos que necesitan las pantallas de CicloPlus que se conservan (Hoy y
/// Configuración). Los días salen de la misma nube que usa el diseño nuevo,
/// así las dos partes ven siempre lo mismo.
class CicloData extends ChangeNotifier {
  CicloData._();
  static final CicloData instance = CicloData._();

  PregnancySettings pregnancy = const PregnancySettings();
  bool irregular = false;
  String userGoal = 'period';
  int? selfCycle;
  int? selfPeriod;
  String themeId = 'pink';

  Map<String, DayEntry> get data => {
        for (final e in AppStore.instance.cloudRaw.entries) e.key: DayEntry.fromJson(e.value),
      };

  Future<void> load() async {
    final s = SettingsService();
    try {
      pregnancy = await s.loadPregnancySettings();
      irregular = await s.loadIrregularCycleMode();
      userGoal = await s.loadUserGoal();
      selfCycle = await s.loadConceiveAvgCycleLength();
      selfPeriod = await s.loadConceiveAvgPeriodLength();
      themeId = await s.loadThemeId();
    } catch (_) {}
    notifyListeners();
  }

  /// Guarda lo que cambió en una pantalla de CicloPlus.
  Future<void> onDataChanged(Map<String, DayEntry> updated) async {
    final before = data;
    final changes = <String, Map<String, dynamic>?>{};
    for (final k in {...before.keys, ...updated.keys}) {
      final n = updated[k];
      if (n == null || n.isEmpty) {
        if (before.containsKey(k)) changes[k] = null;
      } else {
        final nj = n.toJson();
        final oj = before[k]?.toJson();
        if (oj == null || oj.toString() != nj.toString()) changes[k] = nj;
      }
    }
    await AppStore.instance.putCloudDays(changes);
    notifyListeners();
  }
}

/// Pestaña Hoy: la de CicloPlus, con todo lo que tenía.
class CicloToday extends StatefulWidget {
  const CicloToday({super.key, required this.onRegister});

  final void Function([DateTime? day]) onRegister;

  @override
  State<CicloToday> createState() => _CicloTodayState();
}

class _CicloTodayState extends State<CicloToday> {
  @override
  void initState() {
    super.initState();
    CicloData.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    final user = GoSession.user;
    if (user == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: Listenable.merge([AppStore.instance, CicloData.instance]),
      builder: (context, _) {
        final c = CicloData.instance;
        return TodayScreen(
          data: c.data,
          pregnancy: c.pregnancy,
          irregularCycleMode: c.irregular,
          selfReportedCycleLen: c.selfCycle,
          selfReportedPeriodLen: c.selfPeriod,
          themeId: c.themeId,
          userId: user.id,
          userEmail: user.email,
          userGoal: c.userGoal,
          onDataChanged: c.onDataChanged,
          onOpenRegister: () => widget.onRegister(),
          petCard: AppStore.instance.showMichi
              ? CatCard(onFeed: () => widget.onRegister())
              : (AppStore.instance.showGarden ? null : const SizedBox.shrink()),
          topSection: go.TodayScreen(
            embedded: true,
            onRegister: widget.onRegister,
            onCalendar: () => context.findAncestorStateOfType<ShellState>()?.go(1),
          ),
        );
      },
    );
  }
}

/// Configuración: la de CicloPlus.
Future<void> openCicloSettings(BuildContext context) async {
  final user = GoSession.user;
  if (user == null) return;
  final c = CicloData.instance;
  await c.load();
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => SettingsScreen(
      userId: user.id,
      onThemeChanged: (id) {
        c.themeId = id;
        c.load();
      },
      data: c.data,
      onDataChanged: c.onDataChanged,
      onSignOut: () {
        Navigator.of(context).popUntil((r) => r.isFirst);
        GoSession.onSignOut?.call();
      },
    ),
  ));
  // Al volver, refresca embarazo/objetivo y lo pasa al diseño nuevo.
  await c.load();
  await CP.loadFromCicloPlus();
}

/// Pantallas del antiguo "Yo" de CicloPlus que el diseño nuevo no tenía.
class CicloYo {
  CicloYo._();

  static Future<void> _push(BuildContext context, Widget w) async {
    await CicloData.instance.load();
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
  }

  /// Las pantallas antiguas usan 0 Hoy, 1 Calendario, 2 Registrar, 3 Recordatorio, 4 Yo.
  static void _goTab(BuildContext context, int oldTab) {
    final shell = context.findAncestorStateOfType<ShellState>();
    Navigator.of(context).popUntil((r) => r.isFirst);
    if (shell == null) return;
    switch (oldTab) {
      case 2:
        shell.openRegister();
      case 3:
        shell.go(2);
      case 4:
        shell.go(3);
      default:
        shell.go(oldTab);
    }
  }

  static Future<void> field(BuildContext context, String key) {
    final c = CicloData.instance;
    return _push(
      context,
      FieldDetailScreen(themeId: c.themeId, data: c.data, fieldKey: key, onDataChanged: c.onDataChanged, userGoal: c.userGoal),
    );
  }

  static Future<void> summary(BuildContext context, String key) {
    final c = CicloData.instance;
    return _push(
      context,
      QuickSummaryScreen(
        summaryKey: key,
        themeId: c.themeId,
        data: c.data,
        irregularCycleMode: c.irregular,
        selfReportedCycleLen: c.selfCycle,
        selfReportedPeriodLen: c.selfPeriod,
        pregnancy: c.pregnancy,
        onNavigateToTab: (t) => _goTab(context, t),
      ),
    );
  }

  static Future<void> review(BuildContext context) =>
      _push(context, ReviewScreen(data: CicloData.instance.data, themeId: CicloData.instance.themeId));

  static Future<void> stats(BuildContext context) {
    final c = CicloData.instance;
    return _push(
      context,
      StatsScreen(data: c.data, themeId: c.themeId, inPregnancyMode: c.pregnancy.enabled && c.pregnancy.lmp != null),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/locale_controller.dart';
import '../services/settings_service.dart';
import '../services/subscription_service.dart';
import 'cicloplus_host.dart';
import 'cicloplus_links.dart';
import 'upgrade.dart';
import 'data/store.dart';
import 'screens/onboarding.dart';
import 'screens/shell.dart';
import 'services/notifications.dart';
import 'strings.dart';
import 'widgets/ui.dart';

/// Sesión actual de CicloPlus, para que las pantallas del diseño nuevo
/// puedan abrir las funciones que dependen de la cuenta (perfil, premium,
/// pareja, cerrar sesión…).
class GoSession {
  GoSession._();
  static AppUser? user;
  static Future<void> Function()? onSignOut;

  /// Suscripción (RevenueCat), igual que en la versión anterior.
  static final SubscriptionService subscription = SubscriptionService();
  static final ValueNotifier<bool> premium = ValueNotifier(false);

  static Future<void> refreshPremium() async {
    final u = user;
    if (u == null) return;
    try {
      await subscription.refreshCachedStatus();
      premium.value = subscription.hasAccess(u);
    } catch (_) {}
  }
}

/// Raíz del diseño nuevo de CicloPlus. Se muestra cuando la usuaria ya ha
/// iniciado sesión (ver AuthGate) y sustituye a la antigua MainTabScreen.
class GoRoot extends StatefulWidget {
  const GoRoot({super.key, required this.user, required this.onSignOut});

  final AppUser user;
  final Future<void> Function() onSignOut;

  @override
  State<GoRoot> createState() => _GoRootState();
}

class _GoRootState extends State<GoRoot> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    GoSession.user = widget.user;
    GoSession.onSignOut = _signOut;
    _start();
  }

  Future<void> _start() async {
    // Idioma: de momento el diseño nuevo tiene español e inglés.
    L.setLang(LocaleController.instance.languageCode);
    LocaleController.instance.addListener(_syncLang);
    final store = AppStore.instance;
    String? profileName;
    try {
      profileName = await SettingsService().loadProfileName().timeout(const Duration(seconds: 4));
    } catch (_) {}
    await store.attachUser(widget.user.id, profileName: profileName);
    try {
      await CP.loadFromCicloPlus().timeout(const Duration(seconds: 5));
    } catch (_) {}
    await Upgrade.migrateReminders();
    await Upgrade.migrateScene();
    await Upgrade.fixTheme();
    store.removeListener(Upgrade.syncProfileName);
    store.addListener(Upgrade.syncProfileName);
    store.removeListener(Upgrade.updateWidget);
    store.addListener(Upgrade.updateWidget);
    Upgrade.updateWidget();
    _lastGoal = store.goal;
    _lastPregnancy = store.pregnancyStart;
    store.addListener(_syncGoal);
    // La app se muestra ya; Premium y recordatorios se preparan detrás
    // (no hace falta esperarlos para enseñar la pantalla).
    if (mounted) setState(() => _ready = true);
    _startBackground(store);
  }

  Future<void> _startBackground(AppStore store) async {
    try {
      await GoSession.subscription.configure(firebaseUid: widget.user.id);
      await GoSession.refreshPremium();
    } catch (_) {}
    try {
      await Notifier.instance.init();
      store.removeListener(Notifier.instance.reschedule);
      store.addListener(Notifier.instance.reschedule);
      await Notifier.instance.reschedule();
    } catch (_) {}
  }

  String? _lastGoal;
  DateTime? _lastPregnancy;

  /// Si cambia el objetivo o el embarazo en el diseño nuevo, se guarda
  /// también donde lo leen las pantallas de CicloPlus (pareja, embarazo…).
  void _syncGoal() {
    final s = AppStore.instance;
    if (s.goal == _lastGoal && s.pregnancyStart == _lastPregnancy) return;
    _lastGoal = s.goal;
    _lastPregnancy = s.pregnancyStart;
    // Recarga lo que leen las pantallas de CicloPlus (Hoy, estadísticas…)
    // para que el cambio de objetivo se vea al momento.
    CP.syncPregnancyToCicloPlus().then((_) => CicloData.instance.load());
  }

  @override
  void dispose() {
    AppStore.instance.removeListener(_syncGoal);
    LocaleController.instance.removeListener(_syncLang);
    super.dispose();
  }

  void _syncLang() => L.setLang(LocaleController.instance.languageCode);

  Future<void> _signOut() async {
    AppStore.instance.removeListener(_syncGoal);
    AppStore.instance.removeListener(Notifier.instance.reschedule);
    AppStore.instance.detachUser();
    await widget.onSignOut();
  }

  @override
  Widget build(BuildContext context) {
    // El color elegido por la usuaria: al cambiarlo se reconstruye todo.
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        C.setTheme(AppStore.instance.themeColor);
        return KeyedSubtree(key: ValueKey('theme_${C.theme}'), child: _themed(context));
      },
    );
  }

  Widget _themed(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: C.pink, primary: C.pink, secondary: C.emerald),
      scaffoldBackgroundColor: C.pinkBg,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.pink : null),
      ),
    );
    return Theme(
      data: theme,
      child: !_ready
          ? Scaffold(backgroundColor: C.pinkBg, body: Center(child: CircularProgressIndicator(color: C.pink)))
          : ListenableBuilder(
              listenable: AppStore.instance,
              builder: (context, _) => AppStore.instance.onboarded ? const Shell() : const OnboardingScreen(),
            ),
    );
  }
}

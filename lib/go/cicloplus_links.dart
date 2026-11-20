import 'package:flutter/material.dart';

import '../screens/account_screen.dart';
import '../screens/invite_partner_screen.dart';
import '../screens/lock_screen.dart';
import '../screens/partner_welcome_screen.dart';
import '../screens/ovulation_test_screen.dart';
import '../screens/paywall_screen.dart';
import '../screens/pregnancy_tracking_screen.dart';
import '../services/settings_service.dart';
import 'data/store.dart';
import 'go_root.dart';
import 'screens/more.dart' show PregnancyScreen;
import 'strings.dart';
import 'widgets/premium.dart' show PremiumActiveScreen;

/// Accesos desde el diseño nuevo a las funciones que solo tenía CicloPlus
/// (cuenta, premium, pareja conectada, embarazo, test de ovulación, foro y
/// bloqueo con PIN). Se reutilizan las pantallas originales de CicloPlus.
class CP {
  CP._();

  static Future<T?> _push<T>(BuildContext context, Widget w, {bool dialog = false}) =>
      Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => w, fullscreenDialog: dialog));

  static Future<void> openAccount(BuildContext context) async {
    final user = GoSession.user;
    if (user == null) return;
    await _push(context, AccountScreen(user: user, themeId: 'pink', subscriptionService: GoSession.subscription));
    await GoSession.refreshPremium();
  }

  static Future<void> openPremium(BuildContext context) async {
    if (GoSession.premium.value) {
      await _push(context, const PremiumActiveScreen());
      await GoSession.refreshPremium();
      return;
    }
    await _push(context, const PaywallScreen());
    await GoSession.refreshPremium();
  }

  /// Pareja de verdad (invitación con QR, chat, ver el ciclo…).
  static Future<void> openPartner(BuildContext context) async {
    final user = GoSession.user;
    if (user == null) return;
    final settings = SettingsService();
    final pregnancy = await settings.loadPregnancySettings();
    final goal = await settings.loadUserGoal();
    if (!context.mounted) return;
    await openPartnerArea(
      context,
      userId: user.id,
      userEmail: user.email,
      themeId: 'pink',
      inviteBuilder: (_) => InvitePartnerScreen(userId: user.id, userEmail: user.email, userGoal: goal, pregnancy: pregnancy),
    );
  }

  /// Seguimiento del embarazo de CicloPlus. Si todavía no está activado,
  /// primero se pide la fecha con el asistente del diseño nuevo.
  static Future<void> openPregnancy(BuildContext context) async {
    final s = AppStore.instance;
    if (s.pregnancyStart == null) {
      final ok = await PregnancyScreen.setup(context);
      if (!ok || !context.mounted) return;
    }
    await syncPregnancyToCicloPlus();
    if (!context.mounted || s.pregnancyStart == null) return;
    final pregnancy = await SettingsService().loadPregnancySettings();
    if (!context.mounted) return;
    await _push(
      context,
      PregnancyTrackingScreen(lmp: s.pregnancyStart!, themeId: 'pink', isTwins: pregnancy.isTwins),
    );
  }

  /// Mantiene el modo embarazo y el objetivo igual en los dos diseños.
  static Future<void> syncPregnancyToCicloPlus() async {
    final s = AppStore.instance;
    final settings = SettingsService();
    final old = await settings.loadPregnancySettings();
    final pregnant = s.goal == 'pregnancy' && s.pregnancyStart != null;
    await settings.savePregnancySettings(
      pregnant ? old.copyWith(enabled: true, lmp: s.pregnancyStart) : old.copyWith(enabled: false),
    );
    await settings.saveUserGoal(s.goal == 'track' ? 'period' : s.goal);
  }

  /// Al entrar: copia al diseño nuevo el embarazo/objetivo que ya tenía en CicloPlus.
  static Future<void> loadFromCicloPlus() async {
    final s = AppStore.instance;
    final settings = SettingsService();
    try {
      final pregnancy = await settings.loadPregnancySettings();
      final goal = await settings.loadUserGoal();
      if (pregnancy.enabled && pregnancy.lmp != null) {
        s.goal = 'pregnancy';
        s.pregnancyStart = pregnancy.lmp;
      } else if (goal == 'conceive') {
        s.goal = 'conceive';
      }
      await s.commit();
    } catch (_) {}
  }

  static Future<void> openOvulationTest(BuildContext context) => _push(context, const OvulationTestScreen());


  /// Activa o quita el bloqueo con PIN. Para quitarlo pide antes el PIN
  /// actual (o la huella), así nadie más puede desactivarlo.
  static Future<void> togglePin(BuildContext context) async {
    final settings = SettingsService();
    final nav = Navigator.of(context);
    if (await settings.hasPin()) {
      if (!context.mounted) return;
      final ok = await nav.push<bool>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LockScreen(
          mode: LockScreenMode.unlock,
          title: tr('Escribe tu PIN para quitarlo', 'Enter your PIN to remove it'),
          onSuccess: () => nav.pop(true),
          onCancel: () => nav.pop(false),
        ),
      ));
      if (ok != true) return;
      await settings.clearPin();
      if (context.mounted) _snack(context, tr('Bloqueo con PIN desactivado', 'PIN lock turned off'));
      return;
    }
    if (!context.mounted) return;
    final created = await nav.push<bool>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => LockScreen(
        mode: LockScreenMode.create,
        onSuccess: () => nav.pop(true),
        onCancel: () => nav.pop(false),
      ),
    ));
    if (created == true && context.mounted) _snack(context, tr('Bloqueo con PIN activado', 'PIN lock turned on'));
  }

  static void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

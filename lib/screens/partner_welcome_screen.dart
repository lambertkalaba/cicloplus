import 'dart:async';

import 'package:flutter/material.dart';

import '../go/strings.dart' show tr;
import '../services/couple_illustration_controller.dart';
import '../services/partner_service.dart';
import '../services/settings_service.dart' show themeById;
import '../theme/app_theme.dart';
import '../widgets/partner_ui.dart';
import '../widgets/read_only_info_sheet.dart';

/// Entrada a la parte de pareja desde dentro de la app. Si todavía no hay
/// nadie vinculado (ni a quien ella deja ver, ni a quien sigue), primero se
/// enseña la tarjeta de bienvenida; si ya hay alguien, va directa a
/// "Invitar a tu pareja".
Future<void> openPartnerArea(
  BuildContext context, {
  required String userId,
  required String userEmail,
  required String themeId,
  required WidgetBuilder inviteBuilder,
}) async {
  final service = PartnerService();
  var hasAnyone = false;
  try {
    final mine = await service.watchMyPartners(userId).first.timeout(const Duration(seconds: 4));
    final follow = await service.watchPregnanciesIFollow(userId).first.timeout(const Duration(seconds: 4));
    hasAnyone = mine.isNotEmpty || follow.isNotEmpty;
  } catch (_) {
    // Sin conexión: mejor ir a la pantalla completa, que ya funciona offline.
    hasAnyone = true;
  }
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => hasAnyone
        ? inviteBuilder(context)
        : PartnerWelcomeScreen(userId: userId, userEmail: userEmail, themeId: themeId, inviteBuilder: inviteBuilder),
  ));
}

/// Tarjeta de bienvenida "Comparte tu ciclo con tu pareja" (maqueta de
/// ChatGPT, pantalla 1): ilustración, 3 ventajas y dos caminos — invitar a
/// su pareja o ver el seguimiento de su pareja con un código.
class PartnerWelcomeScreen extends StatelessWidget {
  const PartnerWelcomeScreen({super.key, required this.userId, required this.userEmail, required this.themeId, required this.inviteBuilder});

  final String userId;
  final String userEmail;
  final String themeId;
  final WidgetBuilder inviteBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = themeById(themeId);
    final primary = Color(theme.primary);
    final primaryDark = Color(theme.primaryDark);
    CoupleIllustrationController.instance.load();
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F8),
      appBar: PartnerHeader(title: tr('Mi pareja', 'My partner'), primary: primary, primaryDark: primaryDark),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            decoration: PartnerUi.card(radius: 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _CoupleArt(primary: primary),
              const SizedBox(height: 12),
              Text(
                tr('Comparte tu ciclo con tu pareja', 'Share your cycle with your partner'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, height: 1.15, fontWeight: FontWeight.w900, color: primaryDark),
              ),
              const SizedBox(height: 8),
              const _GoldHeartDivider(),
              const SizedBox(height: 6),
              PartnerBenefit(
                icon: Icons.calendar_month_rounded,
                title: tr('Tu calendario, en solo lectura', 'Your calendar, read-only'),
                text: tr('Tu pareja ve tu periodo, tus días fértiles y lo que viene, sin poder cambiar nada.', 'Your partner sees your period, fertile days and what is coming, without being able to change anything.'),
                primary: primary,
              ),
              PartnerBenefit(
                icon: Icons.chat_bubble_outline_rounded,
                title: tr('Chat privado', 'Private chat'),
                text: tr('Habláis dentro de CicloPlus, solo vosotros dos.', 'You talk inside CicloPlus, just the two of you.'),
                primary: primary,
              ),
              PartnerBenefit(
                icon: Icons.favorite_border_rounded,
                title: tr('Tu lista de deseos', 'Your wish list'),
                text: tr('Apunta lo que te apetece o necesitas y tu pareja lo verá.', 'Note down what you fancy or need and your partner will see it.'),
                primary: primary,
              ),
              const SizedBox(height: 10),
              _GoldNote(text: tr('Tú decides qué ve y puedes desvincular cuando quieras.', 'You decide what they see and you can unlink whenever you like.')),
              const SizedBox(height: 18),
              PartnerButton(
                label: tr('Invitar a mi pareja', 'Invite my partner'),
                icon: Icons.favorite_rounded,
                primary: primary,
                primaryDark: primaryDark,
                onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: inviteBuilder)),
              ),
              const SizedBox(height: 10),
              PartnerOutlineButton(
                label: tr('Ver el seguimiento de mi pareja', "See my partner's tracking"),
                icon: Icons.visibility_outlined,
                primary: primary,
                onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => PartnerFollowScreen(userId: userId, userEmail: userEmail, themeId: themeId),
                )),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

/// "Ver el seguimiento de mi pareja" para quien ya tiene cuenta: la misma
/// tarjeta que ve quien entra sin cuenta, pero dentro de la app.
class PartnerFollowScreen extends StatefulWidget {
  const PartnerFollowScreen({super.key, required this.userId, required this.userEmail, required this.themeId});

  final String userId;
  final String userEmail;
  final String themeId;

  @override
  State<PartnerFollowScreen> createState() => _PartnerFollowScreenState();
}

class _PartnerFollowScreenState extends State<PartnerFollowScreen> {
  final _service = PartnerService();
  final _code = TextEditingController();
  bool _accepting = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _accepting = true;
      _error = null;
    });
    try {
      final ownerEmail = await _service.previewInvite(code);
      if (!mounted) return;
      final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(tr('¿Vincularte?', 'Link up?')),
              content: Text(tr('Vas a vincularte con $ownerEmail. Podrás ver su seguimiento (solo lectura), nunca editarlo.', "You're about to link with $ownerEmail. You'll be able to see their tracking (read-only), never edit it.")),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancelar', 'Cancel'))),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Vincularme', 'Link me'))),
              ],
            ),
          ) ??
          false;
      if (!ok) return;
      final outcome = await _service.acceptInvite(code: code, partnerUid: widget.userId, partnerEmail: widget.userEmail);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(outcome.linked ? tr('Vinculado ✓', 'Linked ✓') : tr('Solicitud enviada. Espera a que la dueña la acepte.', 'Request sent. Wait for the owner to accept it.')),
      ));
      Navigator.of(context).pop();
    } on PartnerException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = tr('Algo salió mal. Inténtalo de nuevo.', 'Something went wrong. Please try again.'));
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = themeById(widget.themeId);
    final primary = Color(theme.primary);
    final primaryDark = Color(theme.primaryDark);
    CoupleIllustrationController.instance.load();
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F8),
      appBar: PartnerHeader(title: tr('Ver seguimiento de tu pareja', "See your partner's tracking"), primary: primary, primaryDark: primaryDark),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            decoration: PartnerUi.card(radius: 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _CoupleArt(primary: primary),
              const SizedBox(height: 10),
              const _GoldHeartDivider(),
              const SizedBox(height: 6),
              PartnerBenefit(
                icon: Icons.calendar_month_rounded,
                title: tr('Su calendario, en solo lectura', 'Their calendar, read-only'),
                text: tr('Embarazo, periodo o días fértiles, según lo que comparta contigo.', 'Pregnancy, period or fertile days, depending on what they share with you.'),
                primary: primary,
              ),
              PartnerBenefit(
                icon: Icons.chat_bubble_outline_rounded,
                title: tr('Chat privado', 'Private chat'),
                text: tr('Habláis dentro de CicloPlus, solo vosotros dos.', 'You talk inside CicloPlus, just the two of you.'),
                primary: primary,
              ),
              PartnerBenefit(
                icon: Icons.favorite_border_rounded,
                title: tr('Su lista de deseos', 'Their wish list'),
                text: tr('Descubre qué le apetece o necesita en cada momento.', 'Find out what they fancy or need at any moment.'),
                primary: primary,
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: Text(tr('Pega aquí el código que te compartieron', 'Paste the code you were given here'),
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ),
                IconButton(
                  onPressed: () => showReadOnlyInfoSheet(context, primaryColor: primary, primaryLightColor: Color(theme.primaryLight)),
                  icon: const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.textMuted),
                  tooltip: tr('Qué podrás ver', "What you'll see"),
                  visualDensity: VisualDensity.compact,
                ),
              ]),
              const SizedBox(height: 6),
              PartnerField(
                controller: _code,
                hint: tr('Ej. AB3D9K', 'E.g. AB3D9K'),
                icon: Icons.confirmation_number_outlined,
                primary: primary,
                errorText: _error,
                code: true,
              ),
              const SizedBox(height: 14),
              PartnerButton(
                label: tr('Vincularme', 'Link me'),
                icon: Icons.link_rounded,
                primary: primary,
                primaryDark: primaryDark,
                loading: _accepting,
                onPressed: _accepting ? null : _accept,
              ),
              const SizedBox(height: 14),
              _GoldNote(text: tr('Solo podrás verlo, nunca editarlo. Puedes dejar de seguirlo cuando quieras.', 'You can only view it, never edit it. You can stop following whenever you like.')),
            ]),
          ),
        ],
      ),
    );
  }
}

class _CoupleArt extends StatelessWidget {
  const _CoupleArt({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        gradient: RadialGradient(colors: [primary.withOpacity(0.16), primary.withOpacity(0.0)], radius: 0.75),
      ),
      child: ListenableBuilder(
        listenable: CoupleIllustrationController.instance,
        builder: (context, _) => Image.asset(
          CoupleIllustrationController.instance.illustration.asset,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.favorite_rounded, size: 80, color: primary),
        ),
      ),
    );
  }
}

class _GoldHeartDivider extends StatelessWidget {
  const _GoldHeartDivider();

  @override
  Widget build(BuildContext context) => const Row(children: [
        Expanded(child: Divider(color: PartnerUi.goldSoft, thickness: 1.2)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.favorite_border_rounded, size: 16, color: PartnerUi.gold),
        ),
        Expanded(child: Divider(color: PartnerUi.goldSoft, thickness: 1.2)),
      ]);
}

class _GoldNote extends StatelessWidget {
  const _GoldNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: PartnerUi.goldSoft.withOpacity(0.35), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const Icon(Icons.lock_outline_rounded, size: 18, color: PartnerUi.gold),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12.5, height: 1.35, fontStyle: FontStyle.italic, color: AppColors.textPrimary)),
        ),
      ]),
    );
  }
}

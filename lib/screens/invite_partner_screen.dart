import '../go/strings.dart' show tr;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_strings.dart';
import '../models/day_entry.dart';
import '../services/cycle_predictor.dart';
import '../services/partner_service.dart';
import '../services/pending_link_service.dart';
import '../services/settings_service.dart' show PregnancySettings, SettingsService, themeById;
import '../theme/app_theme.dart';
import '../widgets/partner_ui.dart';
import '../widgets/read_only_info_sheet.dart';
import 'partner_chat_screen.dart';
import 'partner_hub_screen.dart';
import 'partner_wishes_screen.dart';

/// "Invitar a un socio": genera/comparte un código para que la pareja
/// pueda ver el embarazo en modo SOLO LECTURA, permite introducir un
/// código recibido para vincularse a otra persona, y lista los vínculos ya
/// aceptados en ambos sentidos (a quién le diste acceso / a quién sigues).
///
/// La protección real de "solo lectura" no vive aquí — vive en
/// firestore.rules (ver PartnerService): esta pantalla solo ofrece la
/// interfaz para generar/aceptar códigos, nunca escribe directamente el
/// embarazo de otra cuenta.
///
/// Nota de i18n: siguiendo el mismo criterio ya usado en
/// pregnancy_tracking_screen.dart para contenido secundario (tamaños del
/// bebé, dato curioso semanal), los textos de esta pantalla se dejan en
/// español — es contenido nuevo y extenso; el título del botón que la abre
/// (`s.todayInvitePartner`) ya está traducido y se reutiliza tal cual.
///
/// Diseño: estilo "grouped list" tipo iOS (barra blanca con título grande,
/// cajas agrupadas con divisores finos, iconos en cuadraditos de color) —
/// aprobado por la dueña en un mockup antes de implementarlo aquí.
class InvitePartnerScreen extends StatefulWidget {
  final String userId;
  final String userEmail;
  final String themeId;
  // "Mi objetivo" y los mismos insumos de predicción que usa TodayScreen
  // (ver _predictor ahí) — se necesitan aquí para sincronizar, en modo
  // solo lectura, el calendario de ciclo compartido cuando el objetivo NO
  // es "Seguir mi embarazo" (ver PartnerService.syncCycleData). Todos con
  // valores por defecto porque las pantallas que abren "Embarazos que
  // sigues" (sin ningún ciclo propio que compartir, ver
  // partner_viewer_home_screen.dart) no tienen estos datos.
  final String userGoal;
  final PregnancySettings? pregnancy;
  final bool irregularCycleMode;
  final int? selfReportedCycleLen;
  final int? selfReportedPeriodLen;
  final Map<String, DayEntry> data;

  const InvitePartnerScreen({
    super.key,
    required this.userId,
    required this.userEmail,
    this.themeId = 'pink',
    this.userGoal = 'period',
    this.pregnancy,
    this.irregularCycleMode = false,
    this.selfReportedCycleLen,
    this.selfReportedPeriodLen,
    this.data = const {},
  });

  @override
  State<InvitePartnerScreen> createState() => _InvitePartnerScreenState();
}

class _InvitePartnerScreenState extends State<InvitePartnerScreen> {
  final _service = PartnerService();
  final _codeController = TextEditingController();
  // Nombre que le pone a su código antes de generarlo (ej. "Mi pareja",
  // "Mamá") — puramente para su propia referencia, ver PartnerLink.label.
  final _labelController = TextEditingController();
  bool _generating = false;
  bool _accepting = false;
  String? _acceptError;
  String? _labelError;

  bool get _inPregnancyMode => (widget.pregnancy?.enabled ?? false) && widget.pregnancy?.lmp != null;

  @override
  void initState() {
    super.initState();
    // Mejor esfuerzo: sube el estado que corresponda según el objetivo
    // actual (embarazo, o calendario de ciclo) por si cambió desde la
    // última vez, para que cualquier socia que ya esté vinculada vea datos
    // frescos en cuanto entra aquí. Solo uno de los dos documentos se
    // actualiza — el otro queda tal como estaba (ver PartnerHubScreen, que
    // decide cuál mostrar según cuál siga fresco/activo).
    if (_inPregnancyMode) {
      _service.syncPregnancyData(widget.userId);
    } else {
      final predictor = CyclePredictor(
        widget.data,
        forceIrregular: widget.irregularCycleMode,
        selfReportedCycleLen: widget.selfReportedCycleLen,
        selfReportedPeriodLen: widget.selfReportedPeriodLen,
      );
      final prediction = predictor.predict();
      _service.syncCycleData(
        ownerUid: widget.userId,
        userGoal: widget.userGoal,
        cycleLen: predictor.getAvgCycleLength(),
        periodLen: predictor.getAvgPeriodLength(),
        currentDayInCycle: predictor.currentDayInCycle(),
        nextPeriodStart: prediction.nextPeriodStart,
        ovulationDate: prediction.ovulationDate,
        fertileRangeStart: prediction.fertileRangeStart,
        fertileRangeEnd: prediction.fertileRangeEnd,
        isIrregular: prediction.isIrregular,
      );
    }
    // Si se llegó aquí porque alguien escaneó el QR de invitación con la
    // cámara del móvil (ver DeepLinkService), rellena solo el código en
    // "¿Te compartieron un código?" — sigue haciendo falta tocar
    // "Vincularme" para confirmar.
    _applyPendingCode();
    PendingLinkCode.instance.addListener(_applyPendingCode);
  }

  void _applyPendingCode() {
    final pending = PendingLinkCode.instance.consume();
    if (pending == null || pending.isEmpty) return;
    if (!mounted) return;
    setState(() => _codeController.text = pending);
  }

  @override
  void dispose() {
    // Al salir de esta pantalla (botón "Atrás"), se cancela el código de
    // invitación activo si había uno sin usar: así, si se vuelve a entrar
    // más tarde, no sigue enseñando el mismo código/QR viejo — hay que
    // generar uno nuevo. No afecta a vínculos ya aceptados (esos viven en
    // otro sitio, ver PartnerLink) ni falla si ya no queda nada que
    // cancelar (ver PartnerService.cancelActiveInvite).
    _service.cancelActiveInvite(widget.userId);
    PendingLinkCode.instance.removeListener(_applyPendingCode);
    _codeController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _generateCode() async {
    // "Primero nombre, luego código": sin decir para quién es, no se
    // genera (ni se muestra) ningún código — así nunca se le olvida
    // ponerlo y termina con códigos sin identificar.
    if (_labelController.text.trim().isEmpty) {
      setState(() => _labelError = tr('Escribe para quién es antes de generar el código', "Write who it's for before generating the code"));
      return;
    }
    setState(() {
      _generating = true;
      _labelError = null;
    });
    try {
      final ownerName = await SettingsService().loadProfileName() ?? '';
      await _service.createInvite(
        ownerUid: widget.userId,
        ownerEmail: widget.userEmail,
        label: _labelController.text,
        ownerName: ownerName,
      );
    } on PartnerException catch (e) {
      if (mounted) _showSnack(e.message);
    } catch (_) {
      if (mounted) _showSnack(tr('No se pudo generar el código. Revisa tu conexión.', "Couldn't generate the code. Check your connection."));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _shareCode(String code) async {
    await Share.share(
      tr('Te invito a ver mi seguimiento en CicloPlus 💗\n\nAbre la app, ve a "Invitar a un socio" y usa este código para vincularte:\n\n$code\n\nSolo podrás verlo, no editar nada.',
          "I'm inviting you to see my tracking in CicloPlus 💗\n\nOpen the app, go to \"Invite a partner\" and use this code to link up:\n\n$code\n\nYou'll only be able to view it, not edit anything."),
    );
  }

  Future<void> _acceptCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _accepting = true;
      _acceptError = null;
    });
    try {
      final ownerEmail = await _service.previewInvite(code);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(tr('¿Vincularte?', 'Link up?')),
              content: Text(
                tr('Vas a vincularte con $ownerEmail. Podrás ver su seguimiento (solo lectura), nunca editarlo.', "You're about to link with $ownerEmail. You'll be able to see their tracking (read-only), never edit it."),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancelar', 'Cancel'))),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Vincularme', 'Link me'))),
              ],
            ),
          ) ??
          false;
      if (!confirmed) {
        setState(() => _accepting = false);
        return;
      }
      final outcome = await _service.acceptInvite(code: code, partnerUid: widget.userId, partnerEmail: widget.userEmail);
      if (!mounted) return;
      _codeController.clear();
      _showSnack(outcome.linked ? tr('Vinculado ✓', 'Linked ✓') : tr('Solicitud enviada. Espera a que la dueña la acepte.', 'Request sent. Wait for the owner to accept it.'));
    } on PartnerException catch (e) {
      setState(() => _acceptError = e.message);
    } catch (_) {
      setState(() => _acceptError = tr('Algo salió mal. Inténtalo de nuevo.', 'Something went wrong. Please try again.'));
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  void _openChat({required String otherUid, required String otherLabel}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PartnerChatScreen(
        myUid: widget.userId,
        otherUid: otherUid,
        otherLabel: otherLabel,
        themeId: widget.themeId,
      ),
    ));
  }

  // Los deseos son una única lista de la dueña (sus propios antojos/cosas
  // que necesita) — no cambia según desde qué fila de socio se abra, así
  // que siempre apunta a widget.userId sin importar qué icono se tocó.
  void _openWishes() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PartnerWishesScreen(
        ownerUid: widget.userId,
        myUid: widget.userId,
        themeId: widget.themeId,
        isOwner: true,
        showAppBar: true,
      ),
    ));
  }

  Future<void> _confirmToggleTracking({
    required String partnerUid,
    required String otherLabel,
    required bool currentlyShared,
  }) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(currentlyShared ? tr('¿Dejar de compartir?', 'Stop sharing?') : tr('¿Compartir seguimiento?', 'Share tracking?')),
            content: Text(
              _inPregnancyMode
                  ? (currentlyShared
                      ? tr('$otherLabel ya no podrá ver cómo va desarrollándose tu embarazo día a día ni los consejos para ella y para ti. Seguirá pudiendo chatear contigo y ver tus deseos.', '$otherLabel will no longer see how your pregnancy develops day by day or the tips for them and for you. They can still chat with you and see your wishes.')
                      : tr('$otherLabel podrá ver cómo va desarrollándose tu embarazo día a día y consejos bonitos para ella y para ti.', '$otherLabel will be able to see how your pregnancy develops day by day and lovely tips for them and for you.'))
                  : (currentlyShared
                      ? tr('$otherLabel ya no podrá ver tu calendario de ciclo (previsto/ventana fértil). Seguirá pudiendo chatear contigo y ver tus deseos.', '$otherLabel will no longer see your cycle calendar (predicted/fertile window). They can still chat with you and see your wishes.')
                      : tr('$otherLabel podrá ver tu calendario de ciclo (previsto/ventana fértil), en modo solo lectura.', '$otherLabel will be able to see your cycle calendar (predicted/fertile window), read-only.')),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancelar', 'Cancel'))),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(currentlyShared ? tr('Dejar de compartir', 'Stop sharing') : tr('Compartir', 'Share')),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await _service.setShareTracking(
        ownerUid: widget.userId,
        partnerUid: partnerUid,
        enabled: !currentlyShared,
      );
      if (mounted) {
        _showSnack(currentlyShared ? tr('Ya no comparte tu seguimiento', 'No longer sharing your tracking') : tr('Ahora comparte tu seguimiento ✓', 'Now sharing your tracking ✓'));
      }
    } catch (_) {
      if (mounted) _showSnack(tr('No se pudo actualizar. Revisa tu conexión.', "Couldn't update. Check your connection."));
    }
  }

  Future<void> _confirmUnlink({
    required String ownerUid,
    required String partnerUid,
    required String otherLabel,
    String? inviteCode,
  }) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(tr('¿Desvincular?', 'Unlink?')),
            content: Text(
              tr('$otherLabel ya no podrá ver este seguimiento. El código que se usó para vincularse quedará anulado para siempre: no se podrá volver a usar.', "$otherLabel will no longer see this tracking. The code used to link will be cancelled forever: it can't be used again."),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancelar', 'Cancel'))),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Desvincular', 'Unlink'))),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await _service.unlinkPartner(ownerUid: ownerUid, partnerUid: partnerUid, inviteCode: inviteCode);
    if (mounted) _showSnack(tr('Desvinculado', 'Unlinked'));
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showReadOnlyInfo() {
    final theme = themeById(widget.themeId);
    showReadOnlyInfoSheet(
      context,
      primaryColor: Color(theme.primary),
      primaryLightColor: Color(theme.primaryLight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = themeById(widget.themeId);
    final primary = Color(theme.primary);
    final primaryDark = Color(theme.primaryDark);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F8),
      appBar: PartnerHeader(title: s.todayInvitePartner, primary: primary, primaryDark: primaryDark),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
        children: [
          // ── Sobre con el código ──
          StreamBuilder<ActiveInvite?>(
            stream: _service.watchActiveInvite(widget.userId),
            builder: (context, snapshot) {
              final invite = snapshot.data;
              final code = invite?.code;
              // Si ya hay un código con nombre puesto, refleja ese nombre en
              // el campo (por si se reabre la pantalla) sin pisar lo que esté
              // escribiendo — después de este frame, no durante el build.
              if (invite != null && _labelController.text.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _labelController.text.isEmpty) {
                    _labelController.text = invite.label;
                  }
                });
              }
              // El QR codifica un ENLACE (cicloplus://link?code=...): al
              // escanearlo con la cámara normal (ver DeepLinkService),
              // Android abre CicloPlus con el código ya listo.
              final qrData = code == null ? null : Uri(scheme: 'cicloplus', host: 'link', queryParameters: {'code': code}).toString();
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                InviteEnvelopeCard(
                  primary: primary,
                  label: tr('Tu código de invitación', 'Your invitation code'),
                  child: Column(children: [
                    Row(children: [
                      Expanded(
                        child: Container(
                          height: 78,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: primary.withOpacity(0.08), borderRadius: BorderRadius.circular(18)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                code ?? '······',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                  color: code == null ? primary.withOpacity(0.25) : primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 86,
                        height: 86,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primary.withOpacity(0.12)),
                        ),
                        child: qrData == null
                            ? Icon(Icons.qr_code_2_rounded, size: 52, color: primary.withOpacity(0.2))
                            : QrImageView(
                                data: qrData,
                                version: QrVersions.auto,
                                padding: EdgeInsets.zero,
                                eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: primaryDark),
                                dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: primaryDark),
                              ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Text(
                      code == null
                          ? tr('Es solo para ti — así no te confundes de quién es cada código si invitas a más de una persona. Nunca se le muestra a quien lo acepta.', "It's just for you — so you don't mix up who each code is for if you invite more than one person. It's never shown to whoever accepts it.")
                          : '${tr('Válido 48 horas · solo lectura', 'Valid for 48 hours · read-only')}\n${tr('Que tu pareja lo escanee con la cámara de su móvil', 'Have your partner scan it with their phone camera')}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.textMuted),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(tr('¿Para quién es este código?', 'Who is this code for?'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ),
                PartnerField(
                  controller: _labelController,
                  hint: tr('Mi pareja, Mamá', 'My partner, Mum'),
                  icon: Icons.person_outline_rounded,
                  primary: primary,
                  errorText: _labelError,
                  onChanged: (_) {
                    if (_labelError != null) setState(() => _labelError = null);
                  },
                ),
                const SizedBox(height: 14),
                if (code == null)
                  PartnerButton(
                    label: tr('Generar código', 'Generate code'),
                    icon: Icons.auto_awesome_rounded,
                    primary: primary,
                    primaryDark: primaryDark,
                    loading: _generating,
                    onPressed: _generating ? null : _generateCode,
                  )
                else
                  Row(children: [
                    Expanded(
                      child: PartnerButton(
                        label: tr('Compartir', 'Share'),
                        icon: Icons.share_rounded,
                        primary: primary,
                        primaryDark: primaryDark,
                        onPressed: () => _shareCode(code),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PartnerOutlineButton(
                        label: tr('Generar otro', 'Generate another'),
                        icon: Icons.autorenew_rounded,
                        primary: primary,
                        onPressed: _generating ? null : _generateCode,
                      ),
                    ),
                  ]),
              ]);
            },
          ),
          const SizedBox(height: 22),

          // ── ¿Te compartieron un código? ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
            decoration: BoxDecoration(color: primary.withOpacity(0.07), borderRadius: BorderRadius.circular(22)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.link_rounded, color: primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(tr('¿Te compartieron un código?', 'Were you given a code?'),
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                ),
                IconButton(
                  onPressed: _showReadOnlyInfo,
                  icon: const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.textMuted),
                  tooltip: tr('Qué podrá ver', "What they'll see"),
                  visualDensity: VisualDensity.compact,
                ),
              ]),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: PartnerField(
                    controller: _codeController,
                    hint: tr('Ej. AB3D9K', 'E.g. AB3D9K'),
                    icon: Icons.confirmation_number_outlined,
                    primary: primary,
                    errorText: _acceptError,
                    code: true,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 124,
                  child: PartnerButton(
                    label: tr('Vincularme', 'Link me'),
                    primary: primary,
                    primaryDark: primaryDark,
                    loading: _accepting,
                    height: 52,
                    onPressed: _accepting ? null : _acceptCode,
                  ),
                ),
              ]),
            ]),
          ),

          // ── Solicitudes de reconexión ──
          StreamBuilder<List<ReconnectRequest>>(
            stream: _service.watchReconnectRequests(widget.userId),
            builder: (context, snapshot) {
              final requests = snapshot.data ?? const [];
              if (requests.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  PartnerSectionTitle(tr('Solicitudes de reconexión', 'Reconnection requests'), color: primaryDark),
                  for (final r in requests) ...[
                    Container(decoration: PartnerUi.card(radius: 20), child: _reconnectRow(r)),
                    const SizedBox(height: 10),
                  ],
                ]),
              );
            },
          ),

          // ── Personas que pueden ver tu seguimiento ──
          const SizedBox(height: 26),
          PartnerSectionTitle(tr('Personas que pueden ver tu seguimiento', 'People who can see your tracking'), color: primaryDark),
          StreamBuilder<List<PartnerLink>>(
            stream: _service.watchMyPartners(widget.userId),
            builder: (context, snapshot) {
              final links = snapshot.data ?? const [];
              if (links.isEmpty) return _emptyCard(tr('Nadie vinculado todavía.', 'Nobody linked yet.'));
              return Column(children: [
                for (final l in links)
                  Builder(builder: (context) {
                    final label = l.label.isNotEmpty ? l.label : (l.email.isEmpty ? tr('Persona vinculada', 'Linked person') : l.email);
                    return _personCard(
                      name: label,
                      primary: primary,
                      primaryDark: primaryDark,
                      removeLabel: tr('Desvincular', 'Unlink'),
                      onRemove: () => _confirmUnlink(ownerUid: widget.userId, partnerUid: l.uid, otherLabel: label, inviteCode: l.inviteCode),
                      chips: [
                        PartnerChip(icon: Icons.chat_bubble_outline_rounded, label: tr('Chatear', 'Chat'), primary: primary, onTap: () => _openChat(otherUid: l.uid, otherLabel: label)),
                        PartnerChip(icon: Icons.favorite_border_rounded, label: tr('Tus deseos', 'Your wishes'), primary: primary, onTap: _openWishes),
                        PartnerChip(
                          icon: l.shareTracking ? Icons.calendar_month_rounded : Icons.visibility_off_outlined,
                          label: tr('Compartir', 'Share'),
                          primary: primary,
                          active: l.shareTracking,
                          onTap: () => _confirmToggleTracking(partnerUid: l.uid, otherLabel: label, currentlyShared: l.shareTracking),
                        ),
                      ],
                    );
                  }),
              ]);
            },
          ),

          // ── Seguimientos que sigues ──
          const SizedBox(height: 22),
          PartnerSectionTitle(tr('Seguimientos que sigues', 'Tracking you follow'), color: primaryDark),
          StreamBuilder<List<PartnerLink>>(
            stream: _service.watchPregnanciesIFollow(widget.userId),
            builder: (context, snapshot) {
              final links = snapshot.data ?? const [];
              if (links.isEmpty) return _emptyCard(tr('No sigues ningún seguimiento todavía.', "You're not following anyone yet."));
              return Column(children: [
                for (final l in links)
                  Builder(builder: (context) {
                    final display = l.ownerName.trim().isNotEmpty ? l.ownerName.trim() : (l.email.isEmpty ? tr('Persona vinculada', 'Linked person') : l.email);
                    void open() => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => PartnerHubScreen(
                            ownerUid: l.uid,
                            ownerEmail: l.email,
                            ownerLabel: display,
                            myUid: widget.userId,
                            themeId: widget.themeId,
                          ),
                        ));
                    return _personCard(
                      name: display,
                      primary: primary,
                      primaryDark: primaryDark,
                      badge: Icons.visibility_rounded,
                      onTap: open,
                      removeLabel: tr('Desvincular', 'Unlink'),
                      onRemove: () => _confirmUnlink(ownerUid: l.uid, partnerUid: widget.userId, otherLabel: display, inviteCode: l.inviteCode),
                      chips: [
                        PartnerChip(icon: Icons.visibility_outlined, label: tr('Ver', 'View'), primary: primary, onTap: open),
                        PartnerChip(icon: Icons.chat_bubble_outline_rounded, label: tr('Chatear', 'Chat'), primary: primary, onTap: () => _openChat(otherUid: l.uid, otherLabel: display)),
                      ],
                    );
                  }),
              ]);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _approveReconnect(ReconnectRequest request) async {
    try {
      await _service.approveReconnect(request);
      if (mounted) _showSnack(tr('Reconexión aceptada ✓', 'Reconnection accepted ✓'));
    } catch (_) {
      if (mounted) _showSnack(tr('No se pudo aceptar. Revisa tu conexión.', "Couldn't accept. Check your connection."));
    }
  }

  Future<void> _rejectReconnect(ReconnectRequest request) async {
    try {
      await _service.rejectReconnect(request);
      if (mounted) _showSnack(tr('Solicitud rechazada.', 'Request declined.'));
    } catch (_) {
      if (mounted) _showSnack(tr('No se pudo rechazar. Revisa tu conexión.', "Couldn't decline. Check your connection."));
    }
  }

  // ---- Piezas de UI (diseño elegante, ver partner_ui.dart) ----

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: PartnerUi.card(radius: 20),
      child: Text(text, style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
    );
  }

  Widget _personCard({
    required String name,
    required Color primary,
    required Color primaryDark,
    required List<Widget> chips,
    required String removeLabel,
    required VoidCallback onRemove,
    IconData badge = Icons.favorite_rounded,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: PartnerUi.card(radius: 22),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              PartnerAvatar(name: name, primary: primary, primaryDark: primaryDark, badge: badge),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 30,
                      child: OutlinedButton(
                        onPressed: onRemove,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryDark,
                          side: BorderSide(color: primary.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                        child: Text(removeLabel),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(spacing: 7, runSpacing: 7, children: chips),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _reconnectRow(ReconnectRequest request) {
    final label = request.partnerEmail.isEmpty ? tr('Persona vinculada', 'Linked person') : request.partnerEmail;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          const Icon(Icons.replay_circle_filled_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tr('$label quiere reconectar', '$label wants to reconnect'),
              style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => _rejectReconnect(request),
            child: Text(tr('Rechazar', 'Decline')),
          ),
          TextButton(
            onPressed: () => _approveReconnect(request),
            child: Text(tr('Aceptar', 'Accept')),
          ),
        ],
      ),
    );
  }
}

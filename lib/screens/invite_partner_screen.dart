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
      setState(() => _labelError = 'Escribe para quién es antes de generar el código');
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
      if (mounted) _showSnack('No se pudo generar el código. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _shareCode(String code) async {
    await Share.share(
      'Te invito a ver mi seguimiento en CicloPlus 💗\n\n'
      'Abre la app, ve a "Invitar a un socio" y usa este código para vincularte:\n\n'
      '$code\n\n'
      'Solo podrás verlo, no editar nada.',
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
              title: const Text('¿Vincularte?'),
              content: Text(
                'Vas a vincularte con $ownerEmail. Podrás ver su seguimiento (solo lectura), nunca editarlo.',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Vincularme')),
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
      _showSnack(outcome.linked ? 'Vinculado ✓' : 'Solicitud enviada. Espera a que la dueña la acepte.');
    } on PartnerException catch (e) {
      setState(() => _acceptError = e.message);
    } catch (_) {
      setState(() => _acceptError = 'Algo salió mal. Inténtalo de nuevo.');
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
            title: Text(currentlyShared ? '¿Dejar de compartir?' : '¿Compartir seguimiento?'),
            content: Text(
              _inPregnancyMode
                  ? (currentlyShared
                      ? '$otherLabel ya no podrá ver cómo va desarrollándose tu embarazo día a día ni los consejos para ella y para ti. Seguirá pudiendo chatear contigo y ver tus deseos.'
                      : '$otherLabel podrá ver cómo va desarrollándose tu embarazo día a día y consejos bonitos para ella y para ti.')
                  : (currentlyShared
                      ? '$otherLabel ya no podrá ver tu calendario de ciclo (previsto/ventana fértil). Seguirá pudiendo chatear contigo y ver tus deseos.'
                      : '$otherLabel podrá ver tu calendario de ciclo (previsto/ventana fértil), en modo solo lectura.'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(currentlyShared ? 'Dejar de compartir' : 'Compartir'),
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
        _showSnack(currentlyShared ? 'Ya no comparte tu seguimiento' : 'Ahora comparte tu seguimiento ✓');
      }
    } catch (_) {
      if (mounted) _showSnack('No se pudo actualizar. Revisa tu conexión.');
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
            title: const Text('¿Desvincular?'),
            content: Text(
              '$otherLabel ya no podrá ver este seguimiento. El código que se usó para vincularse quedará anulado para siempre: no se podrá volver a usar.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Desvincular')),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await _service.unlinkPartner(ownerUid: ownerUid, partnerUid: partnerUid, inviteCode: inviteCode);
    if (mounted) _showSnack('Desvinculado');
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        // Barra tipo iOS (fila chica de "Atrás" arriba y debajo el título
        // grande) pero con el degradado rosa de la marca, como antes.
        preferredSize: const Size.fromHeight(96),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(26), bottomRight: Radius.circular(26)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(theme.primaryDark), primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(8, 8, 16, 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded, size: 17, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Atrás', style: TextStyle(color: Colors.white, fontSize: 17)),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        s.todayInvitePartner,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _sectionLabel('Tu código de invitación'),
          const SizedBox(height: 8),
          _groupBox(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _iconBadge(Icons.qr_code_2_rounded, primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _labelController,
                      onChanged: (_) {
                        if (_labelError != null) setState(() => _labelError = null);
                      },
                      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: '¿Para quién es este código?',
                        hintText: 'Mi pareja, Mamá',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelStyle: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                        hintStyle: const TextStyle(fontSize: 15, color: AppColors.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        errorText: _labelError,
                        errorStyle: const TextStyle(fontSize: 10.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Es solo para ti — así no te confundes de quién es cada código si invitas a más de una persona. Nunca se le muestra a quien lo acepta.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
          StreamBuilder<ActiveInvite?>(
            stream: _service.watchActiveInvite(widget.userId),
            builder: (context, snapshot) {
              final invite = snapshot.data;
              final code = invite?.code;
              // Si ya hay un código con nombre puesto, refleja ese
              // nombre en el campo (por si se reabre la pantalla) sin
              // pisar lo que esté escribiendo ahora mismo. Se hace
              // después de este frame (no directo aquí en build) para
              // no disparar un rebuild del TextField mientras el
              // árbol todavía se está construyendo.
              if (invite != null && _labelController.text.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _labelController.text.isEmpty) {
                    _labelController.text = invite.label;
                  }
                });
              }
              if (code == null) {
                return Center(
                  child: _pillButton(
                    label: 'Generar código',
                    color: primary,
                    loading: _generating,
                    onPressed: _generating ? null : _generateCode,
                  ),
                );
              }
              // El QR codifica un ENLACE (cicloplus://link?code=...), no
              // solo el código a secas: así, al escanearlo con la cámara
              // normal del móvil (ver DeepLinkService), Android puede
              // abrir CicloPlus directamente con el código ya listo.
              final qrData = Uri(scheme: 'cicloplus', host: 'link', queryParameters: {'code': code}).toString();
              return Column(
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primary.withOpacity(0.15)),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 168,
                        eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: primary),
                        dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'Que tu pareja lo escanee con la cámara de su móvil',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        code,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 5,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text('Válido 48 horas · solo lectura', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareCode(code),
                          icon: Icon(Icons.ios_share, size: 16, color: primary),
                          label: Text('Compartir', style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.background,
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton(
                          onPressed: _generating ? null : _generateCode,
                          child: Text('Generar otro', style: TextStyle(color: primary, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _sectionLabel('¿Te compartieron un código?')),
              IconButton(
                onPressed: _showReadOnlyInfo,
                icon: const Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
                tooltip: 'Qué podrá ver',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _groupBox(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _iconBadge(Icons.link_rounded, primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontSize: 15, letterSpacing: 0.5, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ej. AB3D9K',
                        hintStyle: const TextStyle(fontSize: 15, color: AppColors.textMuted, letterSpacing: 0.5),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        errorText: _acceptError,
                        errorStyle: const TextStyle(fontSize: 10.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: _pillButton(
              label: 'Vincularme',
              color: primary,
              loading: _accepting,
              onPressed: _accepting ? null : _acceptCode,
            ),
          ),
          StreamBuilder<List<ReconnectRequest>>(
            stream: _service.watchReconnectRequests(widget.userId),
            builder: (context, snapshot) {
              final requests = snapshot.data ?? const [];
              if (requests.isEmpty) return const SizedBox.shrink();
              return Column(
                children: [
                  const SizedBox(height: 26),
                  _sectionLabel('Solicitudes de reconexión'),
                  const SizedBox(height: 8),
                  _rowsGroup(requests.map((r) => _reconnectRow(r)).toList()),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          _sectionLabel('Personas que pueden ver tu seguimiento'),
          const SizedBox(height: 8),
          Builder(
            // Antes este bloque envolvía todo en un StreamBuilder solo para
            // saber si el modo embarazo estaba activo (y así decidir si se
            // mostraba el icono de "compartir seguimiento" en cada fila).
            // Ahora ese icono aplica en los 3 objetivos — embarazo, periodo
            // o intento de concebir siempre hay algo que compartir/dejar de
            // compartir (ver PartnerLink.shareTracking, ya genérico) — así
            // que ya no hace falta esa comprobación.
            builder: (context) {
              return StreamBuilder<List<PartnerLink>>(
                stream: _service.watchMyPartners(widget.userId),
                builder: (context, snapshot) {
                  final links = snapshot.data ?? const [];
                  if (links.isEmpty) {
                    return _groupBox(
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Text('Nadie vinculado todavía.', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                      ),
                    );
                  }
                  return _rowsGroup(links
                      .map((l) {
                        final label = l.label.isNotEmpty ? l.label : (l.email.isEmpty ? 'Persona vinculada' : l.email);
                        return _linkRow(
                          icon: Icons.favorite,
                          iconColor: primary,
                          label: label,
                          onChatTap: () => _openChat(otherUid: l.uid, otherLabel: label),
                          onWishesTap: _openWishes,
                          showPregnancyToggle: true,
                          pregnancyShared: l.shareTracking,
                          onPregnancyToggle: () => _confirmToggleTracking(
                            partnerUid: l.uid,
                            otherLabel: label,
                            currentlyShared: l.shareTracking,
                          ),
                          onRemove: () => _confirmUnlink(
                            ownerUid: widget.userId,
                            partnerUid: l.uid,
                            otherLabel: label,
                            inviteCode: l.inviteCode,
                          ),
                        );
                      })
                      .toList());
                },
              );
            },
          ),
          const SizedBox(height: 26),
          _sectionLabel(
            // Antes decía "Embarazos que sigues": cada dueña puede estar en
            // un objetivo distinto (una en embarazo, otra solo llevando su
            // periodo), así que ya no se puede asumir que todo lo que se
            // sigue aquí es un embarazo — ver PartnerHubScreen, que decide
            // qué mostrar (embarazo o calendario de ciclo) según cada
            // dueña concreta.
            'Seguimientos que sigues',
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<PartnerLink>>(
            stream: _service.watchPregnanciesIFollow(widget.userId),
            builder: (context, snapshot) {
              final links = snapshot.data ?? const [];
              if (links.isEmpty) {
                return _groupBox(
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('No sigues ningún seguimiento todavía.', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                  ),
                );
              }
              return _rowsGroup(links
                  .map((l) {
                    final display = l.ownerName.trim().isNotEmpty
                        ? l.ownerName.trim()
                        : (l.email.isEmpty ? 'Persona vinculada' : l.email);
                    return _linkRow(
                      icon: Icons.visibility_outlined,
                      iconColor: primary,
                      label: display,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PartnerHubScreen(
                          ownerUid: l.uid,
                          ownerEmail: l.email,
                          ownerLabel: display,
                          myUid: widget.userId,
                          themeId: widget.themeId,
                        ),
                      )),
                      onChatTap: () => _openChat(otherUid: l.uid, otherLabel: display),
                      onRemove: () => _confirmUnlink(
                        ownerUid: l.uid,
                        partnerUid: widget.userId,
                        otherLabel: display,
                        inviteCode: l.inviteCode,
                      ),
                    );
                  })
                  .toList());
            },
          ),
        ],
      ),
    );
  }

  Future<void> _approveReconnect(ReconnectRequest request) async {
    try {
      await _service.approveReconnect(request);
      if (mounted) _showSnack('Reconexión aceptada ✓');
    } catch (_) {
      if (mounted) _showSnack('No se pudo aceptar. Revisa tu conexión.');
    }
  }

  Future<void> _rejectReconnect(ReconnectRequest request) async {
    try {
      await _service.rejectReconnect(request);
      if (mounted) _showSnack('Solicitud rechazada.');
    } catch (_) {
      if (mounted) _showSnack('No se pudo rechazar. Revisa tu conexión.');
    }
  }

  // ---- Piezas de UI reutilizables (estilo "grouped list" tipo iOS) ----

  /// Etiqueta pequeña en mayúsculas que va encima de cada caja agrupada.
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.5),
      ),
    );
  }

  /// Caja blanca agrupada con esquinas redondeadas y sombra casi plana.
  Widget _groupBox({required Widget child}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1)),
        ],
      ),
      child: child,
    );
  }

  /// Junta varias filas dentro de una sola caja agrupada, separadas por un
  /// divisor fino con sangría (como una lista de Ajustes de iOS).
  Widget _rowsGroup(List<Widget> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(Container(margin: const EdgeInsets.only(left: 41), height: 0.8, color: AppColors.border));
      }
    }
    return _groupBox(child: Column(children: children));
  }

  /// Cuadradito de color con un icono blanco dentro (estilo icono de
  /// Ajustes de iOS) en vez de la burbuja circular usada antes.
  Widget _iconBadge(IconData icon, Color color) {
    return Container(
      width: 29,
      height: 29,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 15, color: Colors.white),
    );
  }

  /// Botón principal, más chico y centrado (no de ancho completo) — así
  /// pesa menos visualmente que un botón que ocupa todo el ancho.
  Widget _pillButton({
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
    );
  }

  Widget _reconnectRow(ReconnectRequest request) {
    final label = request.partnerEmail.isEmpty ? 'Persona vinculada' : request.partnerEmail;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          _iconBadge(Icons.replay_circle_filled_outlined, AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label quiere reconectar',
              style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => _rejectReconnect(request),
            child: const Text('Rechazar'),
          ),
          TextButton(
            onPressed: () => _approveReconnect(request),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Widget _linkRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    VoidCallback? onTap,
    VoidCallback? onChatTap,
    VoidCallback? onWishesTap,
    bool showPregnancyToggle = false,
    bool pregnancyShared = true,
    VoidCallback? onPregnancyToggle,
    required VoidCallback onRemove,
  }) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          _iconBadge(icon, iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
          ),
          // Los iconos de acceso rápido van siempre en el mismo orden y
          // alineados: chat, deseos y (si aplica) embarazo — los tres se
          // tocan igual, para entrar a su pantalla.
          if (onChatTap != null)
            IconButton(
              icon: Icon(Icons.chat_bubble_outline, size: 18, color: iconColor),
              onPressed: onChatTap,
              tooltip: 'Chatear',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          if (onWishesTap != null)
            IconButton(
              icon: Icon(Icons.auto_awesome, size: 18, color: iconColor),
              onPressed: onWishesTap,
              tooltip: 'Tus deseos',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          if (showPregnancyToggle)
            IconButton(
              icon: Icon(
                Icons.pregnant_woman,
                size: 18,
                color: pregnancyShared ? iconColor : AppColors.textMuted,
              ),
              onPressed: onPregnancyToggle,
              tooltip: pregnancyShared ? 'Compartiendo seguimiento — toca para dejar de compartir' : 'Toca para compartir tu seguimiento',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
            onPressed: onRemove,
            tooltip: 'Desvincular',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, size: 20, color: iconColor.withOpacity(0.55)),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return Material(color: Colors.transparent, child: InkWell(onTap: onTap, child: row));
  }
}

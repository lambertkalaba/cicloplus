import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/partner_service.dart';
import '../services/pending_link_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/read_only_info_sheet.dart';
import 'partner_hub_screen.dart';

/// Colores entre los que puede elegir quien ve el embarazo de su pareja —
/// un subconjunto de `kAppThemes` (ver settings_service.dart): solo los 3
/// que pidió el usuario (rosa/azul/lila), no los 5 temas completos de la
/// app principal.
const List<String> kPartnerViewerThemeIds = ['blue', 'pink', 'purple'];

/// Pantalla de inicio para cuentas "solo ver el seguimiento de mi pareja"
/// (autenticadas de forma anónima, ver AuthScreen y AuthService
/// .signInAnonymously). Estas cuentas no tienen ciclo propio ni datos que
/// mostrar en MainTabScreen, así que AuthGate las manda aquí en vez de a la
/// app completa:
///
/// - Si todavía no vincularon ningún código, se les pide aquí mismo (mismo
///   campo que en InvitePartnerScreen, con el mismo ícono de información).
/// - En cuanto tengan al menos un vínculo, se les muestra directo en modo
///   solo lectura (PartnerHubScreen, que a su vez decide entre
///   PartnerPregnancyScreen/PartnerCycleScreen según lo que comparta la
///   dueña) — no hace falta una lista intermedia porque el caso normal es
///   seguir a una sola persona.
class PartnerViewerHomeScreen extends StatefulWidget {
  final AppUser user;
  final VoidCallback onSignOut;

  const PartnerViewerHomeScreen({super.key, required this.user, required this.onSignOut});

  @override
  State<PartnerViewerHomeScreen> createState() => _PartnerViewerHomeScreenState();
}

class _PartnerViewerHomeScreenState extends State<PartnerViewerHomeScreen> {
  final _service = PartnerService();
  final _settings = SettingsService();
  final _codeController = TextEditingController();
  bool _accepting = false;
  String? _acceptError;

  // 'blue' por defecto la primera vez (ver SettingsService
  // .loadPartnerViewerTheme) — luego se recuerda la elección de la
  // persona en este dispositivo.
  String _themeId = 'blue';

  // Si el código que pegó ya se había usado antes por otra sesión (por
  // ejemplo, cerró sesión y volvió a entrar), no se vincula al instante:
  // queda esperando a que la dueña la apruebe desde "Invitar a un socio".
  // Ver PartnerService.acceptInvite / ReconnectRequest.
  ReconnectRequest? _pendingRequest;
  bool _waitingApproval = false;
  StreamSubscription<ReconnectRequest?>? _pendingSub;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _resumePendingReconnect();
    // Si se llegó aquí porque alguien escaneó el QR de invitación con la
    // cámara del móvil (ver DeepLinkService), rellena solo el código —
    // sigue haciendo falta tocar "Vincularme" para confirmar.
    _applyPendingCode();
    PendingLinkCode.instance.addListener(_applyPendingCode);
  }

  void _applyPendingCode() {
    final pending = PendingLinkCode.instance.consume();
    if (pending == null || pending.isEmpty) return;
    if (!mounted) return;
    setState(() => _codeController.text = pending);
  }

  Future<void> _loadTheme() async {
    final id = await _settings.loadPartnerViewerTheme();
    if (mounted) setState(() => _themeId = id);
  }

  /// Si la app se cerró mientras esperábamos que la dueña aprobara una
  /// reconexión, retoma esa espera (la sesión anónima sigue siendo la
  /// misma mientras no toque "Salir" otra vez, así que la solicitud sigue
  /// siendo válida para ella).
  Future<void> _resumePendingReconnect() async {
    final saved = await _settings.loadPendingReconnect();
    if (saved == null) return;
    if (mounted) setState(() => _waitingApproval = true);
    _listenPending(ownerUid: saved['ownerUid']!, requestId: saved['requestId']!);
  }

  void _listenPending({required String ownerUid, required String requestId}) {
    _pendingSub?.cancel();
    _pendingSub = _service.watchReconnectRequestDoc(ownerUid: ownerUid, requestId: requestId).listen((req) async {
      if (!mounted) return;
      if (req == null) {
        // La dueña la rechazó (o ya se completó y se borró sola).
        await _settings.clearPendingReconnect();
        if (mounted) setState(() { _waitingApproval = false; _pendingRequest = null; });
        return;
      }
      if (req.status == 'approved') {
        try {
          await _service.finalizeReconnect(req);
        } catch (_) {
          // Sin conexión u otro fallo transitorio: seguimos escuchando
          // este mismo documento (sigue "approved"), así que se
          // reintentará solo al reabrir la app o si vuelve a emitir.
          setState(() { _waitingApproval = true; _pendingRequest = req; });
          return;
        }
        _pendingSub?.cancel();
        await _settings.clearPendingReconnect();
        if (mounted) setState(() { _waitingApproval = false; _pendingRequest = null; });
        return;
      }
      setState(() {
        _waitingApproval = true;
        _pendingRequest = req;
      });
    });
  }

  @override
  void dispose() {
    PendingLinkCode.instance.removeListener(_applyPendingCode);
    _codeController.dispose();
    _pendingSub?.cancel();
    super.dispose();
  }

  /// "Salir" real: cierra la sesión anónima. La próxima vez que entre será
  /// con una cuenta anónima nueva, así que cualquier espera de reconexión
  /// guardada en este dispositivo ya no aplica — la limpiamos para que no
  /// intente escuchar una solicitud que pertenece a una sesión distinta.
  void _signOut() {
    _pendingSub?.cancel();
    _settings.clearPendingReconnect();
    widget.onSignOut();
  }

  /// "Ya no quiero seguir este embarazo": a diferencia de cerrar sesión
  /// (que no borra nada — el vínculo sigue ahí para cuando quiera volver
  /// a entrar desde este mismo dispositivo), esto es DEFINITIVO. Anula el
  /// código para siempre (ver PartnerService.unlinkPartner) y borra el
  /// vínculo en ambos sentidos. No hace falta cerrar sesión aparte: en
  /// cuanto se borra el vínculo, el StreamBuilder de build() detecta la
  /// lista vacía y vuelve a mostrar solo la pantalla de "pega tu código".
  Future<void> _leaveForever(PartnerLink link) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Ya no quieres seguir este seguimiento?'),
            content: const Text(
              'Dejarás de verlo y el código que usaste quedará anulado para siempre: ni tú ni nadie más podrá volver a usarlo. Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, dejar de seguir')),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await _service.unlinkPartner(ownerUid: link.uid, partnerUid: widget.user.id, inviteCode: link.inviteCode);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo completar. Revisa tu conexión e inténtalo de nuevo.')),
        );
      }
    }
  }

  void _showReadOnlyInfo() {
    final theme = themeById(_themeId);
    showReadOnlyInfoSheet(
      context,
      primaryColor: Color(theme.primary),
      primaryLightColor: Color(theme.primaryLight),
    );
  }

  Future<void> _pickTheme() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ThemePickerSheet(selectedId: _themeId),
    );
    if (picked == null || picked == _themeId) return;
    setState(() => _themeId = picked);
    await _settings.savePartnerViewerTheme(picked);
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
                'Vas a vincularte con $ownerEmail. Podrás ver su seguimiento (embarazo, periodo o intento de concebir, según lo que comparta) en modo solo lectura, nunca editarlo.',
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
      final outcome = await _service.acceptInvite(code: code, partnerUid: widget.user.id, partnerEmail: widget.user.email);
      if (!outcome.linked && outcome.reconnectRequest != null) {
        final request = outcome.reconnectRequest!;
        await _settings.savePendingReconnect(ownerUid: request.ownerUid, requestId: request.id);
        _listenPending(ownerUid: request.ownerUid, requestId: request.id);
      }
      // Si quedó vinculada al instante, no hace falta hacer nada más
      // aquí: el StreamBuilder de build() detecta el nuevo vínculo y
      // muestra PartnerHubScreen solo, que a su vez decide entre
      // PartnerPregnancyScreen/PartnerCycleScreen según lo que comparta
      // la dueña.
    } on PartnerException catch (e) {
      setState(() => _acceptError = e.message);
    } catch (_) {
      setState(() => _acceptError = 'Algo salió mal. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  /// Pantalla de espera mientras la dueña aprueba (o rechaza) la
  /// reconexión — se muestra en vez del campo de código mientras
  /// [_waitingApproval] sea true (ver `_listenPending`).
  Widget _buildWaitingBody(Color primary) {
    final label = _pendingRequest?.ownerEmail;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('⏳', style: TextStyle(fontSize: 40), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          const Text(
            'Esperando aprobación',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            (label == null || label.isEmpty)
                ? 'Ya usaste este código antes, así que le pedimos a quien te invitó que confirme que sigues siendo tú.'
                : 'Ya usaste este código antes, así que le pedimos a $label que confirme que sigues siendo tú.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 28),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 28),
          TextButton(
            onPressed: () async {
              if (_pendingRequest != null) {
                await _service.rejectReconnect(_pendingRequest!);
              }
              await _settings.clearPendingReconnect();
              _pendingSub?.cancel();
              if (mounted) setState(() { _waitingApproval = false; _pendingRequest = null; });
            },
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = themeById(_themeId);
    final primary = Color(theme.primary);
    final primaryDark = Color(theme.primaryDark);

    return StreamBuilder<List<PartnerLink>>(
      stream: _service.watchPregnanciesIFollow(widget.user.id),
      builder: (context, snapshot) {
        final links = snapshot.data ?? const [];
        if (links.isNotEmpty) {
          final link = links.first;
          final ownerDisplay = link.ownerName.trim().isNotEmpty
              ? link.ownerName.trim()
              : (link.email.isEmpty ? 'Persona vinculada' : link.email);
          return PartnerHubScreen(
            ownerUid: link.uid,
            ownerEmail: link.email,
            ownerLabel: ownerDisplay,
            myUid: widget.user.id,
            themeId: _themeId,
            onClose: () => _leaveForever(link),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Ver seguimiento de tu pareja'),
            backgroundColor: primaryDark,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: _pickTheme,
                icon: const Icon(Icons.palette_outlined),
                tooltip: 'Color',
              ),
              TextButton(
                onPressed: _signOut,
                child: const Text('Salir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          body: _waitingApproval ? _buildWaitingBody(primary) : Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Text('💗', style: TextStyle(fontSize: 40), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Pega aquí el código que te compartieron',
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ),
                    IconButton(
                      onPressed: _showReadOnlyInfo,
                      icon: const Icon(Icons.info_outline, size: 20, color: AppColors.textMuted),
                      tooltip: 'Qué podrás ver',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 3),
                  decoration: InputDecoration(
                    hintText: 'Ej. AB3D9K',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    errorText: _acceptError,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _accepting ? null : _acceptCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: _accepting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Vincularme', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Hoja inferior para elegir entre rosa/azul/lila (ver
/// kPartnerViewerThemeIds) — devuelve el id elegido con Navigator.pop, o
/// null si se cierra sin elegir. Mismo estilo redondeado con tirador que
/// read_only_info_sheet.dart, para que ambas hojas de esta pantalla se
/// sientan parte del mismo sistema visual.
class _ThemePickerSheet extends StatelessWidget {
  final String selectedId;

  const _ThemePickerSheet({required this.selectedId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 18),
            const Text(
              'Elige un color',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: kPartnerViewerThemeIds.map((id) {
                final theme = themeById(id);
                final selected = id == selectedId;
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(id),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Color(theme.primary),
                          shape: BoxShape.circle,
                          border: selected ? Border.all(color: AppColors.textPrimary, width: 2.5) : null,
                        ),
                        child: selected ? const Icon(Icons.check, color: Colors.white) : null,
                      ),
                      const SizedBox(height: 8),
                      Text(theme.name, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

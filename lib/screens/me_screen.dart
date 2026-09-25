import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoAlertDialog, CupertinoDialogAction;

import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import '../models/day_entry.dart';
import '../services/cycle_predictor.dart';
import '../services/reminder_service.dart';
import '../services/settings_service.dart';
import '../services/stats_calculator.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/coming_soon_sheet.dart';
import '../widgets/conceive_intake_sheet.dart';
import 'account_screen.dart';
import 'field_detail_screen.dart';
import 'ovulation_test_screen.dart';
import 'pregnancy_tracking_screen.dart';
import 'quick_summary_screen.dart';
import 'reminder_screen.dart';
import 'review_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'timeline_screen.dart';

/// Pestaña "Yo" (rediseño completo, fase 5): reemplaza el uso temporal de
/// `HealthMenuScreen(section: null, ...)` como 5ª pestaña. Estructura
/// tomada de las capturas de referencia del usuario: header con avatar +
/// "Sincronizar datos", grid de 10 accesos rápidos, tarjeta de Cronología,
/// chips de "Mi objetivo" y tarjetas de "Análisis del ciclo" — más los
/// accesos a Configuración, Revisión y Cerrar sesión que antes vivían en
/// otros sitios (Drawer eliminado en la fase 3, pestañas Revisión/
/// Estadísticas/Línea de tiempo sin pestaña propia desde esa misma fase).
///
/// `HealthMenuScreen` (health_menu_screen.dart) deja de usarse desde
/// MainTabScreen a partir de esta fase, pero el archivo se conserva sin
/// borrar por si se necesita reutilizar algo de su lógica más adelante.
class MeScreen extends StatefulWidget {
  final String userId;
  final String userEmail;
  // Usuario completo y servicio de suscripción — se usan solo para abrir
  // AccountScreen ("Mi cuenta") con toda la información real (foto,
  // nombre, fecha de registro, estado de suscripción) desde el botón
  // "Gestionar" de la tarjeta de sesión. El resto de esta pantalla sigue
  // usando userId/userEmail como antes.
  final AppUser user;
  final SubscriptionService subscriptionService;
  final String themeId;
  final ValueChanged<String> onThemeChanged;
  final Map<String, DayEntry> data;
  final ValueChanged<Map<String, DayEntry>> onDataChanged;
  final bool irregularCycleMode;

  // Duración de ciclo/periodo autoinformadas en el cuestionario de
  // "Intentar concebir" — respaldo para CyclePredictor mientras no hay
  // suficientes datos reales (ver conceive_intake_sheet.dart).
  final int? selfReportedCycleLen;
  final int? selfReportedPeriodLen;

  // Modo embarazo — se lee/actualiza aquí también para que el chip "Seguir
  // mi embarazo" de "Mi objetivo" quede coherente con el interruptor real
  // de HealthMenuScreen/Configuración en vez de crear un estado paralelo.
  final PregnancySettings pregnancy;
  final ValueChanged<PregnancySettings> onPregnancyChanged;

  // Recordatorio de periodo/ovulación/fértil — mismo paquete de props que
  // ya recibía HealthMenuScreen, reenviado tal cual a ReminderScreen desde
  // el acceso rápido de esta pantalla.
  final ReminderSettings reminderSettings;
  final bool hasPeriodPrediction;
  final ValueChanged<bool> onReminderToggle;
  final ValueChanged<int> onReminderDaysChanged;
  final ValueChanged<bool> onOvulationReminderToggle;
  final ValueChanged<bool> onFertileReminderToggle;

  // Cambia de pestaña dentro del mismo BottomNavigationBar de MainTabScreen
  // (0=Hoy, 1=Calendario, 2=Registrar, 3=Recordatorio) — se usa para los
  // accesos del grid que ya tienen una pestaña propia (Periodo y ciclo,
  // Vida sexual) en vez de duplicar esas pantallas con un Navigator.push.
  final ValueChanged<int> onNavigateToTab;

  final VoidCallback onSignOut;

  /// "Mi objetivo" tal como lo tiene MainTabScreen — recibido igual que el
  /// resto de pestañas para que, si se cambia desde Configuración y se
  /// vuelve aquí sin cambiar de tab entre medio, didUpdateWidget se entere
  /// del cambio (ver también CalendarScreen.userGoal, mismo criterio).
  final String userGoal;

  /// Avisa a MainTabScreen cuando el objetivo cambia desde los chips de
  /// ESTA pantalla (_selectGoal), para que su copia (_userGoal, la que
  /// reciben Hoy/Calendario/Registrar/Recordatorios) no se quede
  /// desactualizada hasta la próxima vez que se recargue Configuración.
  final ValueChanged<String> onUserGoalChanged;

  const MeScreen({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.user,
    required this.subscriptionService,
    required this.themeId,
    required this.onThemeChanged,
    required this.data,
    required this.onDataChanged,
    this.irregularCycleMode = false,
    this.selfReportedCycleLen,
    this.selfReportedPeriodLen,
    required this.pregnancy,
    required this.onPregnancyChanged,
    required this.reminderSettings,
    required this.hasPeriodPrediction,
    required this.onReminderToggle,
    required this.onReminderDaysChanged,
    required this.onOvulationReminderToggle,
    required this.onFertileReminderToggle,
    required this.onNavigateToTab,
    required this.onSignOut,
    this.userGoal = 'period',
    required this.onUserGoalChanged,
  });

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  final SettingsService _settingsService = SettingsService();

  String _goal = 'period';
  bool _loading = true;
  // Nombre guardado por la persona (registro o "Mi cuenta") — se muestra
  // en la tarjeta de sesión en vez del correo, que es menos personal.
  String? _displayName;

  /// Nombre a mostrar en la tarjeta de sesión: el guardado si existe: si
  /// no (p. ej. cuentas creadas antes de pedir nombre en el registro), se
  /// deriva uno legible a partir de la parte local del correo (todo antes
  /// de la @), separando puntos/guiones/números y poniendo mayúscula
  /// inicial — así nunca se expone el correo completo en esta tarjeta,
  /// aunque no sea el nombre real. Ej.: "lambert.kalaba92@gmail.com" ->
  /// "Lambert Kalaba".
  String get _greetingName {
    if (_displayName != null && _displayName!.trim().isNotEmpty) {
      return _displayName!;
    }
    final email = widget.userEmail.trim();
    final at = email.indexOf('@');
    final local = at > 0 ? email.substring(0, at) : email;
    final parts = local
        .split(RegExp(r'[._\-0-9]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .toList();
    return parts.isEmpty ? email : parts.join(' ');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el modo embarazo se activó/desactivó desde Configuración mientras
    // esta pantalla ya estaba montada, mantenemos el chip de objetivo
    // coherente con ese cambio externo.
    // Nota: aquí NUNCA se llama a widget.onUserGoalChanged — este método
    // reacciona a cambios que YA vienen de MainTabScreen (pregnancy/
    // userGoal), así que MainTabScreen ya tiene el valor correcto; volver
    // a llamar a su setState desde aquí, en mitad de su propio build,
    // dispara "setState() or markNeedsBuild() called during build". Esa
    // notificación es solo para cuando el cambio se origina EN esta
    // pantalla (ver _selectGoal, que corre fuera del ciclo de build).
    if (oldWidget.pregnancy.enabled != widget.pregnancy.enabled) {
      if (widget.pregnancy.enabled && _goal != 'pregnancy') {
        setState(() => _goal = 'pregnancy');
        _settingsService.saveUserGoal('pregnancy');
      } else if (!widget.pregnancy.enabled && _goal == 'pregnancy') {
        setState(() => _goal = 'period');
        _settingsService.saveUserGoal('period');
      }
    } else if (oldWidget.userGoal != widget.userGoal && widget.userGoal != _goal) {
      // Objetivo cambiado desde Configuración (no desde los chips de esta
      // misma pantalla) mientras "Yo" ya estaba montada — sin esto, _goal
      // se queda con el valor con el que se montó la primera vez.
      setState(() => _goal = widget.userGoal);
    }
  }

  Future<void> _load() async {
    final name = await _settingsService.loadProfileName();
    final lastName = await _settingsService.loadProfileLastName();
    if (!mounted) return;
    final fullName = [name, lastName].where((p) => p != null && p.trim().isNotEmpty).join(' ');
    setState(() {
      // Si el modo embarazo ya está activo pero el objetivo guardado no lo
      // refleja (p. ej. se activó desde Configuración antes de que
      // existiera este campo), mostramos "Seguir mi embarazo" de entrada
      // en vez de un chip inconsistente con el resto de la app. widget.userGoal
      // ya viene fresco de MainTabScreen, así que no hace falta releerlo aquí.
      _goal = widget.pregnancy.enabled ? 'pregnancy' : widget.userGoal;
      _displayName = fullName.isNotEmpty ? fullName : null;
      _loading = false;
    });
  }

  Future<void> _selectGoal(String goal) async {
    setState(() => _goal = goal);
    await _settingsService.saveUserGoal(goal);
    widget.onUserGoalChanged(goal);
    // "Seguir mi embarazo" activa el modo embarazo real (mismo interruptor
    // que HealthMenuScreen/Configuración) en vez de un estado paralelo que
    // lo contradiga. Si se elige otro objetivo mientras el modo embarazo
    // seguía activo, lo desactivamos para no dejar ambos estados en
    // conflicto.
    if (goal == 'pregnancy' && !widget.pregnancy.enabled) {
      widget.onPregnancyChanged(widget.pregnancy.copyWith(enabled: true));
    } else if (goal != 'pregnancy' && widget.pregnancy.enabled) {
      widget.onPregnancyChanged(widget.pregnancy.copyWith(enabled: false));
    }
    // Primera vez que se elige "Intentar concebir": un par de preguntas
    // rápidas (fecha objetivo, tiempo intentándolo, etc.) para orientar
    // mejor desde el principio — ver widgets/conceive_intake_sheet.dart.
    if (goal == 'conceive') {
      await maybeShowConceiveIntake(context, _settingsService);
    }
  }

  AppThemeOption get _theme => themeById(widget.themeId);

  Future<void> _showComingSoon(AppStrings s) => showComingSoonSheet(context);

  Future<void> _openReminder() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReminderScreen(
          settings: widget.reminderSettings,
          hasPrediction: widget.hasPeriodPrediction,
          onPeriodToggle: widget.onReminderToggle,
          onDaysChanged: widget.onReminderDaysChanged,
          onOvulationToggle: widget.onOvulationReminderToggle,
          onFertileToggle: widget.onFertileReminderToggle,
          themeId: widget.themeId,
          data: widget.data,
          irregularCycleMode: widget.irregularCycleMode,
          selfReportedCycleLen: widget.selfReportedCycleLen,
          selfReportedPeriodLen: widget.selfReportedPeriodLen,
          userGoal: _goal,
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          userId: widget.userId,
          onThemeChanged: widget.onThemeChanged,
          data: widget.data,
          onDataChanged: widget.onDataChanged,
          onSignOut: widget.onSignOut,
        ),
      ),
    );
    // Al volver de Configuración, refrescamos "Mi objetivo"/modo embarazo
    // por si se cambiaron ahí (SettingsScreen los guarda directo en disco,
    // sin pasar por los callbacks de esta pantalla) — sin este refresco,
    // MainTabScreen se quedaba con el valor viejo en memoria hasta cerrar
    // y reabrir la app del todo, y por eso la tarjeta del bebé en "Hoy" y
    // la pantalla "Seguir embarazo" seguían sin aparecer aunque
    // Configuración ya mostrara el modo embarazo activado. Bug reportado
    // por la usuaria tras la versión 20.
    final pregnancy = await _settingsService.loadPregnancySettings();
    final userGoal = await _settingsService.loadUserGoal();
    if (!mounted) return;
    widget.onPregnancyChanged(pregnancy);
    widget.onUserGoalChanged(userGoal);
    setState(() => _goal = pregnancy.enabled ? 'pregnancy' : userGoal);
  }

  Future<void> _openAccountScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AccountScreen(
          user: widget.user,
          themeId: widget.themeId,
          subscriptionService: widget.subscriptionService,
        ),
      ),
    );
    // Al volver de "Mi cuenta", recarga por si el nombre cambió ahí —
    // así la tarjeta de sesión de esta pantalla queda al día sin tener
    // que salir y volver a entrar a la pestaña "Yo".
    _load();
  }

  Future<void> _openReview() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReviewScreen(data: widget.data, themeId: widget.themeId)),
    );
  }

  Future<void> _openStats() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StatsScreen(data: widget.data, themeId: widget.themeId)),
    );
  }

  Future<void> _openTimeline() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimelineScreen(data: widget.data, onDataChanged: widget.onDataChanged, themeId: widget.themeId),
      ),
    );
  }

  Future<void> _openOvulationTest() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OvulationTestScreen(themeId: widget.themeId)),
    );
  }

  Future<void> _openRegister() async {
    // "Vida sexual" y "Autoexamen de mamas" abren la pestaña Registrar
    // (misma pantalla que ya cubre ambas secciones), en vez de duplicar el
    // formulario aquí.
    widget.onNavigateToTab(2);
  }

  /// Abre la vista de solo lectura del campo tocado (Temperatura, Vida
  /// sexual, Peso, Sueño, Autoexamen de mamas o Bebe agua) en vez de
  /// mandar directo a la pestaña Registrar sin foco. Desde ahí, el botón
  /// "Editar" de FieldDetailScreen lleva al formulario correspondiente ya
  /// enfocado en esa sección.
  Future<void> _openFieldDetail(String fieldKey) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FieldDetailScreen(
          themeId: widget.themeId,
          data: widget.data,
          fieldKey: fieldKey,
          onDataChanged: widget.onDataChanged,
          userGoal: _goal,
        ),
      ),
    );
  }

  Future<void> _openPregnancyOrCalendar() async {
    if (widget.pregnancy.enabled && widget.pregnancy.lmp != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PregnancyTrackingScreen(lmp: widget.pregnancy.lmp!, themeId: widget.themeId, isTwins: widget.pregnancy.isTwins),
        ),
      );
    } else {
      widget.onNavigateToTab(1);
    }
  }

  /// Abre la pantalla de resumen (info + evaluación/predicción) que
  /// antecede a los 4 accesos del grid que antes navegaban directo a una
  /// pantalla completa ya existente (Periodo y ciclo, Síntomas y
  /// predicciones, Test de ovulación, Fertilidad). Desde ahí, el botón de
  /// la barra superior lleva a la pantalla completa correspondiente
  /// reutilizando _openPregnancyOrCalendar/_openStats/_openOvulationTest
  /// (vía la misma lógica, reimplementada dentro de QuickSummaryScreen
  /// para no crear una dependencia circular pasando callbacks que a su vez
  /// hacen Navigator.push sobre este mismo context).
  Future<void> _openQuickSummary(String summaryKey) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuickSummaryScreen(
          summaryKey: summaryKey,
          themeId: widget.themeId,
          data: widget.data,
          irregularCycleMode: widget.irregularCycleMode,
          selfReportedCycleLen: widget.selfReportedCycleLen,
          selfReportedPeriodLen: widget.selfReportedPeriodLen,
          pregnancy: widget.pregnancy,
          onNavigateToTab: widget.onNavigateToTab,
        ),
      ),
    );
  }

  // Diseño iOS (2026-09, pedido explícito): mismo patrón que
  // _confirmDeleteAccount en settings_screen.dart (CupertinoAlertDialog +
  // CupertinoDialogAction en vez del AlertDialog/TextButton de Material
  // por defecto) — la lógica de cierre de sesión no cambió en absoluto.
  Future<void> _confirmSignOut() async {
    final s = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(s.signOutConfirmTitle),
        content: Text(s.signOutConfirmBody),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.signOut),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onSignOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final s = AppStrings.of(context);
    final primary = Color(_theme.primary);
    final primaryDark = Color(_theme.primaryDark);
    final predictor = CyclePredictor(
      widget.data,
      forceIrregular: widget.irregularCycleMode,
      selfReportedCycleLen: widget.selfReportedCycleLen,
      selfReportedPeriodLen: widget.selfReportedPeriodLen,
    );
    final stats = StatsCalculator(widget.data);
    final cycleCount = predictor.getCycles().length;
    final hasEnoughData = cycleCount >= 3;

    // Rediseño editorial: header con degradado de color de app + avatar
    // superpuesto sobre fondo blanco circular, seguido de una tarjeta
    // blanca "flotante" (grid de accesos) que se solapa con el header
    // (margen negativo), y el resto de secciones con tarjetas de sombra
    // suave en vez de bordes planos.
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildHeader(s, primary, primaryDark),
        Transform.translate(
          offset: const Offset(0, -24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildGrid(s, primary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimelineCard(s, primary),
              const SizedBox(height: 22),
              _buildGoalSection(s, primary),
              // "Informe"/Análisis de ciclo también depende de periodos
              // registrados (flujo), algo que no existe durante el
              // embarazo — sin este filtro se quedaba invitando a
              // "Registrar periodo" para siempre, aunque no aplique.
              if (_goal != 'pregnancy') ...[
                const SizedBox(height: 22),
                _buildReportSection(s, primary, stats, hasEnoughData),
              ],
              const SizedBox(height: 22),
              _buildQuickLinks(s, primary),
              const SizedBox(height: 20),
              _buildSignOutButton(s),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AppStrings s, Color primary, Color primaryDark) {
    // Antes este encabezado mostraba siempre "Inicie sesión y sincronice
    // sus datos" con un botón que solo abría un aviso de "próximamente" —
    // aunque ya hubiera una sesión real de Firebase activa (AuthGate exige
    // login antes de llegar aquí, así que widget.userEmail nunca está
    // vacío en la práctica). Ahora refleja el estado real: muestra el
    // correo de la cuenta con la que se inició sesión.
    final hasEmail = widget.userEmail.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      // Vuelto al tamaño original de siempre (18/18/18/28, avatar 58 más
      // abajo) — tras varias pruebas de reducirlo, la usuaria pidió
      // dejarlo tal como estaba. El Transform.translate de -24 que sigue
      // a este header (ver build()) sigue solapando la tarjeta blanca
      // igual que antes.
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primary, primaryDark],
        ),
      ),
      // Antes llevaba una flor decorativa (imagen 3D) asomando en la
      // esquina inferior derecha del degradado, detrás del avatar/correo/
      // botón — se quitó a pedido de la usuaria ("quita esa flor").
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: ClipOval(
                      child: Image.asset(
                        'lib/assets/images/avatar_placeholder.png',
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasEmail ? s.meSignedInAs : s.meSignInAndSync,
                          style: const TextStyle(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w600),
                        ),
                        if (hasEmail) ...[
                          const SizedBox(height: 2),
                          Text(
                            _greetingName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: InkWell(
                      onTap: hasEmail ? _openAccountScreen : () => _showComingSoon(s),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Text(
                          hasEmail ? s.meManageAccount : s.meSyncData,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(AppStrings s, Color primary) {
    final items = <_MeGridItem>[
      // "Periodo y ciclo" no aporta nada durante el embarazo (no hay
      // periodos que seguir) — se oculta solo en ese objetivo, se mantiene
      // en "Seguir mi periodo" e "Intentar concebir".
      if (_goal != 'pregnancy') ...[
        _MeGridItem(
          icon: Icons.calendar_month,
          label: s.mePeriodAndCycle,
          onTap: () => _openQuickSummary('periodCycle'),
          colorStart: const Color(0xFFFF6B6B),
          colorEnd: const Color(0xFFE0344A),
        ),
      ],
      // La temperatura basal es una herramienta de método de fertilidad
      // (detectar la ovulación) — solo tiene sentido con "Intentar
      // concebir"; en periodo normal o embarazo no hace falta.
      if (_goal == 'conceive') ...[
        _MeGridItem(
          icon: Icons.thermostat,
          label: s.meTemperature,
          onTap: () => _openFieldDetail('temperature'),
          colorStart: const Color(0xFFFFA14A),
          colorEnd: const Color(0xFFFF7A1F),
        ),
      ],
      // Igual que "Periodo y ciclo": la fase del ciclo y la predicción del
      // próximo periodo no tienen sentido durante el embarazo (no hay
      // ciclo que calcular), así que este acceso también se oculta en ese
      // objetivo — antes quedaba visible y solo llevaba a una pantalla que
      // decía "Sin datos suficientes" para siempre, aunque la usuaria sí
      // tuviera registros (de embarazo, no de flujo).
      if (_goal != 'pregnancy') ...[
        _MeGridItem(
          icon: Icons.insights,
          label: s.meSymptomsAndPredictions,
          onTap: () => _openQuickSummary('symptoms'),
          colorStart: const Color(0xFFB06CFF),
          colorEnd: const Color(0xFF8A3FF0),
        ),
      ],
      // Test de ovulación y Fertilidad: solo tienen sentido con el objetivo
      // "Intentar concebir" — durante el periodo normal o ya en embarazo no
      // aportan, así que se ocultan (pedido de la usuaria de activar cada
      // función solo donde se usa).
      if (_goal == 'conceive') ...[
        _MeGridItem(
          icon: Icons.science_outlined,
          label: s.meOvulationTest,
          onTap: () => _openQuickSummary('ovulationTest'),
          colorStart: const Color(0xFF2FD0D8),
          colorEnd: const Color(0xFF12A8B0),
        ),
      ],
      _MeGridItem(
        icon: Icons.favorite_border,
        label: s.meSexLife,
        onTap: () => _openFieldDetail('sexLife'),
        colorStart: const Color(0xFFFF7FB0),
        colorEnd: const Color(0xFFEF4D8C),
      ),
      if (_goal == 'conceive') ...[
        _MeGridItem(
          icon: Icons.spa_outlined,
          label: s.meFertility,
          onTap: () => _openQuickSummary('fertility'),
          colorStart: const Color(0xFF57D97E),
          colorEnd: const Color(0xFF28B862),
        ),
      ],
      _MeGridItem(
        icon: Icons.monitor_weight_outlined,
        label: s.meWeight,
        onTap: () => _openFieldDetail('weight'),
        colorStart: const Color(0xFF5B9BFF),
        colorEnd: const Color(0xFF2F74EF),
      ),
      _MeGridItem(
        icon: Icons.bedtime_outlined,
        label: s.meSleep,
        onTap: () => _openFieldDetail('sleep'),
        colorStart: const Color(0xFF8888F5),
        colorEnd: const Color(0xFF5C5CE0),
      ),
      _MeGridItem(
        icon: Icons.health_and_safety_outlined,
        label: s.meBreastSelfExam,
        onTap: () => _openFieldDetail('breastSelfExam'),
        colorStart: const Color(0xFFFF6FA0),
        colorEnd: const Color(0xFFE83F7D),
      ),
      _MeGridItem(
        icon: Icons.water_drop_outlined,
        label: s.meDrinkWater,
        onTap: () => _openFieldDetail('water'),
        colorStart: const Color(0xFF3FC7FF),
        colorEnd: const Color(0xFF1F9FE0),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 2.7,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [item.colorStart, item.colorEnd],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: item.colorEnd.withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineCard(AppStrings s, Color primary) {
    return InkWell(
      onTap: _openTimeline,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFB14A), Color(0xFFFF7A1F)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFF7A1F).withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.meTimeline, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(s.meAllRecordsHere, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSection(AppStrings s, Color primary) {
    final options = [
      ('period', s.meGoalTrackPeriod),
      ('conceive', s.meGoalTryConceive),
      ('pregnancy', s.meGoalTrackPregnancy),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.meMyGoal, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) {
            final selected = _goal == o.$1;
            return InkWell(
              onTap: () => _selectGoal(o.$1),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFF7FB0), Color(0xFFE0344A)],
                        )
                      : null,
                  color: selected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: selected ? null : Border.all(color: AppColors.border),
                  boxShadow: selected
                      ? [BoxShadow(color: const Color(0xFFE0344A).withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]
                      : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
                ),
                child: Text(
                  o.$2,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReportSection(AppStrings s, Color primary, StatsCalculator stats, bool hasEnoughData) {
    final avgPeriod = stats.predictor.getAvgPeriodLength();
    final avgCycle = stats.predictor.getAvgCycleLength();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.meReport, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 3),
        Text(s.meCycleAnalysis, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        const SizedBox(height: 10),
        if (!hasEnoughData)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Text(
                  s.meLogThreePeriods,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _openRegister,
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF7FB0), Color(0xFFE0344A)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFE0344A).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Text(
                      s.meLogPeriod,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(child: _reportCard(s.meAvgPeriod, avgPeriod, s.meDayUnit, primary)),
              const SizedBox(width: 12),
              Expanded(child: _reportCard(s.meAvgCycle, avgCycle, s.meDayUnit, primary)),
            ],
          ),
      ],
    );
  }

  Widget _reportCard(String label, int value, String unit, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Text('$value $unit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: primary)),
        ],
      ),
    );
  }

  Widget _buildQuickLinks(AppStrings s, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _quickLinkRow(
          icon: Icons.notifications_active_outlined,
          label: s.reminderScreenEntry,
          colorStart: const Color(0xFFFFA14A),
          colorEnd: const Color(0xFFFF7A1F),
          onTap: _openReminder,
        ),
        const SizedBox(height: 8),
        _quickLinkRow(
          icon: Icons.bar_chart,
          label: s.tabReview,
          colorStart: const Color(0xFF8888F5),
          colorEnd: const Color(0xFF5C5CE0),
          onTap: _openReview,
        ),
        const SizedBox(height: 8),
        _quickLinkRow(
          icon: Icons.settings_outlined,
          label: s.settingsTitle,
          colorStart: const Color(0xFF9AA3AD),
          colorEnd: const Color(0xFF6B7280),
          onTap: _openSettings,
        ),
      ],
    );
  }

  // Filas tipo iOS (Obtener recordatorio / Revisión / Configuración): cada
  // una con su propio degradado de color en el badge del icono, igual que
  // el grid de accesos y la tarjeta de Cronología — diseño aprobado por la
  // usuaria a partir de una preview.
  Widget _quickLinkRow({
    required IconData icon,
    required String label,
    required Color colorStart,
    required Color colorEnd,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colorStart, colorEnd],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: colorEnd.withOpacity(0.35), blurRadius: 5, offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton(AppStrings s) {
    return Center(
      child: InkWell(
        onTap: _confirmSignOut,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, size: 15, color: Color(0xFFE0344A)),
              const SizedBox(width: 6),
              Text(s.signOutTooltip, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFE0344A))),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeGridItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  // Colores del badge tipo iOS Health app: cada categoría tiene su propio
  // degradado (de más claro a más oscuro) en vez del rosa uniforme de
  // antes — diseño aprobado por la usuaria a partir de una preview.
  final Color colorStart;
  final Color colorEnd;

  const _MeGridItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorStart,
    required this.colorEnd,
  });
}

import 'dart:async';
import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import '../models/day_entry.dart';
import '../services/cycle_predictor.dart';
import '../services/daily_notification_service.dart';
import '../services/home_widget_service.dart';
import '../services/partner_service.dart';
import '../services/reminder_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import 'calendar_screen.dart';
import 'me_screen.dart';
import 'paywall_screen.dart';
import 'register_screen.dart';
import 'reminder_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';

/// Pantalla raíz tras iniciar sesión: header compartido (título, botón de
/// ajustes) y un `BottomNavigationBar` de 5 pestañas (Hoy, Calendario,
/// Registrar, Recordatorio, Yo). Reemplaza a la antigua `HomeScreen` como
/// pantalla principal después de `AuthGate`.
///
/// Nota de rediseño (fase 3): antes había 4 pestañas (Calendario, Línea de
/// tiempo, Revisión, Estadísticas) + un Drawer lateral "Mi salud" abierto
/// con el icono ❤️ del header. Ahora "Hoy" es la pestaña de apertura, el
/// calendario pasa a la posición 1, y "Mi salud" se muestra directo como
/// la pestaña "Yo" en vez de vivir en un Drawer — por eso ya no hay
/// endDrawer ni icono ❤️ en el header.
///
/// Nota de rediseño (fase 5): la pestaña "Yo" ahora usa `MeScreen` (grid de
/// accesos rápidos, Cronología, Mi objetivo, Informe) en vez del relleno
/// temporal `HealthMenuScreen(section: null, ...)` de la fase 3. Línea de
/// tiempo, Revisión y Estadísticas (sin pestaña propia desde la fase 3)
/// vuelven a ser alcanzables desde dentro de "Yo" (grid + tarjeta de
/// Cronología + accesos rápidos), en vez de reincorporarse como pestañas.
/// `HealthMenuScreen` deja de usarse aquí pero el archivo se conserva sin
/// borrar (ver health_menu_screen.dart).
class MainTabScreen extends StatefulWidget {
  final AppUser user;
  final VoidCallback onSignOut;

  const MainTabScreen({super.key, required this.user, required this.onSignOut});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> with SingleTickerProviderStateMixin {
  late final _storage = StorageService(widget.user.id);
  final _reminderService = ReminderService();
  final _dailyNotifications = DailyNotificationService();
  final _settingsService = SettingsService();
  final _subscriptionService = SubscriptionService();
  final _homeWidget = HomeWidgetService();

  Map<String, DayEntry> _data = {};
  ReminderSettings _reminderSettings = const ReminderSettings();
  PregnancySettings _pregnancy = const PregnancySettings();
  String _themeId = 'pink';
  bool _loading = true;
  int _currentTab = 0;

  // Pestaña anterior + controlador de animación del indicador "gota" que se
  // desliza y se estira entre pestañas al cambiar de tab (referencia: barra
  // inferior clásica de WhatsApp) — antes el cambio de pestaña activa solo
  // recoloreaba el ícono tocado, sin ningún indicador que se mueva.
  int _previousTab = 0;
  late final AnimationController _navIndicatorController;

  // Índice del ítem que queda bajo el dedo mientras se DESLIZA
  // horizontalmente sobre la barra (null cuando no hay ningún dedo
  // arrastrando, o cuando el dedo apenas se ha movido — ver
  // _navHoverActivateThreshold) — ese ítem se AGRANDA (ver AnimatedScale
  // más abajo), pedido explícito de la usuaria en vez del efecto de gota
  // que se probó antes y no le gustó. Al soltar sobre un ítem distinto de
  // donde empezó el arrastre, esa pestaña pasa a ser la seleccionada. Un
  // toque directo (sin desplazamiento) NUNCA activa el agrandado — la
  // usuaria pidió explícitamente que el efecto sea solo al deslizar.
  int? _navHoverIndex;
  int? _navHoverOriginIndex;
  double? _navPointerDownDx;


  // Citas médicas (incluye recordatorios puntuales de anticonceptivo) —
  // se cargan aquí en vez de en HomeScreen para poder refrescarlas al
  // volver de Configuración, que es donde también se pueden programar.
  // Antes HomeScreen las cargaba solo en su propio initState, así que si
  // se programaba una cita desde Configuración y se volvía al calendario
  // sin pasar por el editor de día, la campana no aparecía.
  List<MedicalAppointment> _appointments = [];

  // Preferencia para ocultar permanentemente el texto "toca cualquier
  // día..." (se guarda en el dispositivo con SettingsService, a
  //).
  bool _hideCalendarHint = false;

  // Interruptor "Ciclo irregular" de Configuración: cuando está activo,
  // se le pasa a CyclePredictor (en esta pantalla y en HomeScreen) para
  // que fuerce un rango de predicción más amplio en vez de una fecha
  // exacta poco realista.
  bool _irregularCycleMode = false;

  // Duración de ciclo/periodo autoinformadas en el cuestionario de
  // "Intentar concebir" (ver widgets/conceive_intake_sheet.dart): se usan
  // como respaldo en CyclePredictor solo mientras no hay suficientes datos
  // reales registrados, para que la predicción sea más precisa desde el
  // principio en vez de asumir siempre 28/5 días.
  int? _selfReportedCycleLen;
  int? _selfReportedPeriodLen;

  // "Mi objetivo" (Configuración/Yo): 'period' | 'conceive' | 'pregnancy' —
  // se carga aquí (igual que _pregnancy/_themeId) solo para poder pasarlo
  // a TodayScreen y resaltar más la tarjeta de ovulación cuando el
  // objetivo es "Intentar concebir".
  String _userGoal = 'period';

  Future<void> _dismissCalendarHint() async {
    setState(() => _hideCalendarHint = true);
    await _settingsService.saveHideCalendarHint(true);
  }

  @override
  void initState() {
    super.initState();
    _load();
    _navIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..value = 1; // arranca "asentado" en la pestaña 0, sin animar de golpe.
  }

  @override
  void dispose() {
    _navIndicatorController.dispose();
    super.dispose();
  }

  int _navIndexForDx(double dx, double barWidth, double itemWidth, int itemCount) {
    final x = dx.clamp(0.0, barWidth);
    return (x / itemWidth).floor().clamp(0, itemCount - 1);
  }

  // Cuánto tiene que moverse el dedo desde donde bajó para que se
  // considere un arrastre de verdad y arranque el agrandado — por debajo
  // de esto se trata como un toque normal y no pasa nada especial.
  static const _navHoverActivateThreshold = 10.0;

  // Se usa `Listener` (eventos de puntero en bruto) y no
  // `GestureDetector.onHorizontalDrag*` a propósito: cada ícono ya tiene su
  // propio `onTap`, y un reconocedor de arrastre del padre puede perder el
  // arbitraje de gestos contra esos toques y no llegar a dispararse nunca.
  void _handleNavPointerDown(PointerDownEvent event, double barWidth, double itemWidth, int itemCount) {
    final dx = event.localPosition.dx.clamp(0.0, barWidth);
    // Solo se guarda el punto de partida — _navHoverIndex se queda en
    // null (sin agrandar nada todavía) hasta que _handleNavPointerMove
    // confirme que el dedo se desplazó de verdad.
    _navPointerDownDx = dx;
    _navHoverOriginIndex = _navIndexForDx(dx, barWidth, itemWidth, itemCount);
  }

  void _handleNavPointerMove(PointerMoveEvent event, double barWidth, double itemWidth, int itemCount) {
    final downDx = _navPointerDownDx;
    if (downDx == null) return;
    final dx = event.localPosition.dx.clamp(0.0, barWidth);
    if (_navHoverIndex == null && (dx - downDx).abs() < _navHoverActivateThreshold) {
      return; // todavía dentro del margen de un toque normal, no de un arrastre.
    }
    final index = _navIndexForDx(dx, barWidth, itemWidth, itemCount);
    if (_navHoverIndex != index) setState(() => _navHoverIndex = index);
  }

  /// Al soltar el dedo: si hubo arrastre real y terminó sobre un ítem
  /// distinto de donde empezó, esa pestaña pasa a ser la seleccionada —
  /// un toque directo (sin desplazamiento, _navHoverIndex nunca llegó a
  /// activarse) lo sigue gestionando el onTap propio de cada ítem, tal
  /// cual funcionaba antes de este cambio.
  void _handleNavPointerUp() {
    final origin = _navHoverOriginIndex;
    final index = _navHoverIndex;
    setState(() {
      _navHoverIndex = null;
      _navHoverOriginIndex = null;
      _navPointerDownDx = null;
    });
    if (index != null && origin != null && index != origin) {
      _selectTab(index);
    }
  }

  void _handleNavPointerCancel() {
    setState(() {
      _navHoverIndex = null;
      _navHoverOriginIndex = null;
      _navPointerDownDx = null;
    });
  }

  /// Cambia de pestaña y dispara la animación del indicador "gota" desde la
  /// posición anterior hasta la nueva.
  void _selectTab(int index) {
    if (index == _currentTab) return;
    setState(() {
      _previousTab = _currentTab;
      _currentTab = index;
    });
    _navIndicatorController
      ..reset()
      ..forward();
  }

  Future<void> _load() async {
    final data = await _storage.loadAll();
    final reminders = await _reminderService.loadSettings();
    final pregnancy = await _settingsService.loadPregnancySettings();
    final themeId = await _settingsService.loadThemeId();
    final daily = await _settingsService.loadDailyReminderSettings();
    final pill = await _settingsService.loadPillReminderSettings();
    final hideCalendarHint = await _settingsService.loadHideCalendarHint();
    final irregularCycleMode = await _settingsService.loadIrregularCycleMode();
    final appointments = await _settingsService.loadMedicalAppointments();
    final userGoal = await _settingsService.loadUserGoal();
    final selfReportedCycleLen = await _settingsService.loadConceiveAvgCycleLength();
    final selfReportedPeriodLen = await _settingsService.loadConceiveAvgPeriodLength();

    if (!mounted) return;
    setState(() {
      _data = data;
      _reminderSettings = reminders;
      _pregnancy = pregnancy;
      _themeId = themeId;
      _hideCalendarHint = hideCalendarHint;
      _irregularCycleMode = irregularCycleMode;
      _appointments = appointments;
      _userGoal = userGoal;
      _selfReportedCycleLen = selfReportedCycleLen;
      _selfReportedPeriodLen = selfReportedPeriodLen;
      _loading = false;
    });

    _syncPeriodReminder();
    await _dailyNotifications.rescheduleDailyReminder(daily);
    await _dailyNotifications.reschedulePillReminder(pill);
    // Recordatorio de "reenganche" pedido por el usuario: se reprograma
    // cada vez que se entra a la app (aquí, no en AppOpenController,
    // porque esto solo debe empezar a contar una vez ya hay sesión
    // iniciada). Si no vuelve a abrir la app en 2 días, este aviso ya
    // programado se dispara solo — ver
    // DailyNotificationService.scheduleReengagementCheckIn.
    await _dailyNotifications.requestPermissions();
    await _dailyNotifications.scheduleReengagementCheckIn();

    // Vincula RevenueCat al usuario de Firebase Auth (mismo id en todos
    // los dispositivos) y refresca si ya tiene una suscripción de pago
    // activa. No bloquea la carga de la pantalla si falla o si la API key
    // sigue siendo el placeholder (ver TODO en subscription_service.dart).
    await _subscriptionService.configure(firebaseUid: widget.user.id);
    await _subscriptionService.refreshCachedStatus();
    if (mounted) setState(() {});
  }

  void _syncPeriodReminder() {
    // Se pasa forceIrregular igual que en HomeScreen: si el ciclo es
    // irregular, predictNextPeriod() ya usa el promedio ajustado (ver
    // CyclePredictor.getAvgCycleLength), así que el recordatorio programado
    // coincide con lo que ve la usuaria en el calendario, no con un
    // cálculo aparte que podría ignorar el modo irregular.
    final predictor = CyclePredictor(
      _data,
      forceIrregular: _irregularCycleMode,
      selfReportedCycleLen: _selfReportedCycleLen,
      selfReportedPeriodLen: _selfReportedPeriodLen,
    );
    final nextPeriod = predictor.predictNextPeriod();
    final ovulation = predictor.predictOvulation(nextPeriod);
    _reminderService.reschedule(_reminderSettings, nextPeriod, ovulationDate: ovulation);
    _syncHomeWidget(predictor, nextPeriod);
  }

  /// Empuja el día de ciclo actual y la cuenta atrás al próximo periodo
  /// al widget real de pantalla de inicio (ver HomeWidgetService), cada
  /// vez que se reprograman los recordatorios — es decir, cada vez que
  /// cambian los datos que también afectarían a esa predicción. Todo el
  /// fallo es silencioso (ver HomeWidgetService.update): si el widget no
  /// está disponible o el canal falla, el resto de la app sigue igual.
  void _syncHomeWidget(CyclePredictor predictor, DateTime? nextPeriod) {
    if (!mounted) return;
    final s = AppStrings.of(context);
    final cycleDay = predictor.currentDayInCycle();

    String periodLine = '';
    if (nextPeriod != null) {
      final today = DateTime.now();
      final daysUntil = DateTime(nextPeriod.year, nextPeriod.month, nextPeriod.day)
          .difference(DateTime(today.year, today.month, today.day))
          .inDays;
      if (daysUntil >= 0) periodLine = s.homeWidgetDaysUntilPeriod(daysUntil);
    }

    _homeWidget.update(
      cycleDayLine: cycleDay != null ? s.homeWidgetCycleDay(cycleDay) : s.homeWidgetNoDataLine,
      periodLine: periodLine,
    );
  }

  /// Se pasan a ReminderScreen (Mi salud) como callbacks — la tarjeta de
  /// recordatorio ya no vive en la pantalla de Inicio (ver
  /// HealthMenuSection.reminder), pero MainTabScreen sigue siendo el
  /// dueño del estado porque _syncPeriodReminder necesita _data e
  /// _irregularCycleMode, que solo existen aquí.
  Future<void> _onReminderToggle(bool value) async {
    setState(() => _reminderSettings = _reminderSettings.copyWith(enabled: value));
    await _reminderService.saveSettings(_reminderSettings);
    if (value) {
      await _reminderService.requestPermissions();
    }
    _syncPeriodReminder();
  }

  Future<void> _onReminderDaysChanged(int days) async {
    setState(() => _reminderSettings = _reminderSettings.copyWith(daysBefore: days));
    await _reminderService.saveSettings(_reminderSettings);
    _syncPeriodReminder();
  }

  Future<void> _onOvulationReminderToggle(bool value) async {
    setState(() => _reminderSettings = _reminderSettings.copyWith(ovulationEnabled: value));
    await _reminderService.saveSettings(_reminderSettings);
    if (value) {
      await _reminderService.requestPermissions();
    }
    _syncPeriodReminder();
  }

  Future<void> _onFertileReminderToggle(bool value) async {
    setState(() => _reminderSettings = _reminderSettings.copyWith(fertileEnabled: value));
    await _reminderService.saveSettings(_reminderSettings);
    if (value) {
      await _reminderService.requestPermissions();
    }
    _syncPeriodReminder();
  }

  Future<void> _onDataChanged(Map<String, DayEntry> updated) async {
    await _storage.saveAll(updated);
    setState(() => _data = updated);
    _syncPeriodReminder();
  }

  /// Pasado a MeScreen para que el chip "Seguir mi embarazo" de "Mi
  /// objetivo" pueda activar/desactivar el modo embarazo real (mismo
  /// interruptor que antes solo vivía en HealthMenuScreen/Configuración),
  /// sin crear un estado paralelo que lo contradiga.
  Future<void> _onPregnancyChanged(PregnancySettings updated) async {
    setState(() => _pregnancy = updated);
    await _settingsService.savePregnancySettings(updated);
    // Sube el cambio a Firestore por si hay algún socio vinculado viendo
    // este embarazo (ver PartnerService) — de mejor esfuerzo, no bloquea.
    unawaited(PartnerService().syncPregnancyData(widget.user.id));
  }

  /// Pasado a MeScreen para que, cuando el objetivo cambie desde los chips
  /// de "Mi objetivo" en esa misma pantalla (no desde Configuración), esta
  /// copia (_userGoal — la que reciben Hoy/Calendario/Registrar/
  /// Recordatorios) se actualice también, en vez de quedarse desactualizada
  /// hasta la próxima vez que se recargue Configuración. MeScreen ya guarda
  /// el valor con SettingsService.saveUserGoal, así que aquí solo hace
  /// falta reflejarlo en memoria.
  void _onUserGoalChanged(String goal) {
    setState(() => _userGoal = goal);
  }

  /// Cambia la pestaña activa del BottomNavigationBar — usado por MeScreen
  /// para los accesos del grid que ya tienen su propia pestaña (Periodo y
  /// ciclo -> Calendario, Vida sexual/Temperatura/etc. -> Registrar) en vez
  /// de duplicar esas pantallas con un Navigator.push.
  void _navigateToTab(int index) {
    _selectTab(index);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          userId: widget.user.id,
          onThemeChanged: (id) => setState(() => _themeId = id),
          data: _data,
          onDataChanged: _onDataChanged,
          onSignOut: widget.onSignOut,
        ),
      ),
    );
    // Al volver de Configuración, refrescamos por si cambió el modo
    // embarazo, citas médicas (se pueden programar desde ahí) u otros
    // ajustes que afectan esta pantalla.
    final pregnancy = await _settingsService.loadPregnancySettings();
    final themeId = await _settingsService.loadThemeId();
    final irregularCycleMode = await _settingsService.loadIrregularCycleMode();
    final appointments = await _settingsService.loadMedicalAppointments();
    final userGoal = await _settingsService.loadUserGoal();
    final selfReportedCycleLen = await _settingsService.loadConceiveAvgCycleLength();
    final selfReportedPeriodLen = await _settingsService.loadConceiveAvgPeriodLength();
    if (!mounted) return;
    setState(() {
      _pregnancy = pregnancy;
      _themeId = themeId;
      _irregularCycleMode = irregularCycleMode;
      _appointments = appointments;
      _userGoal = userGoal;
      _selfReportedCycleLen = selfReportedCycleLen;
      _selfReportedPeriodLen = selfReportedPeriodLen;
    });
  }

  /// Recarga solo las citas médicas — usado tras cerrar el editor de un
  /// día (por si se programó/eliminó una cita o el recordatorio puntual
  /// de anticonceptivo desde ahí), sin repetir toda la carga de _load().
  Future<void> _reloadAppointments() async {
    final appointments = await _settingsService.loadMedicalAppointments();
    if (mounted) setState(() => _appointments = appointments);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    final s = AppStrings.of(context);
    final theme = themeById(_themeId);
    // Nota: la predicción real que ve la usuaria (tarjeta de estado +
    // calendario) se calcula dentro de HomeScreen, que sí recibe
    // irregularCycleMode más abajo — no se duplica aquí.

    // Las 5 pestañas del rediseño (fase 3): Hoy, Calendario, Registrar,
    // Recordatorio, Yo. "Registrar" (fase 4) es RegisterScreen: pantalla
    // completa de registro del día de hoy con las secciones ampliadas
    // (flujo, vida sexual detallada, medicamento, síntomas, ánimo,
    // autoexamen de mamas, energía, diario, piel y cabello) que no caben
    // en el editor rápido `DayEditorSheet`. "Recordatorio" reutiliza ReminderScreen
    // standalone: su constructor ya recibe exactamente lo que MainTabScreen
    // gestiona (settings, hasPrediction, los 4 callbacks, themeId), así
    // que encaja sin refactor. "Yo" (fase 5) usa MeScreen: grid de accesos
    // rápidos, Cronología, Mi objetivo y Análisis del ciclo, con su propio
    // botón "Cerrar sesión" y confirmación interna (ver MeScreen._confirmSignOut).
    final tabs = [
      TodayScreen(
        data: _data,
        pregnancy: _pregnancy,
        irregularCycleMode: _irregularCycleMode,
        selfReportedCycleLen: _selfReportedCycleLen,
        selfReportedPeriodLen: _selfReportedPeriodLen,
        themeId: _themeId,
        userId: widget.user.id,
        userEmail: widget.user.email,
        userGoal: _userGoal,
        onDataChanged: _onDataChanged,
      ),
      CalendarScreen(
        data: _data,
        onDataChanged: _onDataChanged,
        irregularCycleMode: _irregularCycleMode,
        selfReportedCycleLen: _selfReportedCycleLen,
        selfReportedPeriodLen: _selfReportedPeriodLen,
        appointments: _appointments,
        onAppointmentsChanged: _reloadAppointments,
        themeId: _themeId,
        userGoal: _userGoal,
      ),
      RegisterScreen(
        data: _data,
        onDataChanged: _onDataChanged,
        themeId: _themeId,
        onNavigateToTab: _navigateToTab,
        userGoal: _userGoal,
      ),
      ReminderScreen(
        settings: _reminderSettings,
        hasPrediction: CyclePredictor(
              _data,
              forceIrregular: _irregularCycleMode,
              selfReportedCycleLen: _selfReportedCycleLen,
              selfReportedPeriodLen: _selfReportedPeriodLen,
            ).predictNextPeriod() !=
            null,
        onPeriodToggle: _onReminderToggle,
        onDaysChanged: _onReminderDaysChanged,
        onOvulationToggle: _onOvulationReminderToggle,
        onFertileToggle: _onFertileReminderToggle,
        themeId: _themeId,
        data: _data,
        irregularCycleMode: _irregularCycleMode,
        selfReportedCycleLen: _selfReportedCycleLen,
        selfReportedPeriodLen: _selfReportedPeriodLen,
        userGoal: _userGoal,
      ),
      MeScreen(
        userId: widget.user.id,
        userEmail: widget.user.email,
        user: widget.user,
        subscriptionService: _subscriptionService,
        themeId: _themeId,
        onThemeChanged: (id) => setState(() => _themeId = id),
        data: _data,
        onDataChanged: _onDataChanged,
        irregularCycleMode: _irregularCycleMode,
        selfReportedCycleLen: _selfReportedCycleLen,
        selfReportedPeriodLen: _selfReportedPeriodLen,
        pregnancy: _pregnancy,
        onPregnancyChanged: _onPregnancyChanged,
        reminderSettings: _reminderSettings,
        hasPeriodPrediction: CyclePredictor(
              _data,
              forceIrregular: _irregularCycleMode,
              selfReportedCycleLen: _selfReportedCycleLen,
              selfReportedPeriodLen: _selfReportedPeriodLen,
            ).predictNextPeriod() !=
            null,
        onReminderToggle: _onReminderToggle,
        onReminderDaysChanged: _onReminderDaysChanged,
        onOvulationReminderToggle: _onOvulationReminderToggle,
        onFertileReminderToggle: _onFertileReminderToggle,
        onNavigateToTab: _navigateToTab,
        onSignOut: widget.onSignOut,
        userGoal: _userGoal,
        onUserGoalChanged: _onUserGoalChanged,
      ),
    ];

    // Alto de la barra de estado del sistema (notch/isla dinámica incluida).
    // La cabecera rosa ya no vive dentro de SafeArea (ver más abajo) para
    // que su degradado pinte también esa franja de arriba — pedido de la
    // usuaria, que antes veía un hueco blanco entre la barra de estado y la
    // cabecera — así que aquí se suma manualmente ese alto al padding
    // superior del contenedor, para que el texto/ícono sigan cayendo justo
    // debajo del notch en vez de quedar tapados por él.
    final statusBarHeight = MediaQuery.of(context).padding.top;

    // Iconos de la barra de estado (hora/batería/wifi) en blanco, ya que
    // ahora esa franja queda pintada con el degradado rosa/oscuro de la
    // cabecera en vez del fondo claro de antes — con iconos oscuros por
    // defecto quedaban casi invisibles sobre ese fondo.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // En la pestaña Hoy el borde inferior de la cabecera se recorta
            // en forma de onda (pedido explícito de la usuaria, a partir de
            // su maqueta de referencia "Después"); en el resto de pestañas
            // se mantiene el borde recto original para no alterar su
            // aspecto ya aprobado.
            ClipPath(
              clipper: _currentTab == 0 ? const _HeaderWaveClipper() : null,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, statusBarHeight + 8, 16, _currentTab == 0 ? 20 : 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(theme.primary), Color(theme.primaryDark)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_currentTab == 0)
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('CicloPlus',
                                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                            )
                          else
                            const Text('🌸 CicloPlus',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                          Positioned(
                            right: 0,
                            child: IconButton(
                              onPressed: _openSettings,
                              icon: const Icon(Icons.settings, color: Colors.white, size: 24),
                              tooltip: s.settingsTooltip,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: tabs[_currentTab]),
          ],
        ),
      ),
      bottomNavigationBar: _buildFloatingNavBar(theme, s),
      ),
    );
  }

  /// Barra inferior tipo "pill" flotante: fondo blanco redondeado con
  /// sombra suave (en vez del BottomNavigationBar plano de Material por
  /// defecto), íconos Material reales (no emojis, para que se vean nítidos
  /// y consistentes en cualquier dispositivo), y un resaltado circular de
  /// color del tema que se mueve al tab que se toca (antes solo cambiaba
  /// el color del ícono/texto, sin ningún fondo). El tab "Registrar" (el
  /// del medio) es más grande y siempre lleva su círculo relleno de color,
  /// calcando la referencia de la usuaria (ícono "+" prominente en el
  /// centro de la barra).
  Widget _buildFloatingNavBar(AppThemeOption theme, AppStrings s) {
    final primary = Color(theme.primary);
    final primaryDark = Color(theme.primaryDark);

    final items = <_NavItemData>[
      _NavItemData(icon: Icons.spa_outlined, activeIcon: Icons.spa, label: s.tabToday),
      _NavItemData(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: s.tabCalendar),
      _NavItemData(icon: Icons.add, activeIcon: Icons.add, label: s.tabLog, isCentral: true),
      _NavItemData(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: s.tabReminder),
      _NavItemData(icon: Icons.person_outline, activeIcon: Icons.person, label: s.tabMe),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: primaryDark.withOpacity(0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / items.length;
              return Listener(
                // translucent: deja pasar el tap individual de cada ítem tal
                // cual, este Listener solo OBSERVA el puntero para agrandar
                // el ítem que quede debajo mientras se arrastra.
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) =>
                    _handleNavPointerDown(event, constraints.maxWidth, itemWidth, items.length),
                onPointerMove: (event) =>
                    _handleNavPointerMove(event, constraints.maxWidth, itemWidth, items.length),
                onPointerUp: (_) => _handleNavPointerUp(),
                onPointerCancel: (_) => _handleNavPointerCancel(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildLiquidIndicator(itemWidth, primary),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(items.length, (index) {
                        final item = items[index];
                        final isSelected = index == _currentTab;
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _selectTab(index),
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 140),
                              curve: Curves.easeOut,
                              scale: _navHoverIndex == index ? 1.55 : 1.0,
                              child: item.isCentral
                                  ? _buildCentralNavItem(item, isSelected, primary, primaryDark)
                                  : _buildNavItem(item, isSelected, primary),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Indicador "gota" que vive detrás de los íconos: una píldora que se
  /// desliza de la pestaña anterior a la nueva y se ESTIRA a medio camino
  /// (como una gota de agua/burbuja líquida) antes de volver a su tamaño
  /// normal y asentarse bajo el ícono activo — el mismo efecto clásico de
  /// la barra inferior de WhatsApp al deslizar entre pestañas.
  Widget _buildLiquidIndicator(double itemWidth, Color primary) {
    const baseWidth = 22.0;
    const baseHeight = 5.0;
    return AnimatedBuilder(
      animation: _navIndicatorController,
      builder: (context, _) {
        final rawT = _navIndicatorController.value.clamp(0.0, 1.0);
        final t = Curves.easeOutCubic.transform(rawT);
        final startCenter = (_previousTab + 0.5) * itemWidth;
        final endCenter = (_currentTab + 0.5) * itemWidth;
        final centerX = startCenter + (endCenter - startCenter) * t;

        // El estiramiento crece con la distancia recorrida y alcanza su
        // punto máximo a mitad de la animación (t=0.5), justo como una gota
        // que se alarga al despegarse y se recoge de nuevo al llegar. Se
        // subió el multiplicador (antes 0.32) y además la altura se
        // adelgaza un poco mientras está estirada (como líquido real) para
        // que el efecto se note más "gomoso", a petición de la usuaria.
        final travel = (endCenter - startCenter).abs();
        final stretchFactor = sin(pi * rawT);
        final stretch = travel.clamp(0.0, itemWidth * 4) * 0.55 * stretchFactor;
        final width = baseWidth + stretch;
        final height = (baseHeight - stretch * 0.05).clamp(2.5, baseHeight);

        return Positioned(
          bottom: 4,
          left: centerX - width / 2,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(_NavItemData item, bool isSelected, Color primary) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isSelected ? primary.withOpacity(0.15) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 22,
              color: isSelected ? primary : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? primary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  /// Ítem central "Registrar": círculo relleno grande de color del tema,
  /// siempre visible con ese estilo (no solo al seleccionarlo) para que
  /// destaque como acción rápida de acceso directo, igual que el botón "+"
  /// central de la referencia.
  Widget _buildCentralNavItem(_NavItemData item, bool isSelected, Color primary, Color primaryDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [primary, primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.45),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 3),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? primary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

}

/// Datos de un ítem de la barra flotante `_buildFloatingNavBar`. `isCentral`
/// marca el tab "Registrar", que se dibuja distinto (círculo relleno
/// siempre visible en vez del resaltado solo-al-seleccionar de los demás).
class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isCentral;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isCentral = false,
  });
}

/// Recorta el borde inferior de la cabecera en una onda suave, en vez del
/// filo recto de un rectángulo — mismo lenguaje visual de la maqueta
/// "Después" aprobada por la usuaria para la pestaña Hoy.
class _HeaderWaveClipper extends CustomClipper<Path> {
  const _HeaderWaveClipper();

  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 22);
    path.quadraticBezierTo(size.width * 0.26, size.height, size.width * 0.52, size.height - 12);
    path.quadraticBezierTo(size.width * 0.78, size.height - 26, size.width, size.height - 4);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

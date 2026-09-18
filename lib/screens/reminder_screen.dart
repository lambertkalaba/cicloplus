import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/day_entry.dart';
import '../services/cycle_predictor.dart';
import '../services/daily_notification_service.dart';
import '../services/reminder_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/reminder_card.dart' show kReminderDayOptions;
import '../widgets/reminder_time_sheet.dart';

/// Pantalla "Obtener Recordatorio", rediseñada a partir de una captura de
/// referencia que el usuario compartió (fondo degradado rosa con flores
/// sutiles, título grande en dos líneas, tarjeta blanca con 3
/// interruptores: Periodo, Ovulación, Días fértiles). Antes esto vivía
/// como una tarjeta compacta ("ReminderCard") dentro de la pantalla de
/// Inicio; se movió aquí (dentro de Mi salud) a petición del usuario, con
/// solo el aviso de Periodo real — ahora se agregan también Ovulación y
/// Días fértiles como notificaciones reales (ver ReminderService).
///
/// ---- Ampliación "selector día/hora precargado" ----
/// Todos los interruptores de esta pantalla, al activarse, abren
/// ReminderTimeSheet con un valor por defecto YA CALCULADO a partir de
/// `data` (vía CyclePredictor) en vez de guardar un booleano ciego que no
/// programaba nada útil. `data` es el único campo nuevo del constructor:
/// el resto de pantallas que instancian ReminderScreen ya tenían el mapa
/// de registros disponible (MainTabScreen._data, MeScreen.data,
/// SettingsScreen.widget.data), así que no hizo falta cargar nada nuevo,
/// solo pasarlo hacia abajo.
class ReminderScreen extends StatefulWidget {
  final ReminderSettings settings;
  final bool hasPrediction;
  final ValueChanged<bool> onPeriodToggle;
  final ValueChanged<int> onDaysChanged;
  final ValueChanged<bool> onOvulationToggle;
  final ValueChanged<bool> onFertileToggle;
  final String themeId;

  /// Registros del ciclo — se usa para calcular los valores por defecto
  /// inteligentes que se precargan en ReminderTimeSheet (próximo periodo,
  /// duración media del periodo, ovulación, ventana fértil). Antes
  /// ReminderScreen no necesitaba estos datos porque los switches nuevos
  /// (periodStart/periodEnd/enterPeriod/autoexamen/agua/fase) no
  /// programaban nada real; ahora sí, así que hace falta el mismo
  /// CyclePredictor que ya usa el resto de la app.
  final Map<String, DayEntry> data;
  final bool irregularCycleMode;

  // Duración de ciclo/periodo autoinformadas en el cuestionario de
  // "Intentar concebir" — respaldo para CyclePredictor mientras no hay
  // suficientes datos reales (ver conceive_intake_sheet.dart).
  final int? selfReportedCycleLen;
  final int? selfReportedPeriodLen;

  // "Mi objetivo" (Configuración/Yo): 'period' | 'conceive' | 'pregnancy' —
  // los recordatorios de ventana fértil/ovulación solo se muestran con
  // "Intentar concebir" (ver más abajo, junto a esos dos _iosRow).
  final String userGoal;

  const ReminderScreen({
    super.key,
    required this.settings,
    required this.hasPrediction,
    required this.onPeriodToggle,
    required this.onDaysChanged,
    required this.onOvulationToggle,
    required this.onFertileToggle,
    this.themeId = 'pink',
    this.data = const {},
    this.irregularCycleMode = false,
    this.selfReportedCycleLen,
    this.selfReportedPeriodLen,
    this.userGoal = 'period',
  });

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final SettingsService _settingsService = SettingsService();
  final DailyNotificationService _dailyNotifications = DailyNotificationService();
  final ReminderService _reminderService = ReminderService();

  // Estado local propio de la pantalla, inicializado desde widget.settings.
  // Es necesario porque MainTabScreen reconstruye su lista `tabs` completa
  // en cada build() (sin IndexedStack), así que widget.settings es una
  // FOTO fija tomada en cada reconstrucción, y aunque el callback
  // (onOvulationToggle, etc.) sí actualiza el estado del padre, no hay
  // garantía de que llegue a tiempo antes del próximo frame. Sin estado
  // local, los interruptores de Ovulación y Días fértiles no se veían
  // cambiar visualmente al tocarlos.
  late ReminderSettings _settings;

  // ---- Estado ampliado (fase "Recordatorio"): pastilla, citas, estilo de
  // vida y notificaciones. Se cargan aparte en _loadExtras() porque viven
  // en SettingsService (no en ReminderSettings/ReminderService, que sigue
  // gestionando solo periodo/ovulación/fértil) — mismo patrón de carga
  // async que ya usaba HealthMenuScreen antes de esta ampliación.
  DailyTimeReminderSettings _pillReminder = const DailyTimeReminderSettings(time: '08:00');
  DailyTimeReminderSettings _dailyReminder = const DailyTimeReminderSettings(time: '20:00');
  List<MedicalAppointment> _appointments = [];

  // Autoexamen de mamas: ahora guarda también la fecha/hora exacta elegida
  // en el sheet (antes era un bool suelto sin notificación real).
  bool _breastSelfExamReminder = false;
  DateTime? _breastSelfExamAt;

  // Agua: reutiliza DailyTimeReminderSettings tal cual (mismo modelo que
  // Píldora/Registro Diario) porque es un hábito diario sin fecha propia —
  // ver decisión documentada en SettingsService.
  DailyTimeReminderSettings _drinkWaterReminder = const DailyTimeReminderSettings(time: '10:00');

  // Fase del ciclo: bool + hora del día en la que revisar/notificar el
  // cambio de fase (ver decisión documentada en SettingsService).
  bool _cyclePhaseReminder = false;
  String _cyclePhaseReminderTime = '09:00';

  bool _extrasLoading = true;

  bool get _anyEnabled => _settings.enabled || _settings.ovulationEnabled || _settings.fertileEnabled;

  CyclePredictor get _predictor => CyclePredictor(
        widget.data,
        forceIrregular: widget.irregularCycleMode,
        selfReportedCycleLen: widget.selfReportedCycleLen,
        selfReportedPeriodLen: widget.selfReportedPeriodLen,
      );

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    final pill = await _settingsService.loadPillReminderSettings();
    final daily = await _settingsService.loadDailyReminderSettings();
    final appointments = await _settingsService.loadMedicalAppointments();
    final breastSelfExam = await _settingsService.loadBreastSelfExamReminderEnabled();
    final breastSelfExamAt = await _settingsService.loadBreastSelfExamReminderAt();
    final drinkWater = await _settingsService.loadDrinkWaterReminderSettings();
    final cyclePhase = await _settingsService.loadCyclePhaseReminderEnabled();
    final cyclePhaseTime = await _settingsService.loadCyclePhaseReminderTime();
    if (!mounted) return;
    setState(() {
      _pillReminder = pill;
      _dailyReminder = daily;
      _appointments = appointments;
      _breastSelfExamReminder = breastSelfExam;
      _breastSelfExamAt = breastSelfExamAt;
      _drinkWaterReminder = drinkWater;
      _cyclePhaseReminder = cyclePhase;
      _cyclePhaseReminderTime = cyclePhaseTime;
      _extrasLoading = false;
    });
  }

  // ---- Cálculo de valores por defecto inteligentes (nunca se le pide a
  // la usuaria que calcule nada a mano) ----

  /// Inicio del período / Introducir período: fecha prevista del próximo
  /// periodo, 9:00 (misma hora que ReminderService._scheduleSimple usaba
  /// para todos los avisos antes de esta ampliación).
  DateTime? get _periodStartDefault {
    final next = _predictor.predictNextPeriod();
    if (next == null) return null;
    return DateTime(next.year, next.month, next.day, 9, 0);
  }

  /// Fin del período: nextPeriodStart + duración media del periodo, 9:00.
  DateTime? get _periodEndDefault {
    final next = _predictor.predictNextPeriod();
    if (next == null) return null;
    final end = next.add(Duration(days: _predictor.getAvgPeriodLength()));
    return DateTime(end.year, end.month, end.day, 9, 0);
  }

  /// Ventana fértil: por defecto, `daysBefore` días antes del inicio de la
  /// ventana fértil calculada (`predict().fertileRangeStart` si el ciclo es
  /// irregular, o de lo contrario ovulación-5, mismo criterio que
  /// ReminderService.reschedule ya usaba). 2 días antes por defecto: ni tan
  /// pronto que pierda relevancia, ni tan tarde que no dé tiempo a
  /// prepararse.
  DateTime _fertileWindowStart() {
    final prediction = _predictor.predict();
    if (prediction.fertileRangeStart != null) return prediction.fertileRangeStart!;
    final ov = prediction.ovulationDate;
    if (ov != null) return ov.subtract(const Duration(days: 5));
    return DateTime.now();
  }

  DateTime? get _fertileDefault {
    if (_predictor.predictNextPeriod() == null) return null;
    final start = _fertileWindowStart().subtract(Duration(days: _settings.daysBefore));
    return DateTime(start.year, start.month, start.day, 9, 0);
  }

  /// Día de ovulación: CyclePredictor.predict().ovulationDate, 9:00 salvo
  /// que la usuaria ya haya elegido otra hora antes.
  DateTime? get _ovulationDefault {
    final ov = _predictor.predict().ovulationDate;
    if (ov == null) return null;
    return DateTime(ov.year, ov.month, ov.day, 9, 0);
  }

  /// Autoexamen de mamas: nextPeriodStart + duración media del periodo + 3
  /// días. Inferencia médica razonable (no un estándar clínico rígido): la
  /// práctica común recomienda hacerlo unos días después de terminar el
  /// período, cuando el pecho está menos sensible por los cambios
  /// hormonales del ciclo — 3 días se eligió como margen de seguridad
  /// simple sobre la fecha en la que se espera que termine el período.
  DateTime? get _breastSelfExamDefault {
    final next = _predictor.predictNextPeriod();
    if (next == null) return null;
    final day = next.add(Duration(days: _predictor.getAvgPeriodLength() + 3));
    return DateTime(day.year, day.month, day.day, 9, 0);
  }

  Future<void> _togglePillReminder(bool value) async {
    final updated = _pillReminder.copyWith(enabled: value);
    setState(() => _pillReminder = updated);
    await _settingsService.savePillReminderSettings(updated);
    if (value) await _dailyNotifications.requestPermissions();
    await _dailyNotifications.reschedulePillReminder(updated);
  }

  Future<void> _pickPillReminderTime() async {
    final parts = _pillReminder.time.split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await ReminderTimePickerSheet.show(
      context: context,
      initialTime: initial,
      primary: const Color(0xFFFF9500),
    );
    if (picked == null) return;
    final time = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final updated = _pillReminder.copyWith(time: time);
    setState(() => _pillReminder = updated);
    await _settingsService.savePillReminderSettings(updated);
    await _dailyNotifications.reschedulePillReminder(updated);
  }

  Future<void> _toggleDailyReminder(bool value) async {
    final updated = _dailyReminder.copyWith(enabled: value);
    setState(() => _dailyReminder = updated);
    await _settingsService.saveDailyReminderSettings(updated);
    if (value) await _dailyNotifications.requestPermissions();
    await _dailyNotifications.rescheduleDailyReminder(updated);
  }

  Future<void> _pickDailyReminderTime() async {
    final parts = _dailyReminder.time.split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final theme = themeById(widget.themeId);
    final picked = await ReminderTimePickerSheet.show(
      context: context,
      initialTime: initial,
      primary: Color(theme.primary),
    );
    if (picked == null) return;
    final time = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final updated = _dailyReminder.copyWith(time: time);
    setState(() => _dailyReminder = updated);
    await _settingsService.saveDailyReminderSettings(updated);
    await _dailyNotifications.rescheduleDailyReminder(updated);
  }

  // ==================== Selector día/hora precargado ====================
  // Punto de entrada único para TODOS los interruptores "de fecha del
  // ciclo" (periodStart/periodEnd/enterPeriod/fertile/ovulation): al
  // activarse, abre ReminderTimeSheet precargado con [fallbackDefault] (ya
  // calculado por CyclePredictor) y, si la usuaria confirma (aunque sea
  // sin tocar nada), persiste + reprograma la notificación real. Si el
  // usuario cierra el sheet sin guardar (back/tap fuera), el switch vuelve
  // a apagarse: no tiene sentido dejar un interruptor "activado" sin una
  // hora asociada.
  Future<void> _openDateTimeSheetFor({
    required String title,
    required DateTime? fallbackDefault,
    required Color primary,
    required IconData icon,
    required Color iconColor,
    int? daysBefore,
    ValueChanged<int>? onDaysBeforeChanged,
    required ValueChanged<DateTime> onConfirm,
    required VoidCallback onCancelled,
  }) async {
    if (fallbackDefault == null) {
      // Sin datos suficientes para calcular una fecha (usuaria nueva sin
      // ciclos registrados todavía) — no tiene sentido abrir un sheet con
      // una fecha inventada, así que se revierte el switch. Antes esto
      // pasaba en silencio: el interruptor se encendía y volvía a
      // apagarse sin ninguna explicación, dando la impresión (reportada
      // por la usuaria) de que el interruptor "no funcionaba". Ahora se
      // avisa con un SnackBar explicando por qué, para que quede claro
      // que hace falta registrar al menos un periodo primero.
      onCancelled();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).reminderNeedsPeriodDataFirst),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    var confirmed = false;
    await ReminderTimeSheet.showDateTime(
      context: context,
      title: title,
      icon: icon,
      iconColor: iconColor,
      initialDate: fallbackDefault,
      initialTime: TimeOfDay(hour: fallbackDefault.hour, minute: fallbackDefault.minute),
      daysBefore: daysBefore,
      onDaysBeforeChanged: onDaysBeforeChanged,
      primary: primary,
      onConfirm: (dt) {
        confirmed = true;
        onConfirm(dt);
      },
    );
    if (!confirmed) onCancelled();
  }

  Future<void> _onPeriodStartToggle(bool value, Color primary) async {
    if (!value) {
      setState(() => _settings = _settings.copyWith(periodStartEnabled: false));
      await _reminderService.saveSettings(_settings);
      _syncPeriodReminder();
      return;
    }
    setState(() => _settings = _settings.copyWith(periodStartEnabled: true));
    await _reminderService.requestPermissions();
    await _openDateTimeSheetFor(
      title: AppStrings.of(context).reminderPeriodStart,
      fallbackDefault: _settings.periodStartAt ?? _periodStartDefault,
      primary: primary,
      icon: Icons.water_drop,
      iconColor: const Color(0xFFFF3B30),
      onConfirm: (dt) async {
        setState(() => _settings = _settings.copyWith(periodStartAt: dt));
        await _reminderService.saveSettings(_settings);
        _syncPeriodReminder();
      },
      onCancelled: () => setState(() => _settings = _settings.copyWith(periodStartEnabled: false)),
    );
  }

  Future<void> _onPeriodEndToggle(bool value, Color primary) async {
    if (!value) {
      setState(() => _settings = _settings.copyWith(periodEndEnabled: false));
      await _reminderService.saveSettings(_settings);
      _syncPeriodReminder();
      return;
    }
    setState(() => _settings = _settings.copyWith(periodEndEnabled: true));
    await _reminderService.requestPermissions();
    await _openDateTimeSheetFor(
      title: AppStrings.of(context).reminderPeriodEnd,
      fallbackDefault: _settings.periodEndAt ?? _periodEndDefault,
      primary: primary,
      icon: Icons.water_drop_outlined,
      iconColor: _iosLabelMuted,
      onConfirm: (dt) async {
        setState(() => _settings = _settings.copyWith(periodEndAt: dt));
        await _reminderService.saveSettings(_settings);
        _syncPeriodReminder();
      },
      onCancelled: () => setState(() => _settings = _settings.copyWith(periodEndEnabled: false)),
    );
  }

  Future<void> _onEnterPeriodToggle(bool value, Color primary) async {
    if (!value) {
      setState(() => _settings = _settings.copyWith(enterPeriodEnabled: false));
      await _reminderService.saveSettings(_settings);
      _syncPeriodReminder();
      return;
    }
    setState(() => _settings = _settings.copyWith(enterPeriodEnabled: true));
    await _reminderService.requestPermissions();
    await _openDateTimeSheetFor(
      title: AppStrings.of(context).reminderEnterPeriod,
      // Mismo valor por defecto que Inicio del período (#1), pero se
      // guarda en un campo independiente (enterPeriodAt) para que la
      // usuaria pueda editarlos por separado si quiere avisos en momentos
      // distintos.
      fallbackDefault: _settings.enterPeriodAt ?? _periodStartDefault,
      primary: primary,
      icon: Icons.edit_calendar,
      iconColor: const Color(0xFF5AC8FA),
      onConfirm: (dt) async {
        setState(() => _settings = _settings.copyWith(enterPeriodAt: dt));
        await _reminderService.saveSettings(_settings);
        _syncPeriodReminder();
      },
      onCancelled: () => setState(() => _settings = _settings.copyWith(enterPeriodEnabled: false)),
    );
  }

  // NOTA sobre por qué estos dos NO usan widget.onFertileToggle/
  // onOvulationToggle para persistir: esos callbacks viven en el padre
  // (MainTabScreen/SettingsScreen) y hacen su PROPIO
  // `_reminderSettings.copyWith(...)` + `saveSettings` a partir de SU
  // COPIA de ReminderSettings — que todavía no conoce `fertileAt`/
  // `ovulationAt` en el momento en que se dispara el callback (race:
  // el callback del padre podría guardar una versión vieja y pisar lo que
  // acabamos de guardar aquí). Para evitar esa carrera, estos dos
  // interruptores guardan y reprograman directamente con
  // `_reminderService` (mismo patrón que periodStart/periodEnd/
  // enterPeriod arriba) y solo usan el callback del padre para el caso
  // "apagar", donde no hay ningún valor de fecha/hora que puedan pisar.
  Future<void> _onFertileToggleWrapped(bool value, Color primary) async {
    if (!value) {
      setState(() => _settings = _settings.copyWith(fertileEnabled: false));
      await _reminderService.saveSettings(_settings);
      _syncPeriodReminder();
      widget.onFertileToggle(false);
      return;
    }
    setState(() => _settings = _settings.copyWith(fertileEnabled: true));
    await _reminderService.requestPermissions();
    await _openDateTimeSheetFor(
      title: AppStrings.of(context).reminderFertileApproaching,
      fallbackDefault: _settings.fertileAt ?? _fertileDefault,
      primary: primary,
      icon: Icons.local_florist,
      iconColor: const Color(0xFFAF52DE),
      daysBefore: _settings.daysBefore,
      onDaysBeforeChanged: (days) => setState(() => _settings = _settings.copyWith(daysBefore: days)),
      onConfirm: (dt) async {
        setState(() => _settings = _settings.copyWith(fertileAt: dt));
        await _reminderService.saveSettings(_settings);
        _syncPeriodReminder();
      },
      onCancelled: () => setState(() => _settings = _settings.copyWith(fertileEnabled: false)),
    );
  }

  Future<void> _onOvulationToggleWrapped(bool value, Color primary) async {
    if (!value) {
      setState(() => _settings = _settings.copyWith(ovulationEnabled: false));
      await _reminderService.saveSettings(_settings);
      _syncPeriodReminder();
      widget.onOvulationToggle(false);
      return;
    }
    setState(() => _settings = _settings.copyWith(ovulationEnabled: true));
    await _reminderService.requestPermissions();
    await _openDateTimeSheetFor(
      title: AppStrings.of(context).reminderOvulationDay,
      fallbackDefault: _settings.ovulationAt ?? _ovulationDefault,
      primary: primary,
      icon: Icons.egg_alt,
      iconColor: const Color(0xFF5856D6),
      onConfirm: (dt) async {
        setState(() => _settings = _settings.copyWith(ovulationAt: dt));
        await _reminderService.saveSettings(_settings);
        _syncPeriodReminder();
      },
      onCancelled: () => setState(() => _settings = _settings.copyWith(ovulationEnabled: false)),
    );
  }

  /// Igual cálculo que MainTabScreen._syncPeriodReminder / HealthMenuScreen,
  /// pero llamado desde aquí para los 3 interruptores nuevos que antes no
  /// reprogramaban nada. widget.onPeriodToggle/onDaysChanged siguen siendo
  /// el canal para el aviso de Periodo "clásico" (antelación configurable);
  /// este método adicional asegura que los interruptores nuevos también
  /// disparen un reschedule real sin depender de que el padre (MainTabScreen)
  /// vuelva a llamarlo por su cuenta.
  void _syncPeriodReminder() {
    final nextPeriod = _predictor.predictNextPeriod();
    final ovulation = _predictor.predictOvulation(nextPeriod);
    _reminderService.reschedule(_settings, nextPeriod, ovulationDate: ovulation);
  }

  Future<void> _toggleBreastSelfExamReminder(bool value, Color primary) async {
    if (!value) {
      setState(() => _breastSelfExamReminder = false);
      await _settingsService.saveBreastSelfExamReminderEnabled(false);
      await _dailyNotifications.cancelBreastSelfExamReminder();
      return;
    }
    setState(() => _breastSelfExamReminder = true);
    await _dailyNotifications.requestPermissions();
    await _openDateTimeSheetFor(
      title: AppStrings.of(context).meBreastSelfExam,
      fallbackDefault: _breastSelfExamAt ?? _breastSelfExamDefault,
      primary: primary,
      icon: Icons.favorite,
      iconColor: const Color(0xFFFF2D55),
      onConfirm: (dt) async {
        setState(() => _breastSelfExamAt = dt);
        await _settingsService.saveBreastSelfExamReminderEnabled(true);
        await _settingsService.saveBreastSelfExamReminderAt(dt);
        await _dailyNotifications.scheduleBreastSelfExamReminder(dt);
      },
      onCancelled: () => setState(() => _breastSelfExamReminder = false),
    );
  }

  /// "Recuerda beber agua": a diferencia del resto, no abre el sheet de
  /// fecha+hora (no hay una fecha del ciclo con sentido para un hábito
  /// diario) — abre la variante "solo hora" y reutiliza
  /// DailyTimeReminderSettings, igual patrón que Píldora/Registro Diario.
  Future<void> _toggleDrinkWaterReminder(bool value, Color primary) async {
    if (!value) {
      final updated = _drinkWaterReminder.copyWith(enabled: false);
      setState(() => _drinkWaterReminder = updated);
      await _settingsService.saveDrinkWaterReminderSettings(updated);
      await _dailyNotifications.rescheduleDrinkWaterReminder(updated);
      return;
    }
    await _dailyNotifications.requestPermissions();
    final parts = _drinkWaterReminder.time.split(':');
    await ReminderTimeSheet.showTimeOnly(
      context: context,
      title: AppStrings.of(context).reminderDrinkWaterReminder,
      icon: Icons.local_drink,
      iconColor: const Color(0xFF007AFF),
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      primary: primary,
      onConfirm: (time) async {
        final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        final updated = _drinkWaterReminder.copyWith(enabled: true, time: formatted);
        setState(() => _drinkWaterReminder = updated);
        await _settingsService.saveDrinkWaterReminderSettings(updated);
        await _dailyNotifications.rescheduleDrinkWaterReminder(updated);
      },
    );
    // Si se cerró el sheet sin confirmar, _drinkWaterReminder.enabled
    // sigue en false (no se llegó a tocar "Guardar"), así que no hace
    // falta revertir nada aparte de refrescar la UI.
    if (!mounted) return;
    setState(() {});
  }

  /// "Recordatorio de fase del ciclo": informativo/recurrente, no ligado a
  /// una fecha puntual (se dispara al cambiar de fase, ver
  /// DailyNotificationService.rescheduleCyclePhaseReminder) — el sheet solo
  /// pide la hora del día en la que revisar/notificar el cambio, con el
  /// mismo patrón visual "solo hora" que Agua, para mantener consistencia
  /// en vez de un sheet sin ningún campo editable.
  Future<void> _toggleCyclePhaseReminder(bool value, Color primary) async {
    if (!value) {
      setState(() => _cyclePhaseReminder = false);
      await _settingsService.saveCyclePhaseReminderEnabled(false);
      await _dailyNotifications.rescheduleCyclePhaseReminder(false, _cyclePhaseReminderTime);
      return;
    }
    await _dailyNotifications.requestPermissions();
    final parts = _cyclePhaseReminderTime.split(':');
    await ReminderTimeSheet.showTimeOnly(
      context: context,
      title: AppStrings.of(context).reminderCyclePhaseReminder,
      hint: AppStrings.of(context).reminderCyclePhaseAutoHint,
      icon: Icons.auto_awesome,
      iconColor: const Color(0xFFD4537E),
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      primary: primary,
      onConfirm: (time) async {
        final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        setState(() {
          _cyclePhaseReminder = true;
          _cyclePhaseReminderTime = formatted;
        });
        await _settingsService.saveCyclePhaseReminderEnabled(true);
        await _settingsService.saveCyclePhaseReminderTime(formatted);
        await _dailyNotifications.rescheduleCyclePhaseReminder(true, formatted);
      },
    );
    if (!mounted) return;
    setState(() {});
  }

  /// Mismas opciones predefinidas que health_menu_screen.dart
  /// (_appointmentTypeOptions) y day_editor.dart, replicadas aquí para que
  /// el diálogo de "Cita con el médico" sea idéntico al de Configuración —
  /// misma lista, mismo orden, misma opción "Otro" con texto libre al final.
  List<String Function(AppStrings)> get _appointmentTypeOptions => [
        (s) => s.appointmentTypeGyno,
        (s) => s.appointmentTypeCheckup,
        (s) => s.appointmentTypeBloodTest,
        (s) => s.appointmentTypeUltrasound,
        (s) => s.appointmentTypeMidwife,
        (s) => s.appointmentTypeOther,
      ];

  // Rediseño aprobado en Claude Visualize (2026-08-16): antes era un
  // AlertDialog genérico de Material (dropdown plano con borde, botón
  // OutlinedButton cuadrado, acciones TextButton). Ahora es un bottom sheet
  // con el mismo lenguaje visual que ReminderTimeSheet: icono en tarjeta de
  // color, secciones "TIPO DE CITA"/"FECHA Y HORA" con filas grises +
  // flecha, botón "Guardar cita" (gris mientras el formulario está
  // incompleto, rosa cuando ya se puede guardar) y "Cancelar" debajo. Toda
  // la lógica de selección/validación/guardado se mantiene igual — solo
  // cambia cómo se presenta.
  Future<void> _addAppointment() async {
    final s = AppStrings.of(context);
    final otherController = TextEditingController();
    DateTime? pickedDate;
    TimeOfDay? pickedTime;
    int? selectedIndex;
    final options = _appointmentTypeOptions;
    final otherIndex = options.length - 1;
    const iconColor = Color(0xFFFF2D55);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final isOtherSelected = selectedIndex == otherIndex;
            final labelReady = selectedIndex != null &&
                (!isOtherSelected || otherController.text.trim().isNotEmpty);
            final canSave = labelReady && pickedDate != null && pickedTime != null;
            final typeLabel = selectedIndex == null
                ? s.appointmentTypeSectionLabel
                : (isOtherSelected && otherController.text.trim().isNotEmpty
                    ? otherController.text.trim()
                    : options[selectedIndex!](s));
            final dateTimeLabel = pickedDate == null || pickedTime == null
                ? s.settingsAppointmentPickDate
                : '${pickedDate!.day}/${pickedDate!.month}/${pickedDate!.year} · ${pickedTime!.hour.toString().padLeft(2, '0')}:${pickedTime!.minute.toString().padLeft(2, '0')}';

            Future<void> pickType() async {
              await showModalBottomSheet<void>(
                context: sheetContext,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                builder: (typeSheetContext) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(color: const Color(0xFFD1D1D6), borderRadius: BorderRadius.circular(3)),
                        ),
                        Text(s.appointmentTypeSectionLabel,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.black)),
                        const SizedBox(height: 14),
                        ...List.generate(options.length, (i) {
                          final selected = i == selectedIndex;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () {
                                setSheetState(() => selectedIndex = i);
                                Navigator.of(typeSheetContext).pop();
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                decoration: BoxDecoration(
                                  color: selected ? iconColor.withOpacity(0.1) : _iosBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      options[i](s),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: selected ? iconColor : Colors.black,
                                        fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (selected) Icon(Icons.check, size: 19, color: iconColor),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.of(typeSheetContext).pop(),
                            style: TextButton.styleFrom(foregroundColor: _iosLabelMuted, padding: const EdgeInsets.symmetric(vertical: 10)),
                            child: Text(s.cancel, style: const TextStyle(fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
              setSheetState(() {});
            }

            Future<void> pickDateTime() async {
              final now = DateTime.now();
              final date = await ReminderDatePickerSheet.show(
                context: sheetContext,
                initialDate: pickedDate ?? now,
                firstDate: now,
                lastDate: DateTime(now.year + 3),
                primary: iconColor,
              );
              if (date == null) return;
              if (!sheetContext.mounted) return;
              final time = await ReminderTimePickerSheet.show(
                context: sheetContext,
                initialTime: pickedTime ?? TimeOfDay.now(),
                primary: iconColor,
              );
              if (time == null) return;
              setSheetState(() {
                pickedDate = date;
                pickedTime = time;
              });
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(24, 10, 24, 16 + MediaQuery.of(sheetContext).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: const Color(0xFFD1D1D6), borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.medical_services, size: 22, color: iconColor),
                      ),
                      const SizedBox(width: 14),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          s.settingsAppointmentDialogTitle,
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    s.appointmentTypeSectionLabel.toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _iosLabelMuted, letterSpacing: 0.4),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: pickType,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: _iosBg, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: selectedIndex == null ? _iosLabelMuted : Colors.black,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 17, color: Color(0xFFC7C7CC)),
                        ],
                      ),
                    ),
                  ),
                  if (isOtherSelected) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: otherController,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: s.appointmentTypeOtherHint,
                        filled: true,
                        fillColor: _iosBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (_) => setSheetState(() {}),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    s.reminderTimeSheetDateLabel.toUpperCase() + ' / ' + s.reminderTimeSheetTimeLabel.toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _iosLabelMuted, letterSpacing: 0.4),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: pickDateTime,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: _iosBg, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 19, color: iconColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              dateTimeLabel,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: pickedDate == null ? _iosLabelMuted : Colors.black,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 17, color: Color(0xFFC7C7CC)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: canSave ? () => Navigator.of(sheetContext).pop(true) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: iconColor,
                        disabledBackgroundColor: const Color(0xFFD3D3D6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(s.settingsAppointmentSave, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                      style: TextButton.styleFrom(foregroundColor: _iosLabelMuted, padding: const EdgeInsets.symmetric(vertical: 10)),
                      child: Text(s.cancel, style: const TextStyle(fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (saved != true || pickedDate == null || pickedTime == null) return;
    final isOtherSelected = selectedIndex == otherIndex;
    final label = isOtherSelected ? otherController.text.trim() : options[selectedIndex!](s);
    final picked = DateTime(
      pickedDate!.year,
      pickedDate!.month,
      pickedDate!.day,
      pickedTime!.hour,
      pickedTime!.minute,
    );
    final appointment = MedicalAppointment(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      label: label,
      dateTime: picked,
    );
    final updated = [..._appointments, appointment];
    setState(() => _appointments = updated);
    await _settingsService.saveMedicalAppointments(updated);
    await _dailyNotifications.requestPermissions();
    await _dailyNotifications.scheduleAppointment(appointment);
  }

  Future<void> _deleteAppointment(MedicalAppointment appointment) async {
    final updated = _appointments.where((a) => a.id != appointment.id).toList();
    setState(() => _appointments = updated);
    await _settingsService.saveMedicalAppointments(updated);
    await _dailyNotifications.cancelAppointment(appointment.id);
  }

  // ==================== Estética iOS Settings ====================
  // Rediseño aprobado en Claude Visualize (2026-08-16): fondo gris claro
  // #F2F2F7 (igual a Ajustes de iPhone), tarjetas blancas de esquinas 14px
  // que agrupan filas relacionadas, icono cuadrado de color propio por
  // fila (en vez del icono genérico + texto plano de antes), switch verde
  // #34C759 tipo iOS (en vez del Switch rosa de Material), y el valor
  // programado como subtítulo verde bajo el título de la fila (en vez de
  // una línea aparte con `_scheduledAtHint`). Toda la lógica de toggles,
  // sheets y persistencia de más arriba queda intacta — esto es
  // exclusivamente una reescritura visual de `build` y los widgets de
  // apoyo.
  static const Color _iosBg = Color(0xFFF2F2F7);
  static const Color _iosGreen = Color(0xFF34C759);
  static const Color _iosDivider = Color(0xFFE5E5EA);
  static const Color _iosLabelMuted = Color(0xFF8E8E93);

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = themeById(widget.themeId);
    final primary = Color(theme.primary);

    return Scaffold(
      backgroundColor: _iosBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 44),
                  Text(
                    s.reminderScreenTitleLine1,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 15, color: _iosLabelMuted),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: const CircleBorder(),
                      minimumSize: const Size(28, 28),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                      child: Text(
                        '${s.reminderScreenTitleLine1}\n${s.reminderScreenTitleLine2}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.black, height: 1.15),
                      ),
                    ),
                    // Durante el embarazo no hay periodos que seguir, así
                    // que toda esta sección (inicio/fin/introducir periodo +
                    // ventana fértil/ovulación, ya ocultas fuera de
                    // "Intentar concebir") se oculta por completo.
                    if (widget.userGoal != 'pregnancy') ...[
                    _sectionLabel(s.reminderPeriodAndFertility),
                    _iosCard([
                      _iosRow(
                        icon: Icons.water_drop,
                        iconBg: const Color(0xFFFF3B30),
                        label: s.reminderPeriodStart,
                        subtitle: _settings.periodStartEnabled && _settings.periodStartAt != null
                            ? _scheduledAtLabel(_settings.periodStartAt!)
                            : null,
                        value: _settings.periodStartEnabled,
                        onChanged: (v) => _onPeriodStartToggle(v, primary),
                      ),
                      _iosDividerLine(),
                      _iosRow(
                        icon: Icons.water_drop_outlined,
                        iconBg: _iosLabelMuted,
                        label: s.reminderPeriodEnd,
                        subtitle: _settings.periodEndEnabled && _settings.periodEndAt != null
                            ? _scheduledAtLabel(_settings.periodEndAt!)
                            : null,
                        value: _settings.periodEndEnabled,
                        onChanged: (v) => _onPeriodEndToggle(v, primary),
                      ),
                      _iosDividerLine(),
                      _iosRow(
                        icon: Icons.edit_calendar,
                        iconBg: const Color(0xFF5AC8FA),
                        label: s.reminderEnterPeriod,
                        subtitle: _settings.enterPeriodEnabled && _settings.enterPeriodAt != null
                            ? _scheduledAtLabel(_settings.enterPeriodAt!)
                            : null,
                        value: _settings.enterPeriodEnabled,
                        onChanged: (v) => _onEnterPeriodToggle(v, primary),
                      ),
                      _iosDividerLine(),
                      _iosRow(
                        icon: Icons.calendar_month,
                        iconBg: primary,
                        label: s.reminderRowPeriod,
                        subtitle: null,
                        value: _settings.enabled,
                        onChanged: (v) {
                          // Mismo aviso que los demás interruptores de esta
                          // pantalla (ver _openDateTimeSheetFor): sin ningún
                          // periodo registrado todavía no hay nada que
                          // predecir, así que activar este recordatorio no
                          // serviría de nada. Antes se dejaba encender en
                          // silencio (widget.hasPrediction se declaraba pero
                          // nunca se leía), dando la misma sensación de
                          // "el interruptor no funciona" reportada por la
                          // usuaria para los otros switches.
                          if (v && !widget.hasPrediction) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppStrings.of(context).reminderNeedsPeriodDataFirst),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            return;
                          }
                          setState(() => _settings = _settings.copyWith(enabled: v));
                          widget.onPeriodToggle(v);
                        },
                      ),
                      if (_settings.enabled) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 42, bottom: 4),
                          child: _daysSelector(s, primary),
                        ),
                      ],
                      // Los recordatorios de ventana fértil/ovulación solo
                      // tienen sentido con "Intentar concebir" — con
                      // "Seguir mi periodo" o ya en embarazo se ocultan en
                      // vez de mostrarse siempre (pedido de la usuaria de
                      // activar cada función solo donde se usa).
                      if (widget.userGoal == 'conceive') ...[
                        _iosDividerLine(),
                        _iosRow(
                          icon: Icons.local_florist,
                          iconBg: const Color(0xFFAF52DE),
                          label: s.reminderFertileApproaching,
                          subtitle: _settings.fertileEnabled && _settings.fertileAt != null
                              ? _scheduledAtLabel(_settings.fertileAt!)
                              : null,
                          value: _settings.fertileEnabled,
                          onChanged: (v) => _onFertileToggleWrapped(v, primary),
                        ),
                        _iosDividerLine(),
                        _iosRow(
                          icon: Icons.egg_alt,
                          iconBg: const Color(0xFF5856D6),
                          label: s.reminderOvulationDay,
                          subtitle: _settings.ovulationEnabled && _settings.ovulationAt != null
                              ? _scheduledAtLabel(_settings.ovulationAt!)
                              : null,
                          value: _settings.ovulationEnabled,
                          onChanged: (v) => _onOvulationToggleWrapped(v, primary),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 20),
                    ],
                    if (_extrasLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      )
                    else ...[
                      // El recordatorio de píldora anticonceptiva solo tiene
                      // sentido con "Seguir mi periodo" — quien está
                      // intentando concebir o ya está embarazada no la toma.
                      if (widget.userGoal == 'period') ...[
                        _sectionLabel(s.reminderPill),
                        _iosCard([
                          _iosRow(
                            icon: Icons.medication,
                            iconBg: const Color(0xFFFF9500),
                            label: s.reminderTakePill,
                            subtitle: _pillReminder.enabled ? _timeLabel(_pillReminder.time) : null,
                            value: _pillReminder.enabled,
                            onChanged: _togglePillReminder,
                            onSubtitleTap: _pillReminder.enabled ? _pickPillReminderTime : null,
                          ),
                        ]),
                        const SizedBox(height: 20),
                      ],

                      _sectionLabel(s.reminderAppointment),
                      _iosCard([
                        InkWell(
                          onTap: _addAppointment,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                _iosIcon(Icons.medical_services, const Color(0xFFFF2D55)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(s.reminderDoctorAppointment,
                                      style: const TextStyle(fontSize: 16, color: Colors.black)),
                                ),
                                const Icon(Icons.chevron_right, color: _iosLabelMuted, size: 20),
                              ],
                            ),
                          ),
                        ),
                        if (_appointments.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ..._appointments.map((a) {
                            final d = a.dateTime;
                            final dateLabel =
                                '${d.day}/${d.month}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6, left: 42),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(a.label, style: const TextStyle(fontSize: 13, color: Colors.black)),
                                        Text(dateLabel, style: const TextStyle(fontSize: 12, color: _iosGreen)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteAppointment(a),
                                    icon: const Icon(Icons.close, size: 16, color: _iosLabelMuted),
                                    tooltip: s.settingsAppointmentDelete,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ]),
                      const SizedBox(height: 20),

                      _sectionLabel(s.reminderLifestyle),
                      _iosCard([
                        _iosRow(
                          icon: Icons.edit_note,
                          iconBg: primary,
                          label: s.reminderDailyLog,
                          subtitle: _dailyReminder.enabled ? _timeLabel(_dailyReminder.time) : null,
                          value: _dailyReminder.enabled,
                          onChanged: _toggleDailyReminder,
                          onSubtitleTap: _dailyReminder.enabled ? _pickDailyReminderTime : null,
                        ),
                        _iosDividerLine(),
                        _iosRow(
                          icon: Icons.favorite,
                          iconBg: const Color(0xFFFF2D55),
                          label: s.meBreastSelfExam,
                          subtitle: _breastSelfExamReminder && _breastSelfExamAt != null
                              ? _scheduledAtLabel(_breastSelfExamAt!)
                              : null,
                          value: _breastSelfExamReminder,
                          onChanged: (v) => _toggleBreastSelfExamReminder(v, primary),
                        ),
                        _iosDividerLine(),
                        _iosRow(
                          icon: Icons.local_drink,
                          iconBg: const Color(0xFF007AFF),
                          label: s.reminderDrinkWaterReminder,
                          subtitle: _drinkWaterReminder.enabled ? _timeLabel(_drinkWaterReminder.time) : null,
                          value: _drinkWaterReminder.enabled,
                          onChanged: (v) => _toggleDrinkWaterReminder(v, primary),
                          onSubtitleTap: _drinkWaterReminder.enabled ? () => _toggleDrinkWaterReminder(true, primary) : null,
                        ),
                      ]),
                      const SizedBox(height: 20),

                      _sectionLabel(s.reminderNotifications),
                      _iosCard([
                        _iosRow(
                          icon: Icons.auto_awesome,
                          iconBg: const Color(0xFFD4537E),
                          label: s.reminderCyclePhaseReminder,
                          subtitle: _cyclePhaseReminder
                              ? _timeLabel(_cyclePhaseReminderTime)
                              : s.reminderCyclePhaseTipsHint,
                          subtitleColor: _cyclePhaseReminder ? _iosGreen : _iosLabelMuted,
                          value: _cyclePhaseReminder,
                          onChanged: (v) => _toggleCyclePhaseReminder(v, primary),
                          onSubtitleTap: _cyclePhaseReminder ? () => _toggleCyclePhaseReminder(true, primary) : null,
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: _iosLabelMuted, letterSpacing: 0.3),
        ),
      );

  Widget _iosDividerLine() => const Padding(
        padding: EdgeInsets.only(left: 42),
        child: Divider(height: 0.5, thickness: 0.5, color: _iosDivider),
      );

  Widget _iosCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      // Antes era una tarjeta plana (solo color + radio); ahora sombra
      // suave, mismo lenguaje de tarjeta elevada del rediseño aplicado en
      // Inicio/Calendario.
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.16),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _iosIcon(IconData icon, Color bg) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }

  /// Fila estilo Ajustes de iPhone: icono cuadrado de color + título +
  /// (opcional) subtítulo en verde con la fecha/hora ya programada +
  /// switch verde nativo a la derecha. `onSubtitleTap` permite reabrir el
  /// selector de hora directamente tocando el subtítulo (además del propio
  /// switch), útil en las filas "solo hora" (Píldora/Registro/Agua/Fase).
  Widget _iosRow({
    required IconData icon,
    required Color iconBg,
    required String label,
    String? subtitle,
    Color? subtitleColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    VoidCallback? onSubtitleTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _iosIcon(icon, iconBg),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onSubtitleTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 16, color: Colors.black)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle, style: TextStyle(fontSize: 13, color: subtitleColor ?? _iosGreen)),
                    ),
                ],
              ),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              activeColor: Colors.white,
              activeTrackColor: _iosGreen,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFE9E9EB),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  String _scheduledAtLabel(DateTime at) =>
      '${at.day.toString().padLeft(2, '0')}/${at.month.toString().padLeft(2, '0')} · ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

  String _timeLabel(String time) => time;

  // Rediseño aprobado en Claude Visualize (2026-08-16): antes era un
  // DropdownButton nativo de Material (gris/blanco genérico, desentonaba
  // con el resto del rediseño iOS). Ahora es una fila que abre un bottom
  // sheet de opciones tipo iOS (misma familia visual que ReminderTimeSheet):
  // filas con fondo gris claro, la opción activa resaltada en rosa con
  // check, y "Cancelar" al final.
  Widget _daysSelector(AppStrings s, Color primary) {
    return InkWell(
      onTap: () => _openDaysBeforeSheet(s, primary),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: _iosBg, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Text(s.reminderBefore, style: const TextStyle(fontSize: 13, color: _iosLabelMuted)),
            const Spacer(),
            Text(
              s.reminderDayOption(_settings.daysBefore),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: _iosLabelMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _openDaysBeforeSheet(AppStrings s, Color primary) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: const Color(0xFFD1D1D6), borderRadius: BorderRadius.circular(3)),
              ),
              Text(s.reminderBefore, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.black)),
              const SizedBox(height: 14),
              ...kReminderDayOptions.map((d) {
                final selected = d == _settings.daysBefore;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() => _settings = _settings.copyWith(daysBefore: d));
                      widget.onDaysChanged(d);
                      Navigator.of(sheetContext).pop();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: selected ? primary.withOpacity(0.1) : _iosBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Text(
                            s.reminderDayOption(d),
                            style: TextStyle(
                              fontSize: 16,
                              color: selected ? primary : Colors.black,
                              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          if (selected) Icon(Icons.check, size: 19, color: primary),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: TextButton.styleFrom(foregroundColor: _iosLabelMuted, padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: Text(s.cancel, style: const TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


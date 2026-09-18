import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/day_entry.dart';
import '../services/cycle_predictor.dart';
import '../services/settings_service.dart';
import '../services/calendar_style_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/calendar_grid_elegant.dart';
import '../widgets/calendar_grid_ios.dart';
import 'period_editor_screen.dart';
import 'register_screen.dart';

/// Pestaña "Calendario" del nav inferior de 5 pestañas (ver
/// `main_tab_screen.dart`). Contenido: calendario mensual rediseñado
/// (selector de mes/año en píldoras + botón "Hoy", cápsulas de fase con
/// colores exactos del diseño v0 aprobado), leyenda de 3 categorías
/// (Periodo/Previsto/Fértil) y botones "Editar período"/"Notas".
///
/// Nota de corrección: esta pantalla estaba desconectada del rediseño real
/// — un agente anterior concluyó erróneamente que este archivo era código
/// huérfano y aplicó el rediseño en `home_screen.dart` (que no está
/// instanciado en ningún tab de `MainTabScreen`) en vez de aquí. El
/// contenido de este archivo replica ahora el mismo patrón ya usado en
/// `HomeScreen`/`CalendarGrid`, pero recibiendo los datos reales por props
/// desde `MainTabScreen` (igual que `RegisterScreen`/`ReminderScreen`/
/// `MeScreen`), sin `Scaffold` ni `StatusCard` propios porque el header rosa
/// y el nav inferior ya viven en `MainTabScreen`.
class CalendarScreen extends StatefulWidget {
  final Map<String, DayEntry> data;
  final ValueChanged<Map<String, DayEntry>> onDataChanged;

  /// Si está activo (interruptor "Ciclo irregular" de Configuración), se
  /// le pasa a CyclePredictor para forzar un rango de predicción más
  /// amplio en vez de una fecha exacta.
  final bool irregularCycleMode;

  // Duración de ciclo/periodo autoinformadas en el cuestionario de
  // "Intentar concebir" — respaldo para CyclePredictor mientras no hay
  // suficientes datos reales (ver conceive_intake_sheet.dart).
  final int? selfReportedCycleLen;
  final int? selfReportedPeriodLen;

  // Citas médicas (incluye recordatorios puntuales de anticonceptivo) —
  // se cargan y refrescan en MainTabScreen, igual que en HomeScreen.
  final List<MedicalAppointment> appointments;
  final VoidCallback onAppointmentsChanged;

  // Id del tema de color elegido en Configuración (kAppThemes) — se pasa a
  // RegisterScreen al abrir el editor de un día.
  final String themeId;

  /// "Mi objetivo" (Configuración/Yo): 'period' | 'conceive' | 'pregnancy'.
  /// Recibido de MainTabScreen (misma fuente que el resto de pestañas) en
  /// vez de cargarse aparte con SettingsService: así, si se cambia el
  /// objetivo desde Configuración y se vuelve a esta misma pestaña sin
  /// cambiar de tab entre medio, didUpdateWidget se entera del cambio —
  /// antes se quedaba con el valor cargado la primera vez que se montó
  /// esta pantalla (leyenda "Fértil" y botón "Editar período" desajustados
  /// del objetivo real hasta reiniciar la app).
  final String userGoal;

  const CalendarScreen({
    super.key,
    required this.data,
    required this.onDataChanged,
    this.irregularCycleMode = false,
    this.selfReportedCycleLen,
    this.selfReportedPeriodLen,
    this.appointments = const [],
    required this.onAppointmentsChanged,
    this.themeId = 'pink',
    this.userGoal = 'period',
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _viewMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime.now();

  // Categorías ocultas del calendario (ver panel "Leyenda" /
  // CalendarLegendCategory) — vacío significa "todo visible", que es el
  // valor por defecto hasta que se carguen las preferencias guardadas.
  // Vive en este State (no en widget.data) porque es una preferencia visual
  // de la usuaria, no un dato del ciclo en sí.
  final SettingsService _settings = SettingsService();
  Set<String> _hiddenLegendCategories = <String>{};

  // Controla si se muestra la fila de resumen del día (_buildDaySummary),
  // debajo de "Editar período"/"Notas". Arranca oculta: la usuaria pidió
  // que el botón "i" sea lo que la "active" en vez de mostrarla siempre
  // ("que sera un boton para activa la informacion que este abajo").
  bool _showDaySummary = false;

  // "Mi objetivo" (Configuración/Yo): solo se usa aquí para resaltar más
  // la ventana fértil/ovulación en el calendario cuando es "Intentar
  // concebir" — ver CalendarGrid.emphasizeFertility. Arranca en
  // widget.userGoal (ya viene fresco de MainTabScreen) y se mantiene
  // sincronizado vía didUpdateWidget más abajo.
  late String _userGoal = widget.userGoal;

  // Estado del gesto de deslizar arriba/abajo sobre la cuadrícula del mes
  // (ver Listener en build()): posición Y y momento en que el dedo tocó la
  // pantalla, usados para calcular la velocidad al soltar.
  double? _monthSwipeStartY;
  Duration? _monthSwipeStartTime;

  @override
  void initState() {
    super.initState();
    _loadLegendVisibility();
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el objetivo cambió desde Configuración mientras esta pantalla ya
    // estaba montada (se vuelve a la misma pestaña sin pasar por otra
    // entre medio, así que Flutter reutiliza este State en vez de crear
    // uno nuevo), reflejamos el cambio en vez de quedarnos con el valor
    // con el que se montó por primera vez.
    if (oldWidget.userGoal != widget.userGoal) {
      setState(() => _userGoal = widget.userGoal);
    }
  }

  Future<void> _loadLegendVisibility() async {
    final hidden = await _settings.loadCalendarLegendHidden();
    if (!mounted) return;
    setState(() => _hiddenLegendCategories = hidden);
  }

  void _toggleLegendCategory(String categoryId) {
    setState(() {
      final updated = Set<String>.from(_hiddenLegendCategories);
      if (updated.contains(categoryId)) {
        updated.remove(categoryId);
      } else {
        updated.add(categoryId);
      }
      _hiddenLegendCategories = updated;
    });
    _settings.saveCalendarLegendHidden(_hiddenLegendCategories);
  }

  void _changeMonth(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta, 1);
    });
  }

  // Salta directo a un mes/año elegido desde las píldoras del selector, o
  // al mes de hoy con el botón "Hoy" — a diferencia de _changeMonth (que
  // solo avanza/retrocede de a un mes), este permite saltos arbitrarios.
  void _jumpToMonth(DateTime target) {
    setState(() {
      _viewMonth = DateTime(target.year, target.month, 1);
    });
  }

  // Determina si `date` es el último día de una racha consecutiva de
  // flujo registrado (el "borde final" del período): tiene flujo hoy pero
  // el día siguiente no lo tiene. Se usa para decidir si el menú
  // contextual ofrece "Prolongar período" en vez de "Retirar
  // período"/"Fin del período".
  bool _isPeriodEndDay(DateTime date) {
    final entry = widget.data[dateKey(date)];
    if (entry == null || !entry.isPeriodDay) return false;
    final nextEntry = widget.data[dateKey(date.add(const Duration(days: 1)))];
    return nextEntry == null || !nextEntry.isPeriodDay;
  }

  // Busca hacia atrás, hasta `maxGap` días antes de `date`, el último día
  // con flujo registrado — sin cruzar ningún otro día que también tenga
  // flujo (eso ya sería "dentro" del período, no "después"). Se usa para
  // saber si un día vacío está a 1-2 días de una racha de período que
  // terminó, y así ofrecer "Prolongar período" también ahí, no solo en el
  // borde exacto.
  DateTime? _findRecentPeriodEnd(DateTime date, {int maxGap = 2}) {
    // Si hay período por delante de `date`, el hueco está DENTRO de una
    // racha (p. ej. se retiró un día intermedio), no después de que la
    // racha terminó. En ese caso no corresponde ofrecer "Prolongar".
    final nextEntry = widget.data[dateKey(date.add(const Duration(days: 1)))];
    if (nextEntry != null && nextEntry.isPeriodDay) return null;

    for (var gap = 1; gap <= maxGap; gap++) {
      final candidate = date.subtract(Duration(days: gap));
      final entry = widget.data[dateKey(candidate)];
      if (entry != null && entry.isPeriodDay) return candidate;
    }
    return null;
  }

  // "Prolongar período": si `date` ya es un día de período (el borde
  // final tocado directamente), marca el día siguiente. Si `date` es un
  // día vacío a 1-2 días de una racha reciente (ver
  // `_findRecentPeriodEnd`), rellena todos los días entre el fin de esa
  // racha y `date` (incluido), para que quede una racha continua sin
  // huecos — con el mismo flujo del último día registrado, para mantener
  // continuidad.
  void _extendPeriod(DateTime date) {
    final key = dateKey(date);
    final entry = widget.data[key];
    final updated = Map<String, DayEntry>.from(widget.data);

    if (entry != null && entry.isPeriodDay) {
      final nextDate = date.add(const Duration(days: 1));
      final nextKey = dateKey(nextDate);
      final existingNext = widget.data[nextKey] ?? const DayEntry();
      updated[nextKey] = existingNext.copyWith(flow: entry.flow);
      widget.onDataChanged(updated);
      return;
    }

    final periodEnd = _findRecentPeriodEnd(date);
    if (periodEnd == null) return;
    final lastFlow = widget.data[dateKey(periodEnd)]!.flow;
    var cursor = periodEnd.add(const Duration(days: 1));
    while (!cursor.isAfter(date)) {
      final cursorKey = dateKey(cursor);
      final existingCursor = widget.data[cursorKey] ?? const DayEntry();
      updated[cursorKey] = existingCursor.copyWith(flow: lastFlow);
      cursor = cursor.add(const Duration(days: 1));
    }
    widget.onDataChanged(updated);
  }

  // "Retirar período": quita el flujo solo del día tocado (día intermedio
  // del período), sin tocar los días antes ni después.
  void _removePeriodDay(DateTime date) {
    final key = dateKey(date);
    final existing = widget.data[key];
    if (existing == null) return;
    final updated = Map<String, DayEntry>.from(widget.data);
    final cleared = existing.copyWith(flow: 'none');
    if (cleared.isEmpty) {
      updated.remove(key);
    } else {
      updated[key] = cleared;
    }
    widget.onDataChanged(updated);
  }

  // "Fin del período": corta la racha en el día tocado — ese día y todos
  // los días posteriores YA registrados como período (en la misma racha
  // consecutiva) dejan de contar como período. Los días anteriores no se
  // modifican.
  void _endPeriodHere(DateTime date) {
    final updated = Map<String, DayEntry>.from(widget.data);
    var cursor = date;
    while (true) {
      final key = dateKey(cursor);
      final existing = updated[key];
      if (existing == null || !existing.isPeriodDay) break;
      final cleared = existing.copyWith(flow: 'none');
      if (cleared.isEmpty) {
        updated.remove(key);
      } else {
        updated[key] = cleared;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    widget.onDataChanged(updated);
  }

  // Panel "Leyenda": ya no es solo informativo (colores del calendario),
  // ahora cada categoría tiene un switch que decide si se pinta o no en el
  // calendario. Pensado para privacidad — antes de mostrarle el calendario
  // a alguien (pareja, médico), la usuaria puede apagar de antemano las
  // categorías que prefiere no compartir (ej. vida sexual), sin borrar el
  // dato: solo deja de pintarse mientras el switch esté apagado.
  void _showLegendSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final s = AppStrings.of(context);
          // "Fértil"/"Ovulación" solo se ocultan del todo en embarazo (no
          // aporta nada ahí); tanto en "Seguir mi periodo" como en
          // "Intentar concebir" se calculan y se ofrecen como categoría —
          // pedido explícito de la usuaria para ver también estos días
          // fuera del modo "concebir".
          // "Previsto" (próximo periodo estimado) tampoco tiene sentido en
          // embarazo: la predicción se calcula igual a partir del último
          // ciclo registrado ANTES de quedar embarazada, así que sin este
          // forzado podía seguir marcando "previsto de periodo" semanas o
          // meses después de que ya no aplica — bug de cálculo encontrado
          // al revisar los 3 objetivos.
          const pregnancyForcedOffCategories = {CalendarLegendCategory.fertile, CalendarLegendCategory.predicted};
          final totalCategories = _userGoal == 'pregnancy'
              ? CalendarLegendCategory.all.length - pregnancyForcedOffCategories.length
              : CalendarLegendCategory.all.length;
          final hiddenCount = _userGoal == 'pregnancy'
              ? _hiddenLegendCategories.where((id) => !pregnancyForcedOffCategories.contains(id)).length
              : _hiddenLegendCategories.length;
          final activeCount = totalCategories - hiddenCount;

          void toggle(String id) {
            _toggleLegendCategory(id);
            setSheetState(() {});
          }

          final cycleItems = [
            _LegendCategoryItem(
              id: CalendarLegendCategory.period,
              icon: Icons.water_drop_outlined,
              label: s.calendarLegendCatPeriod,
              accent: CalendarPhaseColors.periodFill,
            ),
            // "Previsto" tampoco se ofrece como opción manual en embarazo
            // (ver nota junto a pregnancyForcedOffCategories más arriba):
            // ya está forzado a apagado ahí, así que un interruptor sería
            // confuso, igual criterio que "Fértil".
            if (_userGoal != 'pregnancy')
              _LegendCategoryItem(
                id: CalendarLegendCategory.predicted,
                icon: Icons.event_outlined,
                label: s.calendarLegendCatPredicted,
                accent: CalendarPhaseColors.predictedBorder,
              ),
            // Se ofrece como opción manual tanto en "Seguir mi periodo"
            // como en "Intentar concebir" — solo se oculta del todo en
            // embarazo, donde esa categoría ya está forzada a apagado (ver
            // effectiveHiddenLegendCategories) y un interruptor para algo
            // forzado sería confuso.
            if (_userGoal != 'pregnancy')
              _LegendCategoryItem(
                id: CalendarLegendCategory.fertile,
                icon: Icons.local_florist_outlined,
                label: s.calendarLegendCatFertile,
                accent: CalendarPhaseColors.fertileBorder,
              ),
          ];
          final sexItems = [
            _LegendCategoryItem(
              id: CalendarLegendCategory.sexUnprotected,
              icon: Icons.favorite_outline,
              label: s.calendarLegendCatSexUnprotected,
              accent: const Color(0xFFE24B4A),
            ),
            _LegendCategoryItem(
              id: CalendarLegendCategory.sexProtected,
              icon: Icons.favorite,
              halfHeart: true,
              label: s.calendarLegendCatSexProtected,
              accent: const Color(0xFF1D9E75),
            ),
            _LegendCategoryItem(
              id: CalendarLegendCategory.masturbation,
              icon: Icons.back_hand_outlined,
              label: s.calendarLegendCatMasturbation,
              accent: const Color(0xFFD4537E),
            ),
          ];
          final methodItems = [
            _LegendCategoryItem(
              id: CalendarLegendCategory.pill,
              icon: Icons.medication_outlined,
              label: s.calendarLegendCatPill,
              accent: const Color(0xFFBA7517),
            ),
            _LegendCategoryItem(
              id: CalendarLegendCategory.diu,
              icon: Icons.shield_moon_outlined,
              label: s.calendarLegendCatDiu,
              accent: const Color(0xFF7F77DD),
            ),
          ];
          final otherItems = [
            _LegendCategoryItem(
              id: CalendarLegendCategory.moodSymptoms,
              icon: Icons.mood_outlined,
              label: s.calendarLegendCatMoodSymptoms,
              accent: const Color(0xFF7F77DD),
            ),
            _LegendCategoryItem(
              id: CalendarLegendCategory.note,
              icon: Icons.sticky_note_2_outlined,
              label: s.calendarLegendCatNote,
              accent: AppColors.textMuted,
            ),
          ];

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.calendarLegendTitle,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      Text(
                        s.calendarLegendActiveCount(activeCount, CalendarLegendCategory.all.length),
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.calendarLegendPrivacySubtitle,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LegendGroup(
                            title: s.calendarLegendGroupCycle,
                            items: cycleItems,
                            hidden: _hiddenLegendCategories,
                            onToggle: toggle,
                          ),
                          const SizedBox(height: 14),
                          _LegendGroup(
                            title: s.calendarLegendGroupSex,
                            items: sexItems,
                            hidden: _hiddenLegendCategories,
                            onToggle: toggle,
                          ),
                          const SizedBox(height: 14),
                          _LegendGroup(
                            title: s.calendarLegendGroupMethod,
                            items: methodItems,
                            hidden: _hiddenLegendCategories,
                            onToggle: toggle,
                          ),
                          const SizedBox(height: 14),
                          _LegendGroup(
                            title: s.calendarLegendGroupOther,
                            items: otherItems,
                            hidden: _hiddenLegendCategories,
                            onToggle: toggle,
                          ),
                        ],
                      ),
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

  // Selección simple (un solo toque): solo resalta/selecciona el día
  // tocado, sin abrir ningún menú — antes un solo toque ya abría de
  // golpe el menú contextual completo (ver _onDayTap más abajo), a
  // petición de la usuaria ahora hace falta doble toque o mantener
  // pulsado el número para abrirlo.
  void _onDaySelect(DateTime date) {
    setState(() => _selectedDate = date);
  }

  // Menú contextual mostrado al mantener pulsado o tocar dos veces un día del calendario, con 3
  // variantes según el estado del día tocado: (1) borde final de período
  // O día vacío a 1-2 días de una racha reciente → "Prolongar período";
  // (2) día intermedio de período → "Retirar período"/"Fin del período";
  // (3) día sin relación con el período → solo Notas/Leyenda/Cancelar.
  // Notas/Leyenda/Cancelar están siempre presentes; las opciones de
  // período se agregan arriba según el caso.
  void _onDayTap(DateTime date) {
    setState(() => _selectedDate = date);
    final s = AppStrings.of(context);
    final entry = widget.data[dateKey(date)];
    final isPeriodDay = entry != null && entry.isPeriodDay;
    // "Puede prolongar" cubre dos casos: (a) el día tocado es el borde
    // final exacto de una racha de período, o (b) el día tocado está
    // vacío pero a 1-2 días de una racha que terminó recientemente (ver
    // _findRecentPeriodEnd) — en ambos casos se ofrece "Prolongar
    // período" en vez del menú de día suelto.
    final isEndDay = isPeriodDay && _isPeriodEndDay(date);
    final canExtendFromGap = !isPeriodDay && _findRecentPeriodEnd(date) != null;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            if (isEndDay || canExtendFromGap)
              _SheetOption(
                label: s.calendarExtendPeriod,
                onTap: () {
                  Navigator.pop(ctx);
                  _extendPeriod(date);
                },
              )
            else if (isPeriodDay) ...[
              _SheetOption(
                label: s.calendarRemovePeriodDay,
                onTap: () {
                  Navigator.pop(ctx);
                  _removePeriodDay(date);
                },
              ),
              _SheetOption(
                label: s.calendarEndPeriodHere,
                onTap: () {
                  Navigator.pop(ctx);
                  _endPeriodHere(date);
                },
              ),
            ],
            _SheetOption(
              label: s.calendarNotes,
              onTap: () {
                Navigator.pop(ctx);
                _openDayEditor(date);
              },
            ),
            _SheetOption(
              label: s.calendarLegendOption,
              onTap: () {
                Navigator.pop(ctx);
                _showLegendSheet();
              },
            ),
            _SheetOption(
              label: s.calendarCancelOption,
              onTap: () => Navigator.pop(ctx),
              isCancel: true,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openDayEditor(DateTime date) {
    setState(() => _selectedDate = date);

    // Siempre se usa la pantalla "Registrar" (única pantalla de edición de
    // día en toda la app) — el antiguo editor modal `DayEditorSheet` quedó
    // retirado también aquí. RegisterScreen acepta `targetDate` para poder
    // trabajar sobre cualquier día, no solo hoy.
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => RegisterScreen(
              data: widget.data,
              onDataChanged: widget.onDataChanged,
              themeId: widget.themeId,
              targetDate: date,
              showCloseButton: true,
              userGoal: _userGoal,
            ),
          ),
        )
        .then((_) => widget.onAppointmentsChanged());
  }

  // Abre la pantalla nueva "Editar período" (rediseño v0) a pantalla
  // completa en vez del editor de día genérico — a diferencia de
  // _openDayEditor, esta pantalla deja marcar/desmarcar varios días de
  // período a la vez en un grid de varios meses, con su propio botón
  // GUARDAR que persiste los cambios vía onDataChanged.
  void _openPeriodEditor() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PeriodEditorScreen(
          data: widget.data,
          onDataChanged: widget.onDataChanged,
          themeId: widget.themeId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final predictor = CyclePredictor(
      widget.data,
      forceIrregular: widget.irregularCycleMode,
      selfReportedCycleLen: widget.selfReportedCycleLen,
      selfReportedPeriodLen: widget.selfReportedPeriodLen,
    );
    final prediction = predictor.predict();
    final s = AppStrings.of(context);
    // Las categorías "Fértil"/"Ovulación" y "Previsto" solo se ocultan
    // siempre del calendario en embarazo (además de lo que la usuaria haya
    // ocultado a mano en el panel "Leyenda"): "Fértil" ya se ve también en
    // "Seguir mi periodo", no solo en "Intentar concebir" — pero en
    // embarazo ni eso ni un "próximo periodo previsto" tienen sentido, y
    // sin forzar "Previsto" aquí el calendario seguía calculando y
    // marcando un periodo previsto a partir del último ciclo registrado
    // ANTES del embarazo, aunque ya no aplique (bug de cálculo).
    final effectiveHiddenLegendCategories = _userGoal == 'pregnancy'
        ? {..._hiddenLegendCategories, CalendarLegendCategory.fertile, CalendarLegendCategory.predicted}
        : _hiddenLegendCategories;

    return ColoredBox(
      color: CalendarPhaseColors.screenBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        child: Column(
          children: [
            // Deslizar verticalmente sobre la cuadrícula también cambia de
            // mes (arriba = mes siguiente, abajo = mes anterior), además de
            // los botones de flecha ya existentes — pedido de la usuaria.
            // Se usa Listener (eventos de puntero crudos) en vez de
            // GestureDetector.onVerticalDragEnd porque todo este bloque vive
            // dentro de un SingleChildScrollView que también arrastra en
            // vertical: si compitieran por el mismo "arena" de gestos, el
            // scroll ambiente podría quedarse con el gesto y este detector
            // nunca dispararía. Listener no participa en esa disputa: recibe
            // el down/move/up del dedo sin importar quién más lo use, así
            // que el cambio de mes siempre se evalúa al soltar, sin
            // interferir con el tap normal de cada día ni con el scroll de
            // la pantalla.
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) {
                _monthSwipeStartY = event.position.dy;
                _monthSwipeStartTime = event.timeStamp;
              },
              onPointerUp: (event) {
                final startY = _monthSwipeStartY;
                final startTime = _monthSwipeStartTime;
                _monthSwipeStartY = null;
                _monthSwipeStartTime = null;
                if (startY == null || startTime == null) return;
                final deltaY = event.position.dy - startY;
                final deltaSeconds = (event.timeStamp - startTime).inMicroseconds / 1e6;
                if (deltaSeconds <= 0) return;
                final velocity = deltaY / deltaSeconds; // px/s, positivo = hacia abajo
                if (deltaY.abs() < 40 || velocity.abs() < 200) return;
                _changeMonth(velocity < 0 ? 1 : -1);
              },
              child: ListenableBuilder(
                listenable: CalendarStyleController.instance,
                builder: (context, _) {
                  // "Estilo de calendario" (Configuración > Estilo de
                  // calendario): 'elegante' usa el diseño elevado
                  // (CalendarGridElegant), 'ios' usa el grid blanco
                  // minimalista con rayitas discontinuas en vez de círculos
                  // (CalendarGridIos, pedido explícitamente por la
                  // usuaria), cualquier otro valor (incluido el 'clasico'
                  // por defecto) sigue usando el grid de siempre. Los tres
                  // reciben exactamente los mismos datos y callbacks, así
                  // que cambiar de estilo nunca cambia qué se calcula, solo
                  // cómo se pinta.
                  if (CalendarStyleController.instance.styleId == 'elegante') {
                    return CalendarGridElegant(
                      viewMonth: _viewMonth,
                      selectedDate: _selectedDate,
                      data: widget.data,
                      prediction: prediction,
                      appointments: widget.appointments,
                      hiddenLegendCategories: effectiveHiddenLegendCategories,
                      onPrevMonth: () => _changeMonth(-1),
                      onNextMonth: () => _changeMonth(1),
                      onSelectDay: _onDaySelect,
                      onDayMenu: _onDayTap,
                      onJumpToMonth: _jumpToMonth,
                      emphasizeFertility: _userGoal != 'pregnancy',
                      themeId: widget.themeId,
                    );
                  }
                  if (CalendarStyleController.instance.styleId == 'ios') {
                    return CalendarGridIos(
                      viewMonth: _viewMonth,
                      selectedDate: _selectedDate,
                      data: widget.data,
                      prediction: prediction,
                      appointments: widget.appointments,
                      hiddenLegendCategories: effectiveHiddenLegendCategories,
                      onPrevMonth: () => _changeMonth(-1),
                      onNextMonth: () => _changeMonth(1),
                      onSelectDay: _onDaySelect,
                      onDayMenu: _onDayTap,
                      onJumpToMonth: _jumpToMonth,
                      emphasizeFertility: _userGoal != 'pregnancy',
                      themeId: widget.themeId,
                    );
                  }
                  return CalendarGrid(
                    viewMonth: _viewMonth,
                    selectedDate: _selectedDate,
                    data: widget.data,
                    prediction: prediction,
                    appointments: widget.appointments,
                    hiddenLegendCategories: effectiveHiddenLegendCategories,
                    onPrevMonth: () => _changeMonth(-1),
                    onNextMonth: () => _changeMonth(1),
                    onSelectDay: _onDaySelect,
                    onDayMenu: _onDayTap,
                    onJumpToMonth: _jumpToMonth,
                    emphasizeFertility: _userGoal != 'pregnancy',
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            // Leyenda de 4 categorías: Periodo (círculo sólido), Previsto y
            // Fértil (círculo con borde punteado), y Hoy (anillo verde sin
            // relleno) — la ovulación no aparece aquí, solo en el propio
            // calendario.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _LegendItem(color: CalendarPhaseColors.periodFill, label: s.legendPeriod),
                // "Previsto" (próximo periodo estimado) no tiene sentido en
                // embarazo — mismo criterio y misma bandera que
                // "Fértil"/"Ovulación" más abajo (ver
                // effectiveHiddenLegendCategories).
                if (_userGoal != 'pregnancy')
                  _LegendItem(
                    color: CalendarPhaseColors.predictedFill,
                    label: s.legendPrediction,
                    dashedBorder: CalendarPhaseColors.predictedBorder,
                  ),
                // "Fértil"/"Ovulación" se muestran tanto en "Seguir mi
                // periodo" como en "Intentar concebir" — pedido de la
                // usuaria para verlos también fuera del modo "concebir".
                // Solo se ocultan (leyenda y calendario, ver
                // effectiveHiddenLegendCategories más abajo) en embarazo,
                // donde no aportan nada.
                if (_userGoal != 'pregnancy')
                  _LegendItem(
                    color: CalendarPhaseColors.fertileFill,
                    label: s.legendFertile,
                    dashedBorder: CalendarPhaseColors.fertileBorder,
                  ),
                // "Ovulación" ya se pinta como círculo/rayita sólida en las
                // tres versiones del grid (día calculado dentro de la
                // ventana fértil), pero le faltaba su propia entrada en la
                // leyenda — s.legendOvulation ya existía en app_strings.dart
                // (con las 9 traducciones) pero nunca se usaba en ningún
                // lado: quedó pendiente de un trabajo anterior. Mismo swatch
                // sólido (sin borde punteado) que el círculo real.
                if (_userGoal != 'pregnancy')
                  _LegendItem(
                    color: CalendarPhaseColors.ovulationFill,
                    label: s.legendOvulation,
                  ),
                _LegendItem(
                  color: CalendarPhaseColors.todayRingColor,
                  label: s.legendToday,
                  ringOnly: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Botones "Editar período" / "Notas" — debajo de la leyenda,
            // dentro del contenido scrolleable normal de la pestaña (no
            // usan Positioned/Stack a nivel de pantalla), así que nunca
            // quedan fijos ni se solapan con el BottomNavigationBar
            // flotante de 5 pestañas de MainTabScreen.
            Row(
              children: [
                // "Editar período" no aporta durante el embarazo (no hay
                // periodos que marcar/desmarcar) — se oculta solo en ese
                // objetivo, dejando "Notas" a ancho completo.
                if (_userGoal != 'pregnancy') ...[
                  Expanded(
                    child: _PillActionButton(
                      label: s.calendarEditPeriod,
                      icon: Icons.edit_outlined,
                      background: CalendarPhaseColors.editPeriodPillBg,
                      foreground: CalendarPhaseColors.editPeriodPillText,
                      onTap: _openPeriodEditor,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                // Botón "i" pedido explícitamente por la usuaria: entre los
                // dos botones principales, ACTIVA/DESACTIVA (toggle) la fila
                // de resumen de abajo (_buildDaySummary) — "que sera un
                // boton para activa la informacion que este abajo". Ya no
                // abre una hoja aparte; la información vive siempre en el
                // mismo lugar, solo se muestra u oculta.
                _DayInfoIconButton(
                  active: _showDaySummary,
                  onTap: () => setState(() => _showDaySummary = !_showDaySummary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PillActionButton(
                    label: s.calendarNotes,
                    icon: Icons.description_outlined,
                    background: CalendarPhaseColors.notesPillBg,
                    foreground: CalendarPhaseColors.notesPillText,
                    onTap: () => _openDayEditor(_selectedDate),
                  ),
                ),
              ],
            ),
            // "Atajo" con lo registrado en _selectedDate (período, vida
            // sexual, síntomas/ánimo, método anticonceptivo, nota) — un
            // vistazo rápido de la información de ese día sin tener que
            // abrir "Notas" primero, como ya hacen otras apps de
            // seguimiento. Reutiliza las mismas categorías/colores de la
            // Leyenda de arriba, así que una categoría oculta ahí por
            // privacidad tampoco aparece aquí. Oculto por defecto: el botón
            // "i" de arriba es lo que la activa/desactiva (ver
            // _showDaySummary). AnimatedSize para que aparezca/desaparezca
            // con una transición suave en vez de un salto brusco.
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _showDaySummary
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: _buildDaySummary(s),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  // Arma la lista de chips con lo registrado en _selectedDate, usada por
  // _buildDaySummary (fila que el botón "i" activa/desactiva).
  List<Widget> _dayChips(AppStrings s) {
    final entry = widget.data[dateKey(_selectedDate)];
    bool visible(String categoryId) => !_hiddenLegendCategories.contains(categoryId);

    final chips = <Widget>[];
    if (entry != null) {
      if (entry.isPeriodDay && visible(CalendarLegendCategory.period)) {
        chips.add(_DaySummaryChip(
          icon: Icons.water_drop,
          color: CalendarPhaseColors.periodFill,
          label: '${s.calendarLegendCatPeriod} · ${s.flowTextOnlyLabelFor(entry.flow)}',
        ));
      }
      if (entry.sex && entry.unprotected && visible(CalendarLegendCategory.sexUnprotected)) {
        chips.add(_DaySummaryChip(
          icon: Icons.favorite,
          color: const Color(0xFFE24B4A),
          label: s.calendarLegendCatSexUnprotected,
        ));
      } else if (entry.sex && !entry.unprotected && visible(CalendarLegendCategory.sexProtected)) {
        chips.add(_DaySummaryChip(
          icon: Icons.favorite,
          color: const Color(0xFF1D9E75),
          label: s.calendarLegendCatSexProtected,
          halfHeart: true,
        ));
      }
      if (entry.sexMasturbation && visible(CalendarLegendCategory.masturbation)) {
        chips.add(_DaySummaryChip(
          icon: Icons.back_hand,
          color: const Color(0xFFD4537E),
          label: s.calendarLegendCatMasturbation,
        ));
      }
      if (entry.medication.contains('anticonceptivo') && visible(CalendarLegendCategory.pill)) {
        chips.add(_DaySummaryChip(
          icon: Icons.medication,
          color: const Color(0xFFBA7517),
          label: s.calendarLegendCatPill,
        ));
      }
      if (entry.diu && visible(CalendarLegendCategory.diu)) {
        chips.add(_DaySummaryChip(
          icon: Icons.shield_moon,
          color: const Color(0xFF7F77DD),
          label: s.calendarLegendCatDiu,
        ));
      }
      if ((entry.symptoms.isNotEmpty || entry.mood.isNotEmpty) && visible(CalendarLegendCategory.moodSymptoms)) {
        chips.add(_DaySummaryChip(
          icon: Icons.mood,
          color: const Color(0xFF7F77DD),
          label: s.calendarLegendCatMoodSymptoms,
        ));
      }
      if (entry.note.isNotEmpty && visible(CalendarLegendCategory.note)) {
        chips.add(_DaySummaryChip(
          icon: Icons.sticky_note_2,
          color: AppColors.textMuted,
          label: s.calendarLegendCatNote,
        ));
      }
    }

    return chips;
  }

  Widget _buildDaySummary(AppStrings s) {
    final chips = _dayChips(s);

    if (chips.isEmpty) {
      return GestureDetector(
        onTap: () => _openDayEditor(_selectedDate),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            s.calendarDaySummaryEmpty,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
        ),
      );
    }

    // Alineado a la izquierda explícitamente (Align + SizedBox de ancho
    // completo): la Column que envuelve todo este contenido no fija
    // crossAxisAlignment (queda en .center por defecto), así que un Wrap
    // sin esto quedaba centrado en vez de arrancar debajo de "Editar
    // período" como el resto de filas de la pantalla.
    return SizedBox(
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips
              .map((chip) => GestureDetector(onTap: () => _openDayEditor(_selectedDate), child: chip))
              .toList(),
        ),
      ),
    );
  }
}

// Chip compacto (ícono + etiqueta) de _buildDaySummary — mismo look que
// los swatches de la Leyenda, pero con relleno pastel y tocable (abre
// "Notas" del día seleccionado para ver/editar el detalle completo).
class _DaySummaryChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  // "Sexo con protección" se distingue de "sin protección" con un corazón
  // A LA MITAD en vez de un icono aparte (antes un escudo) — mismo criterio
  // que el indicador del grid del calendario, ver `_HalfHeartIcon` más
  // abajo. Cuando es `true`, `icon` no se usa.
  final bool halfHeart;

  const _DaySummaryChip({required this.icon, required this.color, required this.label, this.halfHeart = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          halfHeart ? _HalfHeartIcon(size: 14, color: color) : Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

/// Corazón "a la mitad": un corazón contorneado completo (`favorite_border`)
/// con la mitad izquierda rellena encima (`favorite` recortado al 50% del
/// ancho) — misma técnica que las calificaciones de media estrella.
/// Duplicado de `_HalfHeartIcon` en `widgets/calendar_grid.dart` (privado
/// ahí), mismo criterio de duplicación que ya sigue el resto de este
/// archivo con los pintores de línea punteada.
class _HalfHeartIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _HalfHeartIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.favorite_border, size: size, color: color),
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 0.5,
              child: Icon(Icons.favorite, size: size, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  // Color de borde punteado (diseño v0): usado por "Previsto" y "Fértil",
  // cuyos swatches son un círculo con relleno muy claro + trazo punteado,
  // en vez de relleno sólido.
  final Color? dashedBorder;
  // Swatch de anillo sólido SIN relleno (transparente por dentro) — usado
  // por "Hoy", para que coincida visualmente con el anillo verde que se
  // pinta sobre el día actual en el grid del calendario.
  final bool ringOnly;

  const _LegendItem({required this.color, required this.label, this.dashedBorder, this.ringOnly = false});

  @override
  Widget build(BuildContext context) {
    // Swatches un poco más grandes (14px) y con trazo más grueso que el
    // círculo punteado del propio grid del calendario — a 10px con
    // strokeWidth 1.2 el relleno pastel de "Previsto"/"Fértil" quedaba casi
    // invisible sobre el fondo lavanda de la pantalla.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ringOnly)
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.5),
            ),
          )
        else if (dashedBorder != null)
          CustomPaint(
            size: const Size(14, 14),
            painter: _DashedCirclePainter(color: dashedBorder!, strokeWidth: 1.8),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          )
        else
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

/// Trazo punteado circular para los swatches de la leyenda "Previsto" /
/// "Fértil" (círculo con relleno muy claro + borde punteado del tono
/// correspondiente).
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  const _DashedCirclePainter({required this.color, this.strokeWidth = 1.2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2 - 0.6));
    const dashWidth = 2.2;
    const dashGap = 1.6;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        final clampedNext = next > metric.length ? metric.length : next;
        canvas.drawPath(metric.extractPath(distance, clampedNext), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Datos de una categoría dentro del panel "Leyenda" con switches (ver
/// `_CalendarScreenState._showLegendSheet`). `id` es una de las constantes
/// de `CalendarLegendCategory`.
class _LegendCategoryItem {
  final String id;
  final IconData icon;
  final String label;
  final Color accent;
  // Ver `_HalfHeartIcon`: cuando es `true`, la fila pinta un corazón a la
  // mitad en vez de `icon` (caso de "sexo con protección").
  final bool halfHeart;

  const _LegendCategoryItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.accent,
    this.halfHeart = false,
  });
}

/// Bloque con título de grupo + tarjeta blanca conteniendo una fila por
/// categoría (icono + etiqueta + switch), replicando el diseño de
/// referencia (lista de "activación" con switches morados).
class _LegendGroup extends StatelessWidget {
  final String title;
  final List<_LegendCategoryItem> items;
  final Set<String> hidden;
  final ValueChanged<String> onToggle;

  const _LegendGroup({
    required this.title,
    required this.items,
    required this.hidden,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            // Antes llevaba borde plano; ahora sombra suave, mismo lenguaje
            // de tarjeta elevada del rediseño aplicado en Inicio.
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withOpacity(0.16),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                _LegendSwitchRow(
                  item: items[i],
                  isOn: !hidden.contains(items[i].id),
                  showDivider: i < items.length - 1,
                  onChanged: () => onToggle(items[i].id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Una fila individual dentro de `_LegendGroup`: icono redondeado con color
/// de acento, etiqueta, y switch a la derecha que activa/desactiva si esa
/// categoría se pinta en el calendario.
class _LegendSwitchRow extends StatelessWidget {
  final _LegendCategoryItem item;
  final bool isOn;
  final bool showDivider;
  final VoidCallback onChanged;

  const _LegendSwitchRow({
    required this.item,
    required this.isOn,
    required this.showDivider,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: AppColors.border, width: 1)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: item.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: item.halfHeart
                ? _HalfHeartIcon(size: 18, color: item.accent)
                : Icon(item.icon, size: 18, color: item.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            ),
          ),
          Switch.adaptive(
            value: isOn,
            onChanged: (_) => onChanged(),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

/// Una fila del menú contextual mostrado al tocar un día del calendario
/// (estilo lista de opciones tipo action sheet). La opción "Cancelar" se
/// distingue con texto en negrita normal (sin color de acento) y un
/// pequeño espacio arriba, imitando la separación visual de un action
/// sheet nativo respecto a las demás opciones.
class _SheetOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isCancel;

  const _SheetOption({required this.label, required this.onTap, this.isCancel = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          margin: isCancel ? const EdgeInsets.only(top: 6) : EdgeInsets.zero,
          decoration: isCancel
              ? const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                )
              : null,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isCancel ? FontWeight.w600 : FontWeight.w600,
              color: isCancel ? AppColors.textMuted : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón redondo, solo ícono, entre "Editar período" y "Notas" — pedido
/// explícito de la usuaria para dar acceso directo a la información del
/// día sin ocupar el ancho de un botón con texto. Misma altura (46) que
/// _PillActionButton para quedar alineado en la fila.
class _DayInfoIconButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _DayInfoIconButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Con la información activada el botón cambia de fondo/ícono (relleno
    // en vez de contorno) para que quede claro que es un toggle prendido,
    // no solo un acceso directo.
    const purple = Color(0xFF7F77DD);
    return Material(
      color: active ? purple.withOpacity(0.22) : const Color(0xFFF1EEFB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 46,
          width: 46,
          child: Center(
            child: Icon(active ? Icons.info : Icons.info_outline, size: 20, color: purple),
          ),
        ),
      ),
    );
  }
}

/// Botón en píldora usado para "Editar período" y "Notas" debajo de la
/// leyenda, siguiendo el diseño v0 aprobado (fondo pastel, texto e ícono
/// del mismo tono, altura fija).
class _PillActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _PillActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

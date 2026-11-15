import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/day_entry.dart';
import '../services/cycle_predictor.dart' show dateKey;
import '../theme/app_theme.dart';

/// Pantalla "Editar período", portada del diseño v0 aprobado
/// (`components/period-editor.tsx`). Se abre a pantalla completa desde el
/// botón "Editar período" del calendario (ver `CalendarScreen`), en vez del
/// editor de día genérico (`DayEditorSheet`).
///
/// Muestra varios meses en scroll vertical continuo con un círculo tocable
/// por día: vacío/gris por defecto, rosa sólido con check blanco al marcar
/// un día nuevo como período, y círculo punteado rosa numerado (1, 2, 3…)
/// para los días que YA estaban guardados como período al abrir la
/// pantalla (mientras sigan marcados). El botón "GUARDAR" fijo abajo
/// persiste los cambios reales sobre `data` vía `onDataChanged`.
class PeriodEditorScreen extends StatefulWidget {
  final Map<String, DayEntry> data;
  final ValueChanged<Map<String, DayEntry>> onDataChanged;

  // Id del tema de color elegido en Configuración — por ahora esta pantalla
  // sigue el rosa exacto de CalendarPhaseColors (mismo criterio que
  // CalendarGrid, cuyos colores de fase tampoco cambian con el tema), pero
  // se acepta la prop para mantener el mismo patrón de constructor que el
  // resto de pantallas (CalendarScreen/RegisterScreen) y dejar la puerta
  // abierta a usarla más adelante.
  final String themeId;

  const PeriodEditorScreen({
    super.key,
    required this.data,
    required this.onDataChanged,
    this.themeId = 'pink',
  });

  @override
  State<PeriodEditorScreen> createState() => _PeriodEditorScreenState();
}

/// Un mes completo dividido en semanas de 7 celdas (algunas vacías = sin
/// fecha, para completar la primera/última semana del mes).
class _MonthData {
  final String title;
  final List<List<DateTime?>> weeks;
  const _MonthData(this.title, this.weeks);
}

class _PeriodEditorScreenState extends State<PeriodEditorScreen> {
  /// Días que YA estaban guardados como período al abrir la pantalla
  /// (snapshot inmutable, usado para decidir "showSaved" igual que
  /// `savedSet` en el prototipo v0).
  late final Set<String> _savedSet;

  /// Días actualmente marcados como período (copia mutable de _savedSet,
  /// que el usuario puede tocar para agregar/quitar días).
  late Set<String> _marked;

  late final DateTime _today;
  late final List<_MonthData> _months;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);

    _savedSet = widget.data.entries.where((e) => e.value.isPeriodDay).map((e) => e.key).toSet();
    _marked = Set<String>.from(_savedSet);

    // Dos meses antes de hoy y hasta 6 meses en total, igual que
    // `buildMonthRange(TODAY.getFullYear(), TODAY.getMonth() - 2, 6)` en el
    // prototipo v0 — suficiente contexto para marcar un período que cruza
    // de mes sin tener que navegar.
    _months = _buildMonthRange(_today.year, _today.month - 2, 6);
  }

  List<_MonthData> _buildMonthRange(int year, int startMonth0, int count) {
    final months = <_MonthData>[];
    var y = year;
    var m0 = startMonth0; // 0-based, puede venir negativo
    for (var i = 0; i < count; i++) {
      // Normaliza mes 0-based fuera de [0, 11] a un año/mes válidos.
      var yy = y + (m0 ~/ 12);
      var mm = m0 % 12;
      if (mm < 0) {
        mm += 12;
        yy -= 1;
      }
      final month1 = mm + 1; // 1-based para DateTime
      months.add(_buildMonth(yy, month1));
      m0++;
    }
    return months;
  }

  _MonthData _buildMonth(int year, int month) {
    final s = AppStrings.of(context);
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Semana empieza en lunes (Mon=1..Sun=7 en DateTime.weekday), igual
    // que CalendarGrid.
    final startOffset = firstDay.weekday - 1;

    final cells = <DateTime?>[];
    for (var i = 0; i < startOffset; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(year, month, d));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final weeks = <List<DateTime?>>[];
    for (var i = 0; i < cells.length; i += 7) {
      weeks.add(cells.sublist(i, i + 7));
    }

    final title = '${s.monthName(month)[0].toUpperCase()}${s.monthName(month).substring(1)} $year';
    return _MonthData(title, weeks);
  }

  void _toggle(DateTime date) {
    final key = dateKey(date);
    setState(() {
      if (_marked.contains(key)) {
        _marked.remove(key);
      } else {
        // No se puede marcar como período un día que todavía no llegó (no
        // hay forma de haber sangrado en el futuro) — quitar un día ya
        // marcado sigue permitido siempre, solo se bloquea AGREGAR uno
        // nuevo en el futuro. `_DayCircle` ya evita este toque de raíz
        // (onTap null en días futuros), esto es el mismo resguardo aquí
        // por si `_toggle` se llama desde otro lado en el futuro.
        if (date.isAfter(_today)) return;
        _marked.add(key);
      }
    });
  }

  /// Qué día de la racha consecutiva representa esta fecha: 1, 2, 3…
  /// (mismo cálculo que `seqFor` en el prototipo v0).
  int _seqFor(DateTime date) {
    var seq = 1;
    var d = DateTime(date.year, date.month, date.day - 1);
    while (_marked.contains(dateKey(d))) {
      seq++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return seq;
  }

  void _save() {
    final updated = Map<String, DayEntry>.from(widget.data);
    final allKeys = <String>{..._savedSet, ..._marked};
    for (final key in allKeys) {
      final wasMarked = _savedSet.contains(key);
      final isMarked = _marked.contains(key);
      if (isMarked && !wasMarked) {
        // Día nuevo marcado como período: crea o actualiza la entrada con
        // flujo 'medium' (mismo criterio que usa el resto de la app para
        // decidir "día de período" — ver `DayEntry.isPeriodDay`).
        final existing = updated[key] ?? const DayEntry();
        updated[key] = existing.copyWith(flow: 'medium');
      } else if (!isMarked && wasMarked) {
        // Día destildado: quita el flujo. Si el día queda sin ningún otro
        // dato, se elimina la entrada por completo (igual que el resto de
        // la app hace al borrar un día vacío).
        final existing = updated[key];
        if (existing != null) {
          final cleared = existing.copyWith(flow: 'none');
          if (cleared.isEmpty) {
            updated.remove(key);
          } else {
            updated[key] = cleared;
          }
        }
      }
    }
    widget.onDataChanged(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final weekdayLabels = s.weekdayInitialsMondayFirstList;

    return Scaffold(
      backgroundColor: CalendarPhaseColors.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior: X para cerrar + título centrado.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                    tooltip: s.periodEditorCloseA11y,
                  ),
                  Expanded(
                    child: Text(
                      s.calendarEditPeriod,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Compensa el ancho del IconButton, título queda centrado.
                ],
              ),
            ),

            // Banner de instrucción con ícono de gota.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: CalendarPhaseColors.fertileFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CalendarPhaseColors.fertileBorder.withOpacity(0.6)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: CalendarPhaseColors.periodFill.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.water_drop, size: 16, color: CalendarPhaseColors.periodFill),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.periodEditorInstruction,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CalendarPhaseColors.periodFill,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Fila de iniciales de día de la semana, fija (no scrollea con
            // los meses) — igual que el header "sticky" del prototipo v0.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: weekdayLabels
                    .map((w) => Expanded(
                          child: Center(
                            child: Text(
                              w.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 4),

            // Grid de meses en scroll vertical continuo. El padding inferior
            // deja espacio para que el botón GUARDAR fijo no tape el último
            // mes visible.
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                itemCount: _months.length,
                itemBuilder: (context, index) => _MonthSection(
                  month: _months[index],
                  today: _today,
                  marked: _marked,
                  savedSet: _savedSet,
                  onToggle: _toggle,
                  seqFor: _seqFor,
                  todayLabel: s.periodEditorTodayLabel,
                ),
              ),
            ),
          ],
        ),
      ),
      // Botón GUARDAR fijo abajo, ancho completo, con un degradado sutil
      // del fondo pastel a transparente detrás (igual que el prototipo v0)
      // para que el texto del mes no quede pegado justo debajo del botón.
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                CalendarPhaseColors.screenBackground,
                CalendarPhaseColors.screenBackground.withOpacity(0.0),
              ],
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: CalendarPhaseColors.periodFill,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              child: Text(
                s.periodEditorSave,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un mes completo: título + grid de 7 columnas por semana.
class _MonthSection extends StatelessWidget {
  final _MonthData month;
  final DateTime today;
  final Set<String> marked;
  final Set<String> savedSet;
  final ValueChanged<DateTime> onToggle;
  final int Function(DateTime) seqFor;
  final String todayLabel;

  const _MonthSection({
    required this.month,
    required this.today,
    required this.marked,
    required this.savedSet,
    required this.onToggle,
    required this.seqFor,
    required this.todayLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
          child: Text(
            month.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
        ...month.weeks.map(
          (week) => Row(
            children: week
                .map((date) => Expanded(
                      child: _DayCircle(
                        date: date,
                        today: today,
                        marked: marked,
                        savedSet: savedSet,
                        onToggle: onToggle,
                        seqFor: seqFor,
                        todayLabel: todayLabel,
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

/// Celda tocable de un día: etiqueta "HOY" arriba (si aplica), número del
/// día y círculo de estado abajo. Replica el `EditorDay` del prototipo v0.
class _DayCircle extends StatelessWidget {
  final DateTime? date;
  final DateTime today;
  final Set<String> marked;
  final Set<String> savedSet;
  final ValueChanged<DateTime> onToggle;
  final int Function(DateTime) seqFor;
  final String todayLabel;

  const _DayCircle({
    required this.date,
    required this.today,
    required this.marked,
    required this.savedSet,
    required this.onToggle,
    required this.seqFor,
    required this.todayLabel,
  });

  @override
  Widget build(BuildContext context) {
    final d = date;
    if (d == null) {
      return const SizedBox(height: 64);
    }

    final key = dateKey(d);
    final isToday = d.year == today.year && d.month == today.month && d.day == today.day;
    // Los días futuros no se pueden marcar como período (todavía no
    // llegaron) — se muestran atenuados y sin toque, a diferencia de los
    // recordatorios (pantalla aparte), que sí admiten fechas futuras.
    final isFuture = d.isAfter(today);
    final isMarked = marked.contains(key);
    // "Ya estaba guardado" (círculo punteado numerado) solo si el día
    // seguía marcado Y estaba en el set original al abrir la pantalla —
    // igual que `showSaved = marked && saved` en el prototipo v0.
    final showSaved = isMarked && savedSet.contains(key);

    Color background;
    Color foreground;
    Border? border;
    if (!isMarked) {
      background = Colors.white.withOpacity(0.6);
      foreground = Colors.transparent;
      border = Border.all(color: CalendarPhaseColors.gridDivider);
    } else if (showSaved) {
      background = CalendarPhaseColors.fertileFill;
      foreground = CalendarPhaseColors.periodFill;
      border = Border.all(color: CalendarPhaseColors.periodFill, width: 2);
    } else {
      background = CalendarPhaseColors.periodFill;
      foreground = Colors.white;
      border = null;
    }

    return GestureDetector(
      onTap: isFuture ? null : () => onToggle(d),
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: isFuture ? 0.35 : 1.0,
        child: SizedBox(
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 12,
              child: isToday
                  ? Text(
                      todayLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: CalendarPhaseColors.periodFill,
                        letterSpacing: 0.5,
                      ),
                    )
                  : null,
            ),
            Text(
              '${d.day}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                color: isToday ? CalendarPhaseColors.periodFill : AppColors.textPrimary,
                decoration: isToday ? TextDecoration.underline : TextDecoration.none,
                decorationColor: CalendarPhaseColors.periodFill,
                decorationThickness: 2,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: background,
                shape: showSaved ? BoxShape.circle : BoxShape.circle,
                border: border,
              ),
              alignment: Alignment.center,
              child: !isMarked
                  ? null
                  : showSaved
                      ? Text(
                          '${seqFor(d)}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: foreground),
                        )
                      : Icon(Icons.check, size: 14, color: foreground),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

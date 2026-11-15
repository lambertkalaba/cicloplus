import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/day_entry.dart';
import '../services/calendar_style_controller.dart';
import '../services/cycle_predictor.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

/// Tercera opción de "Estilo de calendario" (Configuración > Estilo de
/// calendario), pedida explícitamente como "calendario de iOS": grid
/// blanco y minimalista tipo Calendario/Recordatorios de Apple, sin
/// ningún círculo relleno — ni para período/previsto/fértil/ovulación, ni
/// para el día seleccionado. Todo marcador es una RAYITA discontinua
/// (línea de puntos/segmentos) debajo del número del día, pintada con los
/// mismos colores que ya usa el registro de período (`CalendarPhaseColors`)
/// — la usuaria pidió textualmente "en vez de círculo que sea línea de
/// raya los colores de registro de periodo". "Hoy" es la ÚNICA excepción:
/// a petición posterior de la usuaria ("quiero que hoy sea en círculo"),
/// el número de hoy lleva además un aro (círculo sin relleno) alrededor,
/// sin tocar la rayita de color de período/fértil/ovulación si coincide
/// con hoy.
///
/// Misma interfaz pública que `CalendarGrid`/`CalendarGridElegant` para
/// poder sustituirla 1:1 en `CalendarScreen` según `CalendarStyleController`.
class CalendarGridIos extends StatelessWidget {
  final DateTime viewMonth;
  final DateTime selectedDate;
  final Map<String, DayEntry> data;
  final CyclePrediction prediction;
  final List<MedicalAppointment> appointments;
  final Set<String> hiddenLegendCategories;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDay;
  // Menú contextual (Prolongar período/Notas/Leyenda/Cancelar) — ya no
  // se abre con un solo toque (eso ahora solo selecciona el día, ver
  // onSelectDay), hace falta doble toque o mantener pulsado, a
  // petición de la usuaria.
  final ValueChanged<DateTime> onDayMenu;
  final ValueChanged<DateTime>? onJumpToMonth;
  final bool emphasizeFertility;
  final String themeId;

  const CalendarGridIos({
    super.key,
    required this.viewMonth,
    required this.selectedDate,
    required this.data,
    required this.prediction,
    this.appointments = const [],
    this.hiddenLegendCategories = const {},
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onSelectDay,
    required this.onDayMenu,
    this.onJumpToMonth,
    this.emphasizeFertility = false,
    this.themeId = 'pink',
  });

  Future<void> _pickMonthYear(BuildContext context) async {
    final s = AppStrings.of(context);
    var selectedMonth = viewMonth.month;
    final years = List<int>.generate(21, (i) => viewMonth.year - 10 + i);
    var selectedYearIndex = years.indexOf(viewMonth.year);
    if (selectedYearIndex < 0) selectedYearIndex = 10;

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, DateTime(years[selectedYearIndex], selectedMonth, 1)),
                          child: Text(s.reminderTimeSheetDone, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 216,
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(initialItem: selectedMonth - 1),
                            itemExtent: 40,
                            onSelectedItemChanged: (i) => setSheetState(() => selectedMonth = i + 1),
                            children: List.generate(
                              12,
                              (i) => Center(child: Text(s.monthShort(i + 1), style: const TextStyle(fontSize: 18))),
                            ),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(initialItem: selectedYearIndex),
                            itemExtent: 40,
                            onSelectedItemChanged: (i) => setSheetState(() => selectedYearIndex = i),
                            children: years
                                .map((y) => Center(child: Text('$y', style: const TextStyle(fontSize: 18))))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
    if (result != null) (onJumpToMonth ?? (_) {}).call(result);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final accent = Color(themeById(themeId).primary);
    final weekdayLabels = s.weekdayInitialsMondayFirstList;
    final year = viewMonth.year;
    final month = viewMonth.month;
    final firstDay = DateTime(year, month, 1);
    final startOffset = firstDay.weekday - 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final today = DateTime.now();

    final appointmentDateKeys =
        appointments.where((a) => !a.id.startsWith('pill_')).map((a) => dateKey(a.dateTime)).toSet();
    final pillReminderDateKeys =
        appointments.where((a) => a.id.startsWith('pill_')).map((a) => dateKey(a.dateTime)).toSet();

    // "Forma"/"Relleno" de Configuración > Estilo de calendario — antes
    // solo aplicaban al estilo "Clásico"; a pedido de la usuaria ("lo mismo
    // quiero que esté también en elegante y ios") ahora también rigen
    // aquí. "Raya" (valor por defecto) mantiene el aspecto original de
    // este estilo; "Cuadrado"/"Círculo" pintan en cambio una figura de
    // color detrás del número, con relleno sólido o solo borde según "Con
    // relleno"/"Sin relleno" — mismo criterio de colores que CalendarGrid.
    final markerShape = CalendarStyleController.instance.markerShape;
    final markerFill = CalendarStyleController.instance.markerFill;
    final useShapeMarker = markerShape != 'raya';

    _IosDayKind kindOf(String key) {
      final entry = data[key];
      final isLogged = entry != null && entry.isPeriodDay;
      final isOvulationDay = prediction.ovulationDate != null && dateKey(prediction.ovulationDate!) == key;
      if (isLogged && !hiddenLegendCategories.contains(CalendarLegendCategory.period)) return _IosDayKind.period;
      if (isOvulationDay && !hiddenLegendCategories.contains(CalendarLegendCategory.fertile)) {
        return _IosDayKind.ovulation;
      }
      if (prediction.fertileDates.contains(key) && !hiddenLegendCategories.contains(CalendarLegendCategory.fertile)) {
        return _IosDayKind.fertile;
      }
      if (prediction.predictedPeriodDates.contains(key) &&
          !hiddenLegendCategories.contains(CalendarLegendCategory.predicted)) {
        return _IosDayKind.predicted;
      }
      return _IosDayKind.none;
    }

    // Mismo color que ya usa el registro de período en el resto de la app
    // (`CalendarPhaseColors`, alimentado por la paleta elegida en
    // Configuración) — aquí se usa tanto para el número como para la
    // rayita discontinua de debajo, en vez de como fondo de una cápsula.
    Color? colorOf(_IosDayKind kind) {
      switch (kind) {
        case _IosDayKind.period:
          return CalendarPhaseColors.periodFill;
        case _IosDayKind.predicted:
          return CalendarPhaseColors.predictedBorder;
        case _IosDayKind.fertile:
          return CalendarPhaseColors.fertileBorder;
        case _IosDayKind.ovulation:
          return CalendarPhaseColors.ovulationFill;
        case _IosDayKind.none:
          return null;
      }
    }

    final cells = <Widget>[];
    for (var i = 0; i < startOffset; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final dateObj = DateTime(year, month, d);
      final key = dateKey(dateObj);
      final entry = data[key];
      final isToday = key == dateKey(today);
      final isSelected = key == dateKey(selectedDate);
      final kind = kindOf(key);

      final hasAppointment = appointmentDateKeys.contains(key);
      final hasPillReminder = pillReminderDateKeys.contains(key);

      bool visible(String categoryId) => !hiddenLegendCategories.contains(categoryId);
      _IosIndicator? indicator;
      if (entry != null && entry.sex && entry.unprotected && visible(CalendarLegendCategory.sexUnprotected)) {
        indicator = const _IosIndicator(Color(0xFFE24B4A), isHeart: true);
      } else if (entry != null && entry.sex && !entry.unprotected && visible(CalendarLegendCategory.sexProtected)) {
        indicator = const _IosIndicator(Color(0xFF1D9E75), isHeart: true, halfHeart: true);
      } else if (entry != null && entry.sexMasturbation && visible(CalendarLegendCategory.masturbation)) {
        indicator = const _IosIndicator(Color(0xFFD4537E));
      } else if (entry != null && entry.medication.contains('anticonceptivo') && visible(CalendarLegendCategory.pill)) {
        indicator = const _IosIndicator(Color(0xFFBA7517));
      } else if (entry != null && entry.diu && visible(CalendarLegendCategory.diu)) {
        indicator = const _IosIndicator(Color(0xFF7F77DD));
      } else if ((hasAppointment || hasPillReminder) && visible(CalendarLegendCategory.pill)) {
        indicator = const _IosIndicator(Color(0xFFF59F00));
      }

      // Prioridad del color de la rayita/número: período/previsto/fértil/
      // ovulación primero (son los "colores de registro de periodo" que
      // pidió la usuaria); si el día no tiene ninguno de esos, "hoy" y
      // "seleccionado" usan los mismos acentos que ya tenía el resto de
      // estilos (verde de hoy, morado de selección) — así nunca aparece un
      // círculo, solo cambia de qué color es la rayita.
      final kindColor = colorOf(kind);
      final lineColor = kindColor ?? (isToday ? CalendarPhaseColors.todayRingColor : (isSelected ? CalendarPhaseColors.selectedDayFill : null));
      // Mismo BUG que en CalendarGridElegant: `emphasizeFertility` llegaba
      // como prop pero nunca se usaba acá. Este estilo no tiene círculos
      // rellenos que "resaltar más" como el Clásico (solo la rayita
      // discontinua), así que el equivalente es engrosarla — mismo
      // criterio de "bold" que ya se usaba para hoy/seleccionado.
      final emphasizeThisDay = emphasizeFertility && (kind == _IosDayKind.fertile || kind == _IosDayKind.ovulation);
      final bold = isToday || isSelected || emphasizeThisDay;

      // Colores de fondo/borde/texto de la figura de fase (Cuadrado/
      // Círculo) — mismos tonos que CalendarGrid/CalendarGridElegant.
      // `null` en 'none' (día normal) o cuando la Forma elegida es "Raya"
      // (ese caso sigue el camino original de abajo, sin figura).
      Color? phaseBg;
      Color? phaseBorderTone;
      Color? phaseTextTone;
      switch (kind) {
        case _IosDayKind.period:
          phaseBg = CalendarPhaseColors.periodFill;
          phaseTextTone = CalendarPhaseColors.periodText;
          break;
        case _IosDayKind.predicted:
          phaseBg = CalendarPhaseColors.predictedFill;
          phaseTextTone = CalendarPhaseColors.predictedText;
          phaseBorderTone = CalendarPhaseColors.predictedBorder;
          break;
        case _IosDayKind.fertile:
          phaseBg = CalendarPhaseColors.fertileFill;
          phaseTextTone = CalendarPhaseColors.fertileText;
          phaseBorderTone = CalendarPhaseColors.fertileBorder;
          break;
        case _IosDayKind.ovulation:
          phaseBg = CalendarPhaseColors.ovulationFill;
          phaseTextTone = CalendarPhaseColors.ovulationText;
          break;
        case _IosDayKind.none:
          break;
      }
      final bool showShapeMarker = useShapeMarker && phaseBg != null;
      final bool shapeFilled = markerFill == 'filled';
      final Color? shapeBackground = showShapeMarker ? (shapeFilled ? phaseBg : Colors.transparent) : null;
      final Color? shapeBorderColor = !showShapeMarker
          ? null
          : (emphasizeThisDay && kind == _IosDayKind.fertile)
              ? CalendarPhaseColors.fertileBorder
              : (shapeFilled ? phaseBorderTone : (phaseBorderTone ?? phaseBg));
      final double shapeBorderWidth =
          (emphasizeThisDay && kind == _IosDayKind.fertile) ? 2.2 : (shapeFilled ? 1.4 : 2.0);
      final bool circleLook = isToday || (showShapeMarker && markerShape == 'circle');

      final Widget cell = GestureDetector(
        onTap: () => onSelectDay(dateObj),
        onDoubleTap: () => onDayMenu(dateObj),
        onLongPress: () => onDayMenu(dateObj),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // "Hoy" lleva un aro alrededor del número (única excepción al
            // "sin círculo" del resto del estilo iOS, pedida aparte) — el
            // color de la rayita (lineColor) no cambia, así que si hoy
            // coincide con un día de período/fértil/ovulación, el aro se ve
            // del mismo color que ya tenía la rayita en vez de perderlo.
            // Con Forma Cuadrado/Círculo, los demás días llevan además su
            // propia figura de color detrás del número (relleno sólido o
            // solo borde según "Con relleno"/"Sin relleno").
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isToday ? null : shapeBackground,
                shape: circleLook ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: circleLook ? null : BorderRadius.zero,
                border: isToday
                    ? Border.all(color: lineColor ?? CalendarPhaseColors.todayRingColor, width: 2)
                    : (shapeBorderColor != null ? Border.all(color: shapeBorderColor, width: shapeBorderWidth) : null),
              ),
              child: Text(
                '$d',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: (kind != _IosDayKind.none || bold) ? FontWeight.w700 : FontWeight.w400,
                  color: !showShapeMarker
                      ? (lineColor ?? AppColors.textPrimary)
                      : (shapeFilled ? (phaseTextTone ?? AppColors.textPrimary) : (shapeBorderColor ?? AppColors.textPrimary)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 22,
              height: 4,
              child: (useShapeMarker || lineColor == null)
                  ? null
                  : CustomPaint(painter: _DashedUnderlinePainter(color: lineColor, bold: bold)),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 8,
              child: indicator == null
                  ? null
                  : (indicator.isHeart
                      ? (indicator.halfHeart
                          ? _IosHalfHeartIcon(size: 8, color: indicator.color)
                          : Icon(Icons.favorite, size: 8, color: indicator.color))
                      : Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: indicator.color),
                        )),
            ),
          ],
        ),
      );

      cells.add(cell);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        children: [
          // Cabecera centrada con flechas — igual que Calendario/
          // Recordatorios de iOS, en vez de las píldoras del estilo Clásico.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IosChevronButton(icon: Icons.chevron_left, onTap: onPrevMonth),
              GestureDetector(
                onTap: () => _pickMonthYear(context),
                child: Text(
                  '${s.monthShort(month)} $year',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => (onJumpToMonth ?? (_) {}).call(DateTime(today.year, today.month, 1)),
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(s.calendarTodayButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  _IosChevronButton(icon: Icons.chevron_right, onTap: onNextMonth),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: weekdayLabels
                .map((w) => Expanded(
                      child: Center(
                        child: Text(
                          w.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8E8E93),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          // Líneas divisorias finas horizontales entre semanas, sin
          // divisores verticales — igual que las filas de una tabla tipo
          // iOS, en vez del grid con recuadro completo del estilo Clásico.
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.9,
            children: List.generate(cells.length, (i) {
              final isLastRow = i >= cells.length - (cells.length % 7 == 0 ? 7 : cells.length % 7);
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: isLastRow ? BorderSide.none : const BorderSide(color: Color(0xFFF0F0F2), width: 1),
                  ),
                ),
                child: cells[i],
              );
            }),
          ),
        ],
      ),
    );
  }
}

enum _IosDayKind { none, period, predicted, fertile, ovulation }

class _IosIndicator {
  final Color color;
  final bool isHeart;
  final bool halfHeart;
  const _IosIndicator(this.color, {this.isHeart = false, this.halfHeart = false});
}

/// Corazón mitad-relleno para "sexo con protección" — misma técnica que
/// `_HalfHeartIcon` de `calendar_grid.dart` (estilo Clásico), duplicada aquí
/// porque esa es privada a ese archivo (mismo criterio de duplicación que ya
/// sigue el resto de este widget).
class _IosHalfHeartIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _IosHalfHeartIcon({required this.size, required this.color});

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

/// Rayita discontinua bajo el número del día — el marcador central de este
/// estilo, en sustitución de cualquier círculo relleno o anillo.
class _DashedUnderlinePainter extends CustomPainter {
  final Color color;
  final bool bold;
  const _DashedUnderlinePainter({required this.color, this.bold = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = bold ? 2.6 : 1.8
      ..strokeCap = StrokeCap.round;
    const dashWidth = 3.5;
    const dashGap = 2.5;
    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      final xEnd = (x + dashWidth) > size.width ? size.width : (x + dashWidth);
      canvas.drawLine(Offset(x, y), Offset(xEnd, y), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedUnderlinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.bold != bold;
}

class _IosChevronButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IosChevronButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 22, color: const Color(0xFF8E8E93)),
        ),
      ),
    );
  }
}

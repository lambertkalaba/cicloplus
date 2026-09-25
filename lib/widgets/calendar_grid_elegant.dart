import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/day_entry.dart';
import '../services/calendar_style_controller.dart';
import '../services/cycle_predictor.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

/// Segunda opción de "Estilo de calendario" (Configuración > Colores del
/// calendario), pensada como una versión más elegante/moderna del grid
/// clásico de `CalendarGrid`: tarjeta blanca elevada con sombra suave (en
/// vez de fondo plano lavanda) y botones de navegación circulares.
///
/// Rediseño pedido explícitamente por la usuaria ("no quiero los círculos,
/// solo las línea rayas, se ve más limpio y elegante, lo unico círculo que
/// sea de seleccion o dia de hoy pero con su color"): la versión anterior
/// pintaba período/previsto/fértil/ovulación como círculos ("bicho") sobre
/// una "pista" de color de fondo — ahora esos 4 estados se marcan SOLO con
/// una rayita discontinua de color debajo del número (mismo lenguaje visual
/// que el estilo iOS), y el número en sí nunca lleva relleno ni pista. Los
/// ÚNICOS círculos que quedan son el aro de "hoy" (verde, mismo tono que
/// usan Clásico/iOS) y el aro de "seleccionado" (color de acento de la
/// app) — si un día es hoy Y está seleccionado a la vez, gana el aro verde
/// de hoy, igual criterio que en los otros dos estilos.
///
/// Recibe exactamente las mismas props que `CalendarGrid` (mismo
/// `CyclePrediction`, mismos datos, mismos callbacks) para poder
/// sustituirlo 1:1 en `CalendarScreen` según `CalendarStyleController` —
/// ver ese controlador para cómo se elige uno u otro. Duplica la lógica de
/// clasificación de días (period/predicted/fertile/ovulation) en vez de
/// reusar la de `CalendarGrid` porque esa es privada a ese archivo; ambas
/// copias leen la MISMA fuente de verdad (`CyclePrediction`/`DayEntry`),
/// así que no hay riesgo de que el cálculo diverja entre estilos, solo la
/// pintura final.
class CalendarGridElegant extends StatelessWidget {
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

  const CalendarGridElegant({
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
                            children:
                                years.map((y) => Center(child: Text('$y', style: const TextStyle(fontSize: 18)))).toList(),
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
    // aquí. "Raya" (el valor por defecto) mantiene el aspecto original de
    // este estilo (rayita discontinua bajo el número, sin fondo); "Cuadrado"
    ///"Círculo" pintan en cambio una figura de color en la "cuenta"
    // (AnimatedContainer) que ya envolvía el número, con relleno sólido o
    // solo borde según "Con relleno"/"Sin relleno" — mismo criterio de
    // colores que CalendarGrid (estilo Clásico).
    final markerShape = CalendarStyleController.instance.markerShape;
    final markerFill = CalendarStyleController.instance.markerFill;
    final useShapeMarker = markerShape != 'raya';

    _EleDayKind kindOf(String key) {
      final entry = data[key];
      final isLogged = entry != null && entry.isPeriodDay;
      final isOvulationDay = prediction.ovulationDate != null && dateKey(prediction.ovulationDate!) == key;
      if (isLogged && !hiddenLegendCategories.contains(CalendarLegendCategory.period)) return _EleDayKind.period;
      if (isOvulationDay && !hiddenLegendCategories.contains(CalendarLegendCategory.fertile)) {
        return _EleDayKind.ovulation;
      }
      if (prediction.fertileDates.contains(key) && !hiddenLegendCategories.contains(CalendarLegendCategory.fertile)) {
        return _EleDayKind.fertile;
      }
      if (prediction.predictedPeriodDates.contains(key) &&
          !hiddenLegendCategories.contains(CalendarLegendCategory.predicted)) {
        return _EleDayKind.predicted;
      }
      return _EleDayKind.none;
    }

    // Color de la rayita discontinua bajo el número — mismos colores que ya
    // usa el registro de período en el resto de la app (mismo criterio que
    // el estilo iOS), en vez de la "pista" de fondo que tenía esta pantalla
    // antes. `null` en 'none' significa "sin rayita" (día normal).
    Color? lineColorOf(_EleDayKind kind) {
      switch (kind) {
        case _EleDayKind.period:
          return CalendarPhaseColors.periodFill;
        case _EleDayKind.predicted:
          return CalendarPhaseColors.predictedBorder;
        case _EleDayKind.fertile:
          return CalendarPhaseColors.fertileBorder;
        case _EleDayKind.ovulation:
          return CalendarPhaseColors.ovulationFill;
        case _EleDayKind.none:
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

      // Con "Intentar concebir" la rayita de fértil/ovulación se pinta más
      // gruesa (mismo criterio que el estilo iOS) — antes `emphasizeFertility`
      // se recibía como prop pero nunca se leía acá abajo, así que este
      // estilo no resaltaba nada extra con ese objetivo a diferencia de
      // Clásico/iOS. Solo cambia el grosor de la línea, nunca qué días se
      // calculan.
      final emphasizeThisDay = emphasizeFertility && (kind == _EleDayKind.fertile || kind == _EleDayKind.ovulation);

      bool visible(String categoryId) => !hiddenLegendCategories.contains(categoryId);
      _EleIndicator? indicator;
      if (entry != null && entry.sex && entry.unprotected && visible(CalendarLegendCategory.sexUnprotected)) {
        indicator = const _EleIndicator(Color(0xFFE24B4A), isHeart: true);
      } else if (entry != null && entry.sex && !entry.unprotected && visible(CalendarLegendCategory.sexProtected)) {
        indicator = const _EleIndicator(Color(0xFF1D9E75), isHeart: true, halfHeart: true);
      } else if (entry != null && entry.sexMasturbation && visible(CalendarLegendCategory.masturbation)) {
        indicator = const _EleIndicator(Color(0xFFD4537E));
      } else if (entry != null && entry.medication.contains('anticonceptivo') && visible(CalendarLegendCategory.pill)) {
        indicator = const _EleIndicator(Color(0xFFBA7517));
      } else if (entry != null && entry.diu && visible(CalendarLegendCategory.diu)) {
        indicator = const _EleIndicator(Color(0xFF7F77DD));
      } else if ((hasAppointment || hasPillReminder) && visible(CalendarLegendCategory.pill)) {
        indicator = const _EleIndicator(Color(0xFFF59F00));
      }

      final lineColor = lineColorOf(kind);
      const beadSize = 34.0;

      // Colores de fondo/borde/texto de la figura de fase (Cuadrado/
      // Círculo) — mismos tonos que CalendarGrid (estilo Clásico). `null`
      // en 'none' (día normal) o cuando la Forma elegida es "Raya" (ese
      // caso sigue el camino de abajo, sin figura).
      Color? phaseBg;
      Color? phaseBorderTone;
      Color? phaseTextTone;
      switch (kind) {
        case _EleDayKind.period:
          phaseBg = CalendarPhaseColors.periodFill;
          phaseTextTone = CalendarPhaseColors.periodText;
          break;
        case _EleDayKind.predicted:
          phaseBg = CalendarPhaseColors.predictedFill;
          phaseTextTone = CalendarPhaseColors.predictedText;
          phaseBorderTone = CalendarPhaseColors.predictedBorder;
          break;
        case _EleDayKind.fertile:
          phaseBg = CalendarPhaseColors.fertileFill;
          phaseTextTone = CalendarPhaseColors.fertileText;
          phaseBorderTone = CalendarPhaseColors.fertileBorder;
          break;
        case _EleDayKind.ovulation:
          phaseBg = CalendarPhaseColors.ovulationFill;
          phaseTextTone = CalendarPhaseColors.ovulationText;
          break;
        case _EleDayKind.none:
          break;
      }
      final bool showShapeMarker = useShapeMarker && phaseBg != null;
      final bool shapeFilled = markerFill == 'filled';
      final Color? shapeBackground = showShapeMarker ? (shapeFilled ? phaseBg : Colors.transparent) : null;
      final Color? shapeBorderColor = !showShapeMarker
          ? null
          : (emphasizeThisDay && kind == _EleDayKind.fertile)
              ? CalendarPhaseColors.fertileBorder
              : (shapeFilled ? phaseBorderTone : (phaseBorderTone ?? phaseBg));
      final double shapeBorderWidth =
          (emphasizeThisDay && kind == _EleDayKind.fertile) ? 2.2 : (shapeFilled ? 1.4 : 2.0);

      // El número del día lleva color propio solo cuando la Forma es
      // Cuadrado/Círculo (a juego con la figura); con "Raya" (el aspecto
      // original de este estilo) el tipo de día se marca SOLO con la
      // rayita discontinua de abajo, así que el número se queda neutro.
      Widget numberText = Text(
        '$d',
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: kind == _EleDayKind.none ? FontWeight.w500 : FontWeight.w700,
          color: !showShapeMarker
              ? AppColors.textPrimary
              : (shapeFilled ? (phaseTextTone ?? AppColors.textPrimary) : (shapeBorderColor ?? AppColors.textPrimary)),
        ),
      );

      // Únicos dos círculos que quedan en este estilo, pedido explícito de
      // la usuaria: el aro de "hoy" (verde, mismo tono que Clásico/iOS) y
      // el aro de "seleccionado" (acento de la app). Si un día es hoy Y
      // está seleccionado a la vez, gana el aro de hoy — mismo criterio que
      // los otros dos estilos.
      final showTodayRing = isToday;
      final showSelectedRing = isSelected && !isToday;
      final bool circleLook = showTodayRing || showSelectedRing || (showShapeMarker && markerShape == 'circle');

      Widget cellCore = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: beadSize,
            height: beadSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (showTodayRing || showSelectedRing) ? null : shapeBackground,
              // Nunca se alterna `shape` entre circle/rectangle aquí: un
              // AnimatedContainer interpola (tween) la decoración vieja y
              // la nueva, y a mitad de esa animación Flutter puede quedar
              // con `shape: circle` mientras `borderRadius` todavía no ha
              // llegado a null del todo (viene de BorderRadius.zero) —
              // combinación que BoxDecoration prohíbe explícitamente
              // ("A circle cannot have a border radius") y que causaba un
              // error visible como un parpadeo rojo cada vez que el aro
              // de "seleccionado" aparecía/desaparecía. En su lugar se usa
              // siempre `BoxShape.rectangle` con un borderRadius que llega
              // a la mitad del tamaño (círculo perfecto) cuando toca verse
              // redondo — así la animación solo interpola un número
              // (borderRadius), nunca el tipo de forma, y nunca es inválida
              // a mitad de camino.
              shape: BoxShape.rectangle,
              borderRadius: circleLook ? BorderRadius.circular(beadSize / 2) : BorderRadius.zero,
              border: showTodayRing
                  ? Border.all(color: CalendarPhaseColors.todayRingColor, width: 2.5)
                  : showSelectedRing
                      ? Border.all(color: accent, width: 2.4)
                      : (shapeBorderColor != null ? Border.all(color: shapeBorderColor, width: shapeBorderWidth) : null),
              boxShadow: showSelectedRing
                  ? [BoxShadow(color: accent.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))]
                  : null,
            ),
            child: numberText,
          ),
          const SizedBox(height: 3),
          // Rayita discontinua de color — SOLO con Forma "Raya" (aspecto
          // original de este estilo); con Cuadrado/Círculo el tipo de día
          // ya se ve en la figura de arriba, así que aquí no hay nada.
          // Se engruesa (emphasizeThisDay) para fértil/ovulación cuando el
          // objetivo es "Intentar concebir", igual que el estilo iOS.
          SizedBox(
            width: 22,
            height: 5,
            child: (useShapeMarker || lineColor == null)
                ? null
                : CustomPaint(painter: _EleDashedLinePainter(color: lineColor, bold: emphasizeThisDay)),
          ),
          const SizedBox(height: 2),
          // Indicador extra (sexo/píldora/DIU/cita) — "hoy" ya no necesita
          // su propio puntito acá porque ahora tiene el aro verde de arriba.
          SizedBox(
            height: 8,
            child: indicator == null
                ? null
                : Center(
                    child: indicator.isHeart
                        ? (indicator.halfHeart
                            ? _EleHalfHeartIcon(size: 8, color: indicator.color)
                            : Icon(Icons.favorite, size: 8, color: indicator.color))
                        : Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: indicator.color),
                          ),
                  ),
          ),
        ],
      );

      final Widget dayCell = GestureDetector(
        onTap: () => onSelectDay(dateObj),
        onDoubleTap: () => onDayMenu(dateObj),
        onLongPress: () => onDayMenu(dateObj),
        child: cellCore,
      );

      cells.add(dayCell);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withOpacity(0.10), blurRadius: 26, offset: const Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _EleCircleButton(icon: Icons.chevron_left, onTap: onPrevMonth, accent: accent),
              GestureDetector(
                onTap: () => _pickMonthYear(context),
                child: Column(
                  children: [
                    Text(
                      s.monthShort(month).toUpperCase(),
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: accent, letterSpacing: 1.2),
                    ),
                    Text(
                      '$year',
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              _EleCircleButton(icon: Icons.chevron_right, onTap: onNextMonth, accent: accent),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => (onJumpToMonth ?? (_) {}).call(DateTime(today.year, today.month, 1)),
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(s.calendarTodayButton, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: weekdayLabels
                  .map((w) => Expanded(
                        child: Center(
                          child: Text(
                            w.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.88,
            children: cells,
          ),
        ],
      ),
    );
  }
}

enum _EleDayKind { none, period, predicted, fertile, ovulation }

class _EleIndicator {
  final Color color;
  final bool isHeart;
  final bool halfHeart;
  const _EleIndicator(this.color, {this.isHeart = false, this.halfHeart = false});
}

/// Corazón mitad-relleno para "sexo con protección" — misma técnica que
/// `_HalfHeartIcon` de `calendar_grid.dart` (estilo Clásico), duplicada aquí
/// porque esa es privada a ese archivo (mismo criterio de duplicación que ya
/// sigue el resto de este widget, ver comentario de `_EleDashedLinePainter`).
class _EleHalfHeartIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _EleHalfHeartIcon({required this.size, required this.color});

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

/// Rayita discontinua bajo el número del día — el marcador de
/// período/previsto/fértil/ovulación en este estilo, en sustitución del
/// círculo/pista rellenos que tenía antes. Misma técnica que
/// `_DashedUnderlinePainter` de `calendar_grid_ios.dart`, duplicada aquí
/// porque esa es privada a ese archivo (mismo criterio de duplicación que
/// ya sigue el resto de este widget).
class _EleDashedLinePainter extends CustomPainter {
  final Color color;
  final bool bold;
  const _EleDashedLinePainter({required this.color, this.bold = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = bold ? 3.0 : 2.0
      ..strokeCap = StrokeCap.round;
    const dashWidth = 4.0;
    const dashGap = 3.0;
    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      final xEnd = (x + dashWidth) > size.width ? size.width : (x + dashWidth);
      canvas.drawLine(Offset(x, y), Offset(xEnd, y), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _EleDashedLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.bold != bold;
}

class _EleCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;
  const _EleCircleButton({required this.icon, required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withOpacity(0.10),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 20, color: accent),
        ),
      ),
    );
  }
}
